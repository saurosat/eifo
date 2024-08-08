local utils = require "eifo.utils"

local recordBaseClass = require "eifo.db.record.Record"

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
        __keys = {},
        key = tableInfo.key,
        _level = 0,
        maxLevel = tableInfo.maxLevel or 100,
        recordCommons = tableInfo.commonData or {},
        tableCommons = {skippedTables = tableInfo.skippedTables, --TODO: add leftColumns and rightColumns as below ??
            leftColumns = tableInfo.leftColumns, rightColumns = tableInfo.rightColumns}, 
        --columns = columns or nil,
        filters = tableInfo.filters or {},
        skippedTables = utils.ArraySet:new(),
        initialized = false,
        groupBy = {}
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

    if(tableInfo.skippedTables) then
        tbl.skippedTables = utils.ArraySet:new()
        for i = 1, #tableInfo.skippedTables, 1 do
            tbl.skippedTables:add(tableInfo.skippedTables[i])
        end
    end
    if not self._leftCols then
        tbl._leftCols = assert(tableInfo.fnFKs, "fnFKs is missing in table schema")
    elseif tableInfo.leftColumns then
        local cols = {}
        for i = 1, #tableInfo.leftColumns, 1 do
            local colName = tableInfo.leftColumns[i]
            if self._leftCols[colName] then
                cols[colName] = utils.clone(self._leftCols[colName]) -- need clone because this is an object
            end
        end
        tbl._leftCols = cols
    end
    if not self._rightCols then
        tbl._rightCols = {}
    elseif tableInfo.rightColumns then
        local rColInfos = tableInfo.rightColumns
        local cols = {}
        for i = 1, #rColInfos, 1 do
            local alias = rColInfos[i]
            if self._rightCols[alias] then
                cols[alias] = utils.clone(self._rightCols[alias]) -- need clone because this is an object
            end
        end

        -- for key, value in pairs(rColInfos) do
        --     local alias, joinInfo
        --     if type(value) == "table" then
        --         alias = key
        --         joinInfo = value
        --     else
        --         alias = value
        --         joinInfo = nil
        --     end
        --     assert(self._rightCols[alias], 
        --         "Table "..self._name.." does not have FK relationship at field "..alias)
        --     cols[alias] = {table.unpack(self._rightCols[alias])}
        -- end
        tbl._rightCols = cols
    end
    tbl.toJsonColumns = tableInfo.toJsonColumns
    tbl = self:extend(tbl)
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

function _table:init(tableRegistry)
    if self.initialized then
        --ngx.log(ngx.DEBUG, "Table "..self._name.." had been inititalized")
        return -- Do nothing
    end
    self.initialized = true
    if not tableRegistry then
        tableRegistry = {}
        tableRegistry[self._name] = self
    end
    ngx.log(ngx.DEBUG, "Initializing "..self._name..". leftCols = "..utils.toJson(self._leftCols)..", rightCols = "..utils.toJson(self._rightCols))
    self._leftTables = {}
    self._rightTables = {}


    local newLTables = {}
    local newRTables = {}
    local metaLeftTables = self:getMetaValue("_leftTables")
    for colName, joinInfo in pairs(self._leftCols) do
        if not self.groupBy[colName] then
            self.groupBy[colName] = {}
        end
        local tblName, alias = joinInfo[1], joinInfo[2]
        if not self.skippedTables:index(tblName) then
            -- Init left table:
            local lTbl = self._leftTables[tblName]
            if not lTbl then 
                lTbl = tableRegistry[tblName]
                if not lTbl then
                    local metaTbl = assert(metaLeftTables and metaLeftTables[tblName], "Relation of "..self._name.." with Left Table "..tblName.." is not initialized")
                    lTbl = metaTbl:new(self.tableCommons)
                    if not rawget(lTbl, "_rightCols") then
                        lTbl._rightCols = {} -- left tables should not inherit rightCols from super
                    end
                    newLTables[#newLTables+1] = lTbl
                    tableRegistry[lTbl._name] = lTbl
                end
                self._leftTables[tblName] = lTbl
            end
            if not lTbl._rightCols[alias] then
                lTbl._rightCols[alias] = {self._name, colName}
            end
            if not lTbl._rightTables[self._name] then
                lTbl._rightTables[self._name] = self;
            end
        end
    end

    local metaRightTables = self:getMetaValue("_rightTables")
    if metaRightTables then --> if metaRightTables does not exist, this is the initialization of root class, below steps are not needed.
        for alias, joinInfo in pairs(self._rightCols) do
            local tblName, colName = joinInfo[1], joinInfo[2]
            if not self.skippedTables:index(tblName) then
                ngx.log(ngx.DEBUG, "Initializing right relations for "..self._name..": colName="..colName..", tblName"..tblName..", alias="..alias)
                local rTbl = self._rightTables[tblName]
                if not rTbl then
                    rTbl = tableRegistry[tblName]
                    if not rTbl then
                        local metaTbl = assert(metaRightTables[tblName], "Relation of "..self._name.." with Right Table "..tblName.." is not inititalized")
                        rTbl = metaTbl:new(self.tableCommons)
                        tableRegistry[tblName] = rTbl
                        newRTables[#newRTables+1] = rTbl
                    end
                    self._rightTables[tblName] = rTbl
                end
                if not rTbl._leftTables[self._name] then
                    rTbl._leftTables[self._name] = self 
                end
            end
        end
    end
    for i = 1, #newLTables, 1 do
        newLTables[i]:init(tableRegistry, 1)
    end
    for i = 1, #newRTables, 1 do
        newRTables[i]:init(tableRegistry, -1)
    end
    ngx.log(ngx.DEBUG, "Initialized "..self._name..". leftCols = "..utils.toJson(self._leftCols)..", rightCols = "..utils.toJson(self._rightCols))
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
        key = self._prefix..self._p_kSep..assert(ids[1], self._name..": Missing ID field "..fnIds[1])
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
function _table:getRecord(key, conn)
    if not key then
        return nil
    end
    local record = self:keys(key)
    if not record and conn then
        return self:load(key, conn)
    end
    return record
end
function _table:addRecordCommon(key, value)
    self.recordCommons[key] = value
end
function _table:load(recordData, conn, nowEpoch, direction)
    nowEpoch = nowEpoch or os.time()
    local recordKey = self:generateKey(recordData)
    --ngx.log(ngx.DEBUG, recordKey)
    local record = self:keys(recordKey)
    if record then
        return record
    end
    if self._level >= self.maxLevel then
        ngx.log(ngx.DEBUG, "max deep level reached: self._level = "..self._level)
        return record
    end
    --ngx.log(ngx.DEBUG, self._name.." loading key "..recordKey)
    self._level = self._level + 1
    record = self._record:new(self, {key = recordKey})
    local record, err = record:load(conn)
    if not record then
        self._level = self._level - 1
        return nil, "Record not found: "..utils.toJson(recordData)
    end
    local thruEpoch = record.thruDate and utils.timeFromDbStr(record.thruDate)
    if thruEpoch and thruEpoch < nowEpoch then
        record:delete(conn)
        self._level = self._level - 1
        return nil, "Record is expired: "..utils.toJson(record)
    end 

    self:add(record)

    local leftCols = self._leftCols
    for colName, joinInfo in pairs(leftCols) do
        local tblName = assert(joinInfo[1])
        if record[colName] and not self.skippedTables:index(tblName) then
            local tbl = assert(self._leftTables[tblName])
            local fKeyValue = record[colName]
            local lRecord = tbl:load({key = fKeyValue}, conn, nowEpoch, 1)
            if not self.groupBy[colName][fKeyValue] then
                self.groupBy[colName][fKeyValue] = utils.ArraySet:new()
            end
            self.groupBy[colName][fKeyValue]:add(record)
        end
    end

    for _, joinInfo in pairs(self._rightCols) do
        local tblName, colName = assert(joinInfo[1]), assert(joinInfo[2])
        if not self.skippedTables:index(tblName) then
            local tbl = assert(self._rightTables[tblName], self._name.."'s right table is not initiated: "..tblName)
            tbl:loadByFk(colName, record.key, conn, nowEpoch, -1)
        end
    end

    self._level = self._level - 1
    if self.onLoaded and self._level == 0 then
        self:onLoaded(record)
    end
    return record
end
function _table:getLeftRelKey(columnName, leftRecordKey)
    return self._prefix..self._p_kSep..columnName..self._p_kSep..leftRecordKey
end
function _table:getRightRelKey(joinAlias, leftRecordKey)
    local joinInfo = self._rightCols[joinAlias]
    local tbl = self._rightTables[joinInfo[1]]
    return tbl:getLeftRelKey(joinInfo[2], leftRecordKey)
end
function _table:loadByFk(fKeyColumn, fKeyValue, conn, nowEpoch, direction)
    --ngx.log(ngx.DEBUG, self._name..":loadByFk "..fKeyColumn.."= "..fKeyValue)
    if not self.groupBy[fKeyColumn] then
        local msg = "Column "..fKeyColumn.." is not a foreign key"
        ngx.log(ngx.ERR, msg)
        return nil, msg
    end
    local group = self.groupBy[fKeyColumn][fKeyValue]
    if group then
        if self._isLoadedByFk then
            ngx.log(ngx.DEBUG, "Already loaded: loadByFk "..fKeyColumn.."= "..fKeyValue)
            return group
        end
    else
        self.groupBy[fKeyColumn][fKeyValue] = utils.ArraySet:new()
        group = self.groupBy[fKeyColumn][fKeyValue]
    end
    self._isLoadedByFk = true

    nowEpoch = nowEpoch or os.time()

    self._level = self._level + 1
    local relkey = self:getLeftRelKey(fKeyColumn, fKeyValue)
    local keys = conn:sgetall(relkey)
    if not keys then
        ngx.log(ngx.DEBUG, "loadByFk: Key not found "..fKeyColumn.."= "..fKeyValue)
        self._level = self._level - 1
        return group
    end
    for i = 1, #keys, 1 do
        local record = self:load({key = keys[i]}, conn, nowEpoch, direction)
        if record then
            group:add(record)
        end
    end
    self._level = self._level - 1
    if self.onLoaded and self._level == 0 then
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