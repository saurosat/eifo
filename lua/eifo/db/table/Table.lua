local utils = require "eifo.utils"
if not eifo then
    eifo = {}
end
if not eifo.db then
    eifo.db = {}
end
if not eifo.db.table then
    eifo.db.table = {}
end

local recordBaseClass = require "eifo.db.record.Record"

local _table = setmetatable({_p_kSep = '.', _k_kSep = '+'}, {__index = utils.observable})
function _table:extend(subClass)
    subClass = setmetatable(subClass or {}, self)
    self.__index = self
    return subClass
end
function _table:new(tableInfo)
    local tbl = {
        _rightCols = {},
        _leftTables = {},
        _rightTables = {},
        key = tableInfo.key,
        maxLevel = tableInfo.maxLevel or 100,
        recordCommons = tableInfo.commonData or {},
        --columns = columns or nil,
        filters = tableInfo.filters or {},
    }
    if not self._alias then
        self._alias = tableInfo.alias or tableInfo.name
    end
    if not self._name then
        self._name = assert(tableInfo.name, "table name is missing in table schema")
        local ok, recordClass = pcall(require, "eifo.db.record."..self._name)
        self._record = ok and recordClass or recordBaseClass
    end
    if not self._prefix then
        self._prefix = assert(tableInfo.prefix, "prefix is missing in table schema")
    end
    if not self._fnIds then
        local fnIds = assert(tableInfo.fnIds, "fnIds is missing in table schema")
        self._fnIds = utils.ArraySet.new(fnIds)
    end
    if not self._leftCols then
        self._leftCols = assert(tableInfo.fnFKs, "fnFKs is missing in table schema")
    end
    if(tableInfo.skippedTables) then
        tbl.skippedTables = utils.ArraySet:new()
        for i = 1, #tableInfo.skippedTables, 1 do
            tbl.skippedTables.add(tableInfo.skippedTables[i])
        end
    end
    if tableInfo.leftColumns then
        local cols = {}
        for i = 1, #tableInfo.leftColumns, 1 do
            local colName = tableInfo.leftColumns[i]
            assert(self._leftCols[colName], 
                "Table "..self._name.." does not have FK relationship at field "..colName)
            cols[colName] = utils.clone(self._leftCols[colName]) -- need clone because this is an object
        end
        tbl._leftCols = cols
    end
    if tableInfo.rightColumns then
        local cols = {}
        for i = 1, #tableInfo.rightColumns, 1 do
            local colName = tableInfo.rightColumns[i]
            assert(self._rightCols[colName], 
                "Table "..self._name.." does not have FK relationship at field "..colName)
            cols[colName] = utils.clone(self._rightCols[colName])
        end
        tbl._leftCols = cols
    end
    tbl = self:extend(tbl)
    -- TODO:
    -- if tableInfo.evs then
    --     for i = 1, #tableInfo.evs, 1 do
            
    --     end
    -- end
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

function _table:init()
    if self.initialized or utils.isTableEmpty(self._leftCols) then
        return -- Do nothing
    end
    local metaLeftTables = self:getMetaValue("_leftTables")
    for colName, joinInfo in pairs(self._leftCols) do
        local tblName, alias = joinInfo[1], joinInfo[2]
        local lTbl = self._leftTables[tblName]
        if not lTbl and not self.skippedTables:index(tblName) then
            local metaTbl = metaLeftTables[tblName]
            if metaTbl then
                lTbl = metaTbl:new()
            else
                lTbl = assert(eifo.db.table[tblName], tblName.." is not defined")
            end
            lTbl._rightTables[self._name] = self;
            lTbl._rightCols[alias] = joinInfo
            lTbl:init()
            self._leftTables[tblName] = lTbl
        end
    end
    local metaRightTables = self:getMetaValue("_rightTables")
    for _, joinInfo in pairs(self._rightCols) do
        local tblName, colName = joinInfo[1], joinInfo[2]
        local rTbl = self._rightTables[tblName]
        if not rTbl and not self.skippedTables:index(tblName) then
            local metaTbl = metaRightTables[tblName]
            if metaTbl then
                rTbl = metaTbl:new()
            else
                rTbl = assert(eifo.db.table[tblName], tblName.." is not defined")
            end
            rTbl._leftTables[self._name] = self
            rTbl._leftCols[colName] = joinInfo
            rTbl:init()
            self._rightTables[tblName] = rTbl
        end
    end
    self.initialized = true
end
function _table:generateKey(ids)
    local fnIds = self._fnIds
    assert(#ids >= #fnIds, "Not provide enough id values. Required: "..utils.toJson(fnIds)..", provided: "..utils.toJson(ids))
    local sep = self._k_kSep
    local key = self._prefix..self._p_kSep..ids[1]
    for i = 2, #fnIds, 1 do
        key = key..sep..fnIds[i]
    end
    return key
end
function _table:getRecord(key, conn)
    if not key then
        return nil
    end
    local record = self.keys[key]
    if not record and conn then
        return self:load(key, conn)
    end
    return record
end
function _table:addRecordCommon(key, value)
    self.recordCommons[key] = value
end
function _table:load(recordData, conn)
    local record = self._record:new(self, recordData)
    local ok, err = record:load(conn)
    if ok then
        self[#self+1] = record
        self.keys[record.key] = record
    end
end
