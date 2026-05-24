local utils = require "eifo.utils"

local recordBaseClass = require "eifo.db.record.Record"

local lTblIndex = function (self, tableName) -- self is _leftTables object
    local parentTbl = self.parent
    local loadedTbls = parentTbl.tblRegistry
    local lTbl = loadedTbls[tableName]
    if not lTbl then
        --local tblClass = assert(eifo.db.table[tableName], tableName.." table definition is not found")
        local classRegistry = getmetatable(parentTbl).tblRegistry
        local tblClass = assert(classRegistry[tableName], tableName.." table definition is not found")
        lTbl = tblClass:new({conn = assert(parentTbl.conn, parentTbl._name..".conn == nil "), tblRegistry = loadedTbls})
    end
    lTbl._rightTables[parentTbl._name] = parentTbl
    self[tableName] = lTbl
    return lTbl
end
local rTblIndex = function (self, tableName)
    local parentTbl = self.parent
    local loadedTbls = parentTbl.tblRegistry
    local rTbl = loadedTbls[tableName]
    if not rTbl then
        local classRegistry = getmetatable(parentTbl).tblRegistry
        local tblClass = assert(classRegistry[tableName], tableName.." table definition is not found")
        rTbl = tblClass:new({conn = assert(parentTbl.conn, parentTbl._name..".conn == nil "), tblRegistry = loadedTbls})
    end
    rTbl._leftTables[parentTbl._name] = parentTbl
    self[tableName] = rTbl
    return rTbl
end
-- local LTables = setmetatable({}, {
--     __index = function (self, tableName)
--         local parentTbl = self.parent
--         local lTbl = eifo.db.table[tableName]:new({conn = assert(parentTbl.conn, parentTbl._name..".conn == nil ")})
--         lTbl._rightTables[parentTbl._name] = parentTbl
--         self[tableName] = lTbl
--         return lTbl
--     end
-- })
-- function LTables:new(parentTable)
--     self.__index = self
--     return setmetatable({parent = parentTable}, self)
-- end

-- local RTables = setmetatable({}, {
--     __index = function (self, tableName)
--         local parentTbl = self.parent
--         local rTbl = eifo.db.table[tableName]:new({conn = assert(parentTbl.conn, parentTbl._name..".conn == nil ")})
--         rTbl._leftTables[parentTbl._name] = parentTbl
--         self[tableName] = rTbl
--         return rTbl
--     end
-- })
-- function RTables:new(parentTable)
--     self.__index = self
--     return setmetatable({parent = parentTable}, self)
-- end

local _table = utils.ArraySet:new({_p_kSep = '.', _k_kSep = '+'})
_table._attach = utils.observable._attach
_table._detach = utils.observable._detach
function _table:extend(subClass)
    subClass = setmetatable(subClass or {}, self)
    self.__index = self
    return subClass
end
function _table:new(tableInfo)
    tableInfo = tableInfo or {}
    local tblName = self._name or tableInfo.name
    assert(tblName, "table name is missing in table schema")
    if tableInfo.tblRegistry and tableInfo.tblRegistry[tblName] then
        return tableInfo.tblRegistry[tblName]
    end
    local tbl = {
        _name = tblName,
        key = tableInfo.key,
        recordCommons = tableInfo.commonData or {},
        groupBy = {},
        conn = tableInfo.conn or nil,
        tblRegistry = tableInfo.tblRegistry or {},
        __keys = {} --> overwrite ArraySet.__keys
    }
    if not self._name then
        local ok, recordClass = pcall(require, "eifo.db.record."..tblName)
        tbl._record = ok and recordClass or recordBaseClass
    end
    if not self._alias then
        tbl._alias = tableInfo.alias or tbl._name
    end
    if not self._prefix then
        tbl._prefix = assert(tableInfo.prefix, "prefix is missing in table schema")
    end
    if not self._fnIds then
        local fnIds = assert(tableInfo.fnIds, "fnIds is missing in table schema")
        tbl._fnIds = utils.ArraySet:new(fnIds)
    end
    if tableInfo.indexFields and next(tableInfo.indexFields) then
        tbl.indexFields = tableInfo.indexFields
    end

    tbl._leftTables = setmetatable({parent = tbl}, {__index = lTblIndex})
    if not self._leftCols then
        tbl._leftCols = assert(tableInfo.fnFKs, "fnFKs is missing in table schema")
    else
        for colName, _ in pairs(self._leftCols) do
            tbl.groupBy[colName] = {}
        end
    end

    tbl._rightTables = setmetatable({parent = tbl}, {__index = rTblIndex})
    if not self._rightCols then
        tbl._rightCols = {}
    end
    if tableInfo.toJsonColumns then
        tbl.toJsonColumns = tableInfo.toJsonColumns
    end
    tbl = self:extend(tbl)
    tbl.tblRegistry[tbl._name] = tbl
    return tbl
end

function _table:equal(anotherSchema)
    return anotherSchema and (anotherSchema == self or 
            (self.key and anotherSchema.key == self.key) or 
            anotherSchema._name == self._name)
end

function _table:getMetaValue(key)
    local meta = getmetatable(self)
    return meta[key]
end
function _table:setMetaValue(key, value)
    local meta = getmetatable(self)
    meta[key] = value
end
function _table:generateKey(recordData)
    if recordData.key then
        return recordData.key
    end
    local fnIds = self._fnIds
    local sep = self._k_kSep
    local key
    if #recordData > 0 then
        local ids = recordData
        key = self._prefix..self._p_kSep..ids[1]
        for i = 2, #fnIds, 1 do
            key = key..sep..assert(ids[i], "Missing ID field "..fnIds[i])
        end
    elseif recordData.pkValue then
        key = self._prefix..self._p_kSep..recordData.pkValue
    else
        key = self._prefix..self._p_kSep..assert(recordData[fnIds[1]], self._name.."Missing ID field "..fnIds[1].." ID fields: "..utils.toJson(fnIds))
        for i = 2, #fnIds, 1 do
            key = key..sep..assert(recordData[fnIds[i]], "Missing ID field"..fnIds[i])
        end
    end

    return key
end
function _table:newRecord(recordData)
    return self._record:new(self, recordData)
end
function _table:addRecordCommon(key, value)
    self.recordCommons[key] = value
end
function _table:loadByKey(recordKey, nowEpoch)
    if not recordKey then
        return nil, "recordKey is nil"
    end
    local record, err = self:keys(recordKey), nil
    if record then
        return record
    end
    local conn = self.conn
    record = self._record:new(self, {key = recordKey})
    record, err = record:load(conn)
    if not record then
        local errMsg = "Record not found: "..recordKey..(err and ": "..err or "")
        return nil, errMsg
    end

    --> Remove expired records
    nowEpoch = nowEpoch or os.time()
    local thruEpoch = record.thruDate and utils.timeFromDbStr(record.thruDate)
    if thruEpoch and thruEpoch < nowEpoch then
        record:delete(conn)
        return nil, "Record is expired: "..utils.toJson(record)
    end 

    self:add(record)
    if self.onLoaded then
        self:onLoaded(record)
    end
    return record
end
function _table:load(recordData, nowEpoch)
    return self:loadByKey(self:generateKey(recordData))
end
function _table:getLeftRelKey(columnName, leftRecordKey)
    return self._prefix..self._p_kSep..columnName..self._p_kSep..leftRecordKey
end
function _table:getRightRelKey(joinAlias, leftRecordKey)
    local joinInfo = self._rightCols[joinAlias]
    local tbl = self._rightTables[joinInfo[1]]
    return tbl:getLeftRelKey(joinInfo[2], leftRecordKey)
end

function _table:loadByKeywords(keywords, nowEpoch)
    local conn = assert(self.conn, self._name.." has no connection")
    local res, err = eifo.indexes:search(self, keywords, conn)
    if not res then
        return nil, err or "Unknown error"
    end
    if #res == 0 then
        return nil, "No records found"
    end
    local group = utils.ArraySet:new()
    for i = 1, #res, 1 do
        local recordKey = res[i]
        local record, loadErr = self:loadByKey(recordKey, nowEpoch)
        if record then
            group:add(record)
        else
            utils.logWarn("Record not found by key: "..recordKey..", loadErr: "..(loadErr or "nil"))
        end
    end
    if self.onLoaded then
        self:onLoaded(table.unpack(group))
    end
    return group
end
function _table:loadByFk(fKeyColumn, fKeyValue, nowEpoch)
    if not self.groupBy[fKeyColumn] then
        local msg = "Column "..fKeyColumn.." is not a foreign key"
        return nil, msg
    end
    local group = self.groupBy[fKeyColumn][fKeyValue]
    if not group then
        group = utils.ArraySet:new()
        self.groupBy[fKeyColumn][fKeyValue] = group
    end
    if group.isLoadedAll then
        return group
    end
    group.isLoadedAll = true

    nowEpoch = nowEpoch or os.time()

    local relkey = self:getLeftRelKey(fKeyColumn, fKeyValue)
    local conn = assert(self.conn, self._name.." has no connection")
    local keys = conn:sgetall(relkey)
    if not keys then
        utils.logWarn("FK not found "..fKeyColumn.."= "..fKeyValue)
        return group
    end
    for i = 1, #keys, 1 do
        local record, loadErr = self:loadByKey(keys[i], nowEpoch)
        if record then
            group:add(record)
        else
            utils.logWarn(keys[i].." not found :"..(loadErr or "Unknown error"))
        end
    end
    if self.onLoaded then
        self:onLoaded(table.unpack(group))
    end
    return group
end
function _table:toJson()
    local json = "{ \n\r"
    for i = 1, #self, 1 do
        json = json.."'"..self[i].key.."': "..self[i]:toJson()..",\n\r"
    end
    json = json.."}"
    return json
end
function _table:select(where)
    local sFunction = "local f = function(entity) return "..where.." end return f"
    local fWhere = load(sFunction)
    assert(fWhere)
    fWhere = fWhere()
    --utils.logDebug(utils.toString(fWhere))
    local numRecords = #self
    local records = utils.newTable(numRecords, 0)
    for i = 1, numRecords, 1 do
        local pass = fWhere(self[i])
        -- if not status then
        --     utils.logError("Filter "..utils.toString(fWhere).." can not be evaluated")
        --     return false
        -- end
        if pass then
            records[#records+1] = self[i]
        --     if not selfInstance[i].parents then
        --         utils.logDebug("Record "..selfInstance[i].key.." has no parents")
        --     else
        --         utils.logDebug("Record "..selfInstance[i].key.." has "..(#selfInstance[i].parents).." parents")
        --     end
        -- else
        --     utils.logDebug("Record "..selfInstance[i].key.." is filtered out")
        end
    end
    return records
end
return _table