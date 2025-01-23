local utf8 = require("lua.utf8")
return {
    tableName = "ProductStore",
    key = eifo.storeId,
    outputFile = true,
    createPageContext = function (self, context)
        local record = context.record
        local categories = record.categories
        local cats = {}
        for i = 1, #categories, 1 do 
            local cat = categories[i]
            if cat.productCategoryTypeEnumId == 'e.PctCatalog' and not next(cat.parents) then
                cat:getTreeDisplayStrs(cats, {productCategoryTypeEnumId = 'e.PctCatalog'}, "+", " ", "+", "+", "+")
            end 
        end 
        local catTreeArray = {}
        for i = 1, #cats, 1 do
            local treeNodeName = cats[i]:getMetaValue("treeNodeName")
            -- treeNodeName = string.encode(treeNodeName) --> encode utf-8 characters
            catTreeArray[i] = {key = cats[i].key, treeNodeName = treeNodeName}
        end
        local store = eifo.store
        return {
            token = store:getSessionToken(),
            storeId = store.productStoreId,
            currencyUomId = store.defaultCurrencyUomId or "undefined",
            catTreeArray = catTreeArray
        }
    end
}