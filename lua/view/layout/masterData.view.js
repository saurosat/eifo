/* {%
    local utils = eifo.utils
    local categories = record.categories
    local topCats = utils.ArraySet:new()
    for i = 1, #categories, 1 do 
        if categories[i].productCategoryTypeEnumId == 'e.PctCatalog' and not next(categories[i].parents) then 
            topCats:add(categories[i])
        end 
    end 

    local store = eifo.store
    local token = store:getSessionToken()
    local storeId = store.productStoreId
    local currencyUomId = store.defaultCurrencyUomId or "undefined"
 %} */
 const categories = JSON.parse("{* utils.toJson(categories) *}");
 const topCats = JSON.parse("{* utils.toJson(topCats) *}");
 const sessionToken = "{* token *}";
 const storeId = "{* storeId *}";
 const currencyUomId = "{* currencyUomId *}"
