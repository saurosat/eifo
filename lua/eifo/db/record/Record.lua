local utils = require "eifo.utils"

local _record = {className = "Record"}

local function __equal(self, otherRecord)
    return self.key == otherRecord.key
end
local function __getByKey(self, sKey)
    --ngx.log(ngx.DEBUG, "Querying key = "..key)
    local meta = getmetatable(self)
    --ngx.log(ngx.DEBUG, "metatable: "..utils.toJson(meta))
    --ngx.log(ngx.DEBUG, "className = "..meta.className)
    local metaValue = meta[sKey]
    if metaValue then
        --ngx.log(ngx.DEBUG, "key = "..key..", Returning metavalue: "..(type(metaValue) == "string" and metaValue or " object"))
        return metaValue
    end

    local _table = meta._table
    -- if sKey == "_table" then --> Redundant
    --     return _table
    -- end
    --ngx.log(ngx.DEBUG, meta.className..".__getByKey "..key..", self.key: "..(rawget(self, "key") or "nil")..", meta._table = "..(_table and _table._name or "nil"))
    if _table then
        if sKey == "ids" then
            local fnIds = _table._fnIds
            local ids = utils.newArray(#fnIds)
            for i = #fnIds, 1, -1 do
                ids[i] = self[fnIds[i]]
            end
            meta.ids = ids
            return ids
        end

        local recordCommons = _table.recordCommons
        --ngx.log(ngx.DEBUG, utils.toString(recordCommons))
        if recordCommons and recordCommons[sKey] then
            return recordCommons[sKey]
        end
    
        local rightInfo = _table._rightCols[sKey]
        if rightInfo then
            local rTable = _table._rightTables[rightInfo[1]] --> rightInfo[1] is table name
            if not rTable then
                ngx.log(ngx.DEBUG, rightInfo[1].." rTable is nil: "..sKey)
                return nil
            end
            local colGroup = rTable.groupBy[rightInfo[2]] --> rightInfo[2] is joined column name
            if not colGroup then
                ngx.log(ngx.DEBUG, "Table "..rightInfo[1]..", column "..rightInfo[2]..": groupBy is nil: "..sKey)
                return nil
            end
            local group = colGroup[self.key]
            if group and group.isLoadedAll then
                return group
            end
            return rTable:loadByFk(rightInfo[2], self.key)
        end

        local fkColName = (string.match(sKey, "Obj$") and sKey:sub(1, -4)) or sKey.."Id"
        local leftInfo = _table._leftCols[fkColName]
        if leftInfo then
            local lTable = _table._leftTables[leftInfo[1]]
            return lTable and lTable:loadByKey(self[fkColName])
        end
    end
    if string.sub(sKey, 1,3) ~= "get" then
        local getterKey = "get"..string.upper(sKey:sub(1, 1))..sKey:sub(2)
        local getter = meta[getterKey]
        if getter then
            return type(getter) == "function" and getter(self)
        end
    end
    return nil
end

function _record:createSubClass(classInfo)
    local o = classInfo or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function _record:new(tableObj, recordData)
    assert(tableObj, "table is required to instantiate record")
    local record
    local dataType = type(recordData)
    if dataType == "string" then
        record = {key = recordData}
    elseif dataType == "table" then
        record = {}
        local fnIds = tableObj._fnIds
        if #recordData > 0 then
            local ids = recordData
            record.key = tableObj:generateKey(ids)
        else
            -- Because compound key does not need left tables. Ignore this: Because FKs can form compound key, alway get full left columns to record even if it does not want to load left columns
            -- local lCols = tableObj:getMetaValue("_leftCols") or tableObj._leftCols
            local lCols = tableObj._leftCols
            for columnName, joinInfo in pairs(lCols) do
                -- add prefix to FKs:
                local fkId = utils.popKey(recordData, columnName)
                if fkId then
                    if fkId ~= "_NA_" then
                        local lTbl = assert(tableObj._leftTables[joinInfo[1]], 
                        "Left table "..joinInfo[1].." is not set. This table is "
                        ..(tableObj.initialized and "not" or "").." initialized")
                        fkId = lTbl:generateKey({fkId})
                    end
                    record[columnName] = fkId
                end
            end
            for key, value in pairs(recordData) do
                record[key] = value
            end
            
            if not record.key then
                record.key = tableObj:generateKey(record)
            end
        end
    else
        error("invalid datatype: "..dataType..". Only hash, array and string is supported")
    end
    
    local _mt = self:createSubClass({ _table = tableObj, __index = __getByKey, __eq = __equal, isLoaded = false})
    return setmetatable(record, _mt)
end
function _record:getMetaValue(key, raw)
    local meta = getmetatable(self)
    if raw then
        return rawget(meta, key)
    end
    return meta[key]
end
function _record:setMetaValue(key, value)
    local meta = getmetatable(self)
    meta[key] = value
end

function _record:toJson(columns)
    local refs = {self}
    local json = "{"
    for key, value in pairs(self) do
        json = json..'"'..key..'": '..utils.toJson(value, refs)..", "
    end
    columns = columns or self._table.toJsonColumns
    if columns then
        for i = 1, #columns, 1 do
            local colValJson = utils.toJson(utils.getPropertyValue(self, columns[i]), refs)
            if colValJson then
                json = json..'"'..columns[i]..'": '..colValJson..", "
            end
        end
    end
    json = json:sub(1, -3).."}"
    return json
end
function _record:getLeftRelKey(columnName, leftRecordKey)
    return self._table:getLeftRelKey(columnName, leftRecordKey or self[columnName])
end
function _record:getRightRelKey(joinAlias)
    return self._table:getRightRelKey(joinAlias, self.key)
end
function _record:load(conn)
    if self.isLoaded then
        return self
    end
    local eData = conn:hgetall(self.key)
    if not eData or utils.isTableEmpty(eData) then
        local err = "Entity key '"..self.key.."' not found in "..self._table._name
        --ngx.log(ngx.DEBUG, err)
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
    self.isLoaded = true
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
        return nil, nil, err
    end
    self:removeOldParents(oldVals, conn, not nocommit)
    if curVals and next(curVals) then 
        for k, _ in pairs(oldVals) do
            self[k] = nil
        end
        self.isUpdated = true
    else -- delete All
        self.isDeleted = true
        self._table.remove(self)
    end
    return oldVals, {}
end
function _record:save(conn, nocommit)
    --assert(not self._table.evs, "Trying to update a read-only entity: "..self._table._name)
    --ngx.log(ngx.DEBUG, "self['key'] = "..utils.toString(self["key"]))
    local oldVals, err, newVals = conn:hset(self["key"], self)
    if err then 
        conn:rollback()
        ngx.log(ngx.ERR, "Failed to save: "..err)
        return nil, nil, "Failed to save: "..err
    end
    if utils.isTableEmpty(newVals) then --case ignore update
        return {}, {}
    end
    if self.version > 1 then
        self:removeOldParents(oldVals, conn, nocommit)
    end
    local ok, errMsg = self:updateParents(newVals, oldVals, conn)
    if errMsg then
        ngx.log(ngx.ERR, errMsg)
    end
    if not ok then
        ngx.log(ngx.DEBUG, "Error: "..(errMsg or "Unknown reason"))
        if not nocommit then
            ngx.log(ngx.DEBUG, "Rollback key "..self["key"])
            conn:rollback()            
        end
        return nil, nil, errMsg
    end
    if not nocommit then
        ngx.log(ngx.DEBUG, "Commit key "..self["key"])
        conn:commit()            
    end
    if oldVals and next(oldVals) then
        self.isUpdated = true
    else
        self.isLoaded = true -- has just inserted, hence this instance has all column values
    end
    return oldVals, newVals
end
function _record:updateParents(newVals, oldVals, conn)
    local leftCols = self._table._leftCols
    for colName, _ in pairs(leftCols) do
        local newVal = newVals and newVals[colName]
        if newVal then
            local num, err = conn:sadd(self:getLeftRelKey(colName, newVal), self.key)
            if not num then
                return false, err
            end
            local groupBy = self._table.groupBy[colName]
            local group = groupBy and groupBy[newVal]
            if group then
                group:add(self.key)
            end
        end
    end
    return true
end
function _record:removeOldParents(oldVals, conn, nocommit)
    if not oldVals or not next(oldVals) then
        return
    end
    local fkFields = self._table._leftCols
    for columnName, joinInfo in pairs(fkFields) do
        local parentId = oldVals[columnName]
        if oldVals[columnName] then
            local relKey = self:getLeftRelKey(columnName, parentId)
            conn:sremove(relKey, self.key, not nocommit)
            local group = self._table.groupBy[columnName][parentId]
            if group then
                group:remove(self.key)
            end
        end
    end
    return true
end
function _record:persist(conn, tobeDeleted, nowEpoch)
    nowEpoch = nowEpoch or os.time()
    local oldVals, newVals, err
    if not tobeDeleted then
        local thruDate = self.thruDate
        if thruDate then
            ngx.log(ngx.DEBUG, "thruDate = "..thruDate)
            local thruEpoch = utils.timeFromDbStr(thruDate)
            if thruEpoch < nowEpoch then
                tobeDeleted = true -- expired
            end
        end 
    end
    if tobeDeleted then
        oldVals, newVals, err = self:delete(conn)
    else
        oldVals, newVals, err = self:save(conn)
    end
    return oldVals, newVals, err
end
local function notifyAll(records, observers, oldVals, newVals)
    for _, v in pairs(observers) do
        --ngx.log(ngx.DEBUG, "Receiver: "..utils.toString(v, ": ", "\r\n"))
        v:_update(records, oldVals, newVals)
    end
    local record = records[1]
    local leftTables = record._table._leftTables
    local leftCols = record._table._leftCols
    for colName, tblInfo in pairs(leftCols) do
        if record[colName] and string.sub(colName, -2) == "Id" then
            local lRecordName =  string.sub(colName, 1, -3)
            local lRecord = record[lRecordName]
            if lRecord then
                local tblName = tblInfo[1]
                local lTbl = leftTables[tblName]
                local leftObservers = lTbl._observers
                notifyAll({lRecord, table.unpack(records)}, leftObservers, oldVals, newVals)
            else
                ngx.log(ngx.DEBUG, lRecordName.." is not found. Key: "..(record[colName] or "nil"))
            end
        end
    end
end
function _record:_notify(oldVals, newVals)
    local observers = self._table._observers or {}
    -- if not observers or not next(observers) then
    --     ngx.log(ngx.DEBUG, self._table._name.." updated. No observers")
    --     return true
    -- end
    notifyAll({self}, observers, oldVals, newVals)
    return true
end
return _record