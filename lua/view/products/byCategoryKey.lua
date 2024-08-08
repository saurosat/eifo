local utils = require "eifo.utils"
return {
    tableName = "ProductCategory",
    layout = "/layout/master",
    outputFile = false, 
    toJson = function (self, record)
        if not record or not next(record) then
            return "{}"
        end
        local json = "{"
        for k, v in pairs(record) do
            json = json..'"'..k..'": '..utils.toJson(v)..", "
        end
        json = json..'"products": {'
        local catmems = record.catMems
        for i = 1, #catmems, 1 do
            local product = catmems[i].product
            json = json..'"'..product.key..'": '..product:toJson()..", "
        end
        json = json:sub(1, -3).."}}"
        return json
    end
}