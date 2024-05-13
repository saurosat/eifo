local utils = require "eifo.utils"
if not eifo then
    eifo = {}
end
if not eifo.db then
    eifo.db = {}
end
if not eifo.db.record then
    eifo.db.record = {}
end
if eifo.db.record.Record then
    return eifo.db.record.Record
end

local function __indexBase(self, key)
    local meta = getmetatable(self)
    local metaValue = meta[key]
    if metaValue then
        return metaValue
    end
    local _table = meta._table
    if _table then
        if key == "ids" then
            local fnIds = _table._fnIds
            local ids = utils.newArray(#fnIds)
            for i = #fnIds, 1, -1 do
                ids[i] = self[fnIds[i]]
            end
            return ids
        end

        local common = _table.recordCommons
        if common and common[key] then
            return common[key]
        end
        local rightInfo = _table._rightCols[key]
        if rightInfo then
            local rTable = _table._rightTables[rightInfo[1]] --> rightInfo[1] is table name
            if rTable then
                local groupBy = rTable.groupBy[rightInfo[2]] --> rightInfo[2] is joined column name
                return groupBy and groupBy[self.key] or nil
                end
        end
        local fkKey = (string.match(key, "Obj$") and key:sub(1, -4)) or key.."Id"
        local leftInfo = _table._leftCols[fkKey]
        if leftInfo then
            local lTable = _table.leftTables[leftInfo.eName]
            if lTable then
                return lTable.keys[self[fkKey]]
            end
        end
    end
    return nil
end

local _record = setmetatable({}, {__index = __indexBase})
function _record:createSubClass(classInfo)
    local o = classInfo or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function _record:new(tableObj, recordData)
    local record
    local dataType = type(recordData)
    if dataType == "string" then
        record = {key = recordData}
    elseif dataType == "table" then
        record = {}
        local fnIds = tableObj._fnIds
        if #recordData > 0 then
            local ids = recordData
            record.key = self._table:generateKey(ids)
        else
            local lCols = self:getMetaValue("_leftCols") or self._leftCols
            for columnName, joinInfo in pairs(lCols) do
                local lTbl = assert(self._table._leftTables[joinInfo[1]], 
                    "Left table "..joinInfo[1].."is not set. This table is "
                    ..(self._table.initialized and "not" or "").." initialized")
                record[columnName] =  lTbl:generateKey({utils.popKey(recordData, columnName)})
            end
            for key, value in pairs(recordData) do
                record[key] = value
            end
            
            if not record.key then
                local ids = utils.newArray(#fnIds)
                for i = 1, #fnIds, 1 do
                    ids[i] = assert(recordData[fnIds[i]], "ID field is missing: "..fnIds[i])
                end
                record.key = self._table:generateKey(ids)
            end
        end
    else
        error("invalid datatype: "..dataType..". Only hash, array and string is supported")
    end
    local _mt = self:createSubClass({ _table = tableObj or {} })
    return _mt:createSubClass(record)
end
function _record:getMetaValue(key)
    local meta = getmetatable(self)
    return meta[key]
end
function _record:setMetaValue(key, value)
    local meta = getmetatable(self)
    meta[key] = value
end
function _record:toJson()
    return utils.toJson(self)
end
function _record:getLeftRelKey(columnName, leftRecordKey)
    local tbl = self._table
    return tbl._prefix..tbl._p_kSep..columnName..tbl._p_kSep..(leftRecordKey or self[columnName])
end
function _record:getRightRelKey(joinAlias)
    local joinInfo = self._table._rightCols[joinAlias]
    local tbl = self._table._rightTables[joinInfo[1]]
    return tbl._prefix..tbl._p_kSep..joinInfo[2]..tbl._p_kSep..self.key
end
function _record:load(conn)
    if self.isLoaded then
        return self
    end
    local eData = conn:hgetall(self.key)
    if not eData or utils.isTableEmpty(eData) then
        local err = "Entity key '"..self.key.."' not found in "..self._table.name
        ngx.log(ngx.INFO, err)
        return nil, err
    end

    if self._table.removeExpired and eData.thruDate then
        local nowEpoch = os.time()
        local thruEpoch = utils.timeFromDbStr(eData.thruDate)
        if thruEpoch < nowEpoch then
            self:delete(conn)
            return nil, "Entity is expired. Key: "..self.key
        end 
    end
    for key, value in pairs(eData) do
        self[key] = value
    end
    if self.onLoaded then
        self:onLoaded()
    end
    return self
end
function _record:delete(conn, nocommit)
    --assert(not self._table.evs, "Trying to update a read-only entity: "..self._table._name)
    return self:deleteFields(conn, nil, nocommit)
end
function _record:deleteFields(conn, fields, nocommit)
    --assert(not self._table.evs, "Trying to update a read-only entity: "..self._table._name)
    if fields and #fields > 0 then
        local fnIds = self._table._fnIds
        for i = 1, #fields, 1 do
            assert(not fnIds:index(fields[i]), "Can not delete ID field: "..fnIds[i])
        end
    end
    local oldVals, err, curVals = conn:hdel(self.key, fields, not nocommit)
    if not oldVals then 
        return nil, err
    end

    if fields then
        for k, _ in pairs(oldVals) do
            self[k] = nil
        end
    end
    self:_notify(curVals, oldVals) --> notify before delete all relkeys
    self:removeOldParents(oldVals, conn)
    if fields then
        self:_notify(oldVals)
    end
    return oldVals, nil
end
function _record:save(self, conn, nocommit)
    --assert(not self._table.evs, "Trying to update a read-only entity: "..self._table._name)
    ngx.log(ngx.DEBUG, "self['key'] = "..(self.key or "NIL")..". self.key = "..(self.key or "NIL"))
    local oldVals, err = conn:hset(self["key"], self, not nocommit)
    if not oldVals then 
        return nil, "Failed to save: "..err 
    end
    if utils.isTableEmpty(oldVals) and (not self["version"] or self["version"] > 1) then --case ignore update
        return {}
    end
    self:_notify(self, oldVals)
    self:removeOldParents(oldVals, conn)
    return oldVals
end
function _record:removeOldParents(oldVals, conn)
    if not oldVals or not next(oldVals) then
        return
    end
    local fkFields = self._table._leftCols
    for columnName, joinInfo in pairs(fkFields) do
        if oldVals[columnName] then
            local relKey = self:getLeftRelKey(columnName)
            conn:sremove(relKey, self.key, true)
        end
    end
end
function _record:getNotified(self, conn)
    local ok, err
    local onAction = utils.popKey(self, "on")
    local viewableCat = utils.popKey(self, "viewable")
    local columnPrefix = utils.popKey(self, "columnPrefix")
    local tobeDeleted = utils.popKey(self, "delete")
    if not tobeDeleted then
        local thruDate = self.thruDate
        if thruDate then
            local nowEpoch = os.time()
            local thruEpoch = utils.timeFromDbStr(thruDate)
            if thruEpoch < nowEpoch then
                tobeDeleted = true -- expired
            end
        end 
    end
    if tobeDeleted then
        ok, err = self:delete(conn)
    else
        ok, err = self:save(conn)
    end
    return ok, err
end
function _record:_notify(curVals, oldVals)
    local observers = self._table._observers
    if not observers or not next(self._observers) then
        return 
    end
    for _, v in pairs(observers) do
        ngx.log(ngx.DEBUG, "Receiver: "..utils.toString(v, ": ", "\r\n"))
        v:_update(curVals, oldVals)
    end
end
eifo.db.record.Record = _record
return _record