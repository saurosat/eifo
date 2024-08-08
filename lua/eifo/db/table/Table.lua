local utils = require "eifo.utils"

local recordBaseClass = require "eifo.db.record.Record"

local lTblIndex = function (self, tableName)
    local parentTbl = self.parent
    local loadedTbls = parentTbl.tblRegistry
    local lTbl = loadedTbls[tableName]
    if not lTbl then
        lTbl = eifo.db.table[tableName]:new({conn = assert(parentTbl.conn, parentTbl._name..".conn == nil "), tblRegistry = loadedTbls})
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
        rTbl = eifo.db.table[tableName]:new({conn = assert(parentTbl.conn, parentTbl._name..".conn == nil "), tblRegistry = loadedTbls})
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
    local tbl = {
        key = tableInfo.key,
        recordCommons = tableInfo.commonData or {},
        groupBy = {},
        conn = tableInfo.conn or nil,
        tblRegistry = tableInfo.tblRegistry or {},
        __keys = {} --> overwrite ArraySet.__keys
    }
    if not self._name then
        tbl._name = assert(tableInfo.name, "table name is missing in table schema")
        local ok, recordClass = pcall(require, "eifo.db.record."..tbl._name)
        tbl._record = ok and recordClass or recordBaseClass
        ngx.log(ngx.INFO, "Table "..tbl._name..", record class: "..tbl._record.className)
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
    tbl.toJsonColumns = tableInfo.toJsonColumns
    tbl = self:extend(tbl)
    tbl.tblRegistry[tbl._name] = tbl
    ngx.log(ngx.DEBUG, "Created new table "..tbl._name)
    return tbl
end
-- function _table:init() 
--     --TODO to be deleted
-- end
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
        --ngx.log(ngx.DEBUG, "Key already exists: "..recordData.key)
        return recordData.key
    end
    --ngx.log(ngx.DEBUG, "Generate key from "..utils.toJson(recordData))
    local fnIds = self._fnIds
    local sep = self._k_kSep
    local key
    if #recordData > 0 then
        local ids = recordData
        key = self._prefix..self._p_kSep..ids[1]
        for i = 2, #fnIds, 1 do
            key = key..sep..assert(ids[i], "Missing ID field "..fnIds[i])
        end
        --ngx.log(ngx.DEBUG, key)

    else
        key = self._prefix..self._p_kSep..assert(recordData[fnIds[1]], self._name.."Missing ID field "..fnIds[1].." ID fields: "..utils.toJson(fnIds))
        for i = 2, #fnIds, 1 do
            key = key..sep..assert(recordData[fnIds[i]], "Missing ID field"..fnIds[i])
        end
    end
    --ngx.log(ngx.DEBUG, key)

    return key
end
function _table:newRecord(recordData)
    return self._record:new(self, recordData)
end
function _table:addRecordCommon(key, value)
    self.recordCommons[key] = value
end
function _table:loadByKey(recordKey, nowEpoch)
    local record, err = self:keys(recordKey), nil
    if record then
        return record
    end
    --ngx.log(ngx.DEBUG, self._name.." loading key "..recordKey)
    local conn = self.conn
    record = self._record:new(self, {key = recordKey})
    record, err = record:load(conn)
    if not record then
        local errMsg = "Record not found: "..recordKey..(err and ": "..err or "")
        ngx.log(ngx.DEBUG, errMsg)
        return nil, err
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
function _table:loadByFk(fKeyColumn, fKeyValue, nowEpoch)
    --ngx.log(ngx.DEBUG, self._name..":loadByFk "..fKeyColumn.."= "..fKeyValue)
    if not self.groupBy[fKeyColumn] then
        local msg = "Column "..fKeyColumn.." is not a foreign key"
        ngx.log(ngx.ERR, msg)
        return nil, msg
    end
    local group = self.groupBy[fKeyColumn][fKeyValue]
    if not group then
        group = utils.ArraySet:new()
        self.groupBy[fKeyColumn][fKeyValue] = group
    end
    if group.isLoadedAll then
        --ngx.log(ngx.DEBUG, "Already loaded: loadByFk "..fKeyColumn.."= "..fKeyValue)
        return group
    end
    group.isLoadedAll = true

    nowEpoch = nowEpoch or os.time()

    local relkey = self:getLeftRelKey(fKeyColumn, fKeyValue)
    local conn = assert(self.conn, self._name.." has no connection")
    local keys = conn:sgetall(relkey)
    if not keys then
        ngx.log(ngx.DEBUG, "FK not found "..fKeyColumn.."= "..fKeyValue)
        self._level = self._level - 1
        return group
    end
    for i = 1, #keys, 1 do
        local record, loadErr = self:loadByKey(keys[i], nowEpoch)
        if record then
            group:add(record)
        else
            ngx.log(ngx.DEBUG, "Key not found :"..keys[i])
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
        --ngx.log(ngx.DEBUG, "Record "..i..": "..(self[i].key or "NIL"))
        json = json.."'"..self[i].key.."': "..self[i]:toJson()..",\n\r"
    end
    json = json.."}"
    return json
end
function _table:select(where)
    local sFunction = "local f = function(entity) return "..where.." end return f"
    local fWhere = loadstring(sFunction)
    assert(fWhere)
    fWhere = fWhere()
    ngx.log(ngx.DEBUG, utils.toString(fWhere))
    local numRecords = #self
    local records = utils.newTable(numRecords, 0)
    for i = 1, numRecords, 1 do
        local pass = fWhere(self[i])
        ngx.log(ngx.DEBUG, pass and "PASS" or "FAILED")
        -- if not status then
        --     ngx.log(ngx.ERR, "Filter "..utils.toString(fWhere).." can not be evaluated")
        --     return false
        -- end
        if pass then
            records[#records+1] = self[i]
        --     if not selfInstance[i].parents then
        --         ngx.log(ngx.DEBUG, "Record "..selfInstance[i].key.." has no parents")
        --     else
        --         ngx.log(ngx.DEBUG, "Record "..selfInstance[i].key.." has "..(#selfInstance[i].parents).." parents")
        --     end
        -- else
        --     ngx.log(ngx.DEBUG, "Record "..selfInstance[i].key.." is filtered out")
        end
    end
    return records
end
return _table