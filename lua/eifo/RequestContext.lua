local getIndex = function (self, index)
    local meta = getmetatable(self)._meta_
    local f = meta["get_"..index]
    local val = f and f(self) or meta._privates_[index]
    if val == "NULL" then
        return nil
    end
    return val or meta[index]
end
local RequestContext = {
    _privates_ = {
    }
}
function RequestContext:new(context, privateFieldVals)
    local privateFVs = {}
    if privateFieldVals then
        for i = 1, #privateFieldVals, 1 do
            privateFVs[privateFieldVals[i]] = "NULL"
        end
        for key, value in pairs(privateFieldVals) do
            privateFVs[key] = value
        end
    end
    return setmetatable(context or {}, {__index = getIndex, _meta_ = self, _privates_ = privateFVs})
end
function RequestContext:get_key()
    local record = rawget(self, "record")
    if record then
        return record.key or "NULL" --> prevent searching on metatable
    end
    local params = rawget(self, "params")
    if params then
        return #params == 1 and params[1] or "NULL" --> prevent searching on metatable
    end
    return nil --> continue search on metatable
end
function RequestContext:get_params()
    local key = rawget(self, "key")
    if key then
        return {key}
    end
    local record = rawget(self, "record")
    return record and {record.key} --> prevent searching on metatable
end
function RequestContext:get_filePath()
    if rawget(self, "key") or rawget(self, "params") then
        return "NULL" --> prevent searching on metatable
    end
    return nil
end
return RequestContext