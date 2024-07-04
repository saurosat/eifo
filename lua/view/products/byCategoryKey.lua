local utils = require "eifo.utils"
return {
    tableName = "ProductCategory",
    leftColumns = {},
    rightColumns = {"catMems"},
    skippedTables = {"ProductAssoc"},
    layout = "/layout/master",
    outputFile = false, 
    toJson = function (self, model)
        if #model == 0 then
            return "{}"
        end
        local json = "{"
        for k, v in pairs(model[1]) do
            json = json..'"'..k..'": '..utils.toJson(v)..", "
        end
        json = json..'"products": {'
        local catmems = model._rightTables["ProductCategoryMember"]
        for i = 1, #catmems, 1 do
            local product = catmems[i].product
            json = json..'"'..product.key..'": '..product:toJson()..", "
        end
        json = json:sub(1, -3).."}}"
        return json
    end
}