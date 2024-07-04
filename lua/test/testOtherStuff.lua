local utils = require "eifo.utils"
-- local params = eifo.utils.splitStr(ngx.var.params, "/")
-- if not params or #params == 0 then
--     ngx.say("Please pass in a message")
--     return
-- end
-- local imgDir = params[1]
-- if imgDir then
--     eifo.store:getProductImages(imgDir)
-- end


local function getMetaValue(self, key)
    local meta = getmetatable(self)
    local metaValue = meta[key]
    if metaValue then
        return metaValue
    end
    local _table = meta._table
    if _table then
        if key == "ids" then
            local fnIds = _table.ed.fnIds
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
        local rightInfo = _table.rightCols[key]
        if rightInfo then
            local rTable = _table.rightTables[rightInfo[1]] --> rightInfo[1] is table name
            if rTable then
                local groupBy = rTable.groupBy[rightInfo[2]] --> rightInfo[2] is joined column name
                return groupBy and groupBy[self.key] or nil
                end
        end
        local fkKey = (string.match(key, "Obj$") and key:sub(1, -4)) or key.."Id"
        local leftInfo = _table.leftCols[fkKey]
        if leftInfo then
            local lTable = _table.leftTables[leftInfo.eName]
            if lTable then
                return lTable:keys(self[fkKey])
            end
        end
    end
    return "metaValue"
end
local record = setmetatable({}, {__index = getMetaValue})
function record:createSubClass(classInfo)
    local o = classInfo or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function record:new(tableObj, recordData)
    local _mt = self:createSubClass({ _table = tableObj or {} })
    return _mt:createSubClass(recordData or {})
end

local productClass = record:createSubClass()
function productClass:get_Intro() 
    return "This is Product. ID is "..self.id
end

local specialProductClass = productClass:createSubClass()
function specialProductClass:get_IntroSpecial() 
    return "This is Special Product. ID is "..self.id
end
-- local sProduct = productClass:new({size = "3x4x5"}, {id = "ABCXFS001"})
-- ngx.log(ngx.INFO, utils.toJson(sProduct))
-- ngx.log(ngx.INFO, sProduct.id)
-- ngx.log(ngx.INFO, sProduct.casdcfasdca)
-- ngx.log(ngx.INFO, "Size:"..sProduct._table.size)
-- sProduct = specialProductClass:new({price = "1 billion USD"}, {id = "ABCXFS002-SPECIAL"})
-- ngx.log(ngx.INFO, utils.toJson(sProduct))
-- ngx.log(ngx.INFO, sProduct.id)
-- ngx.log(ngx.INFO, sProduct.asdasdfa)
-- ngx.log(ngx.INFO, sProduct._table.size)
-- ngx.log(ngx.INFO, sProduct._table.price)

local cmd = "find `pwd` -name '*.lua'"
local pfile, err = io.popen(cmd, "r")
if not pfile then
    ngx.log(ngx.DEBUG, err or "Can not open directory")
    return nil, err
end
local line = pfile:read('*l')
while line do
    ngx.log(ngx.INFO, line)
    line = pfile:read('*l')
end
pfile:close()
