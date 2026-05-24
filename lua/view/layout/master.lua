local function buildCatMenuData(categories)
    local topCats = {}
    for i = 1, #categories, 1 do 
        local cat = categories[i]
        local catType = cat.productCategoryTypeEnumId
        if catType == 'e.PctCatalog' or catType == 'e.PctCustom' then
            cat.title = cat.categoryName 
            local parents = cat:getParents()
            if not next(parents) then                
                topCats[#topCats + 1] = cat
                cat.desc = cat.description
                if not (cat.icon or cat.svgPath or cat.svgId)  then
                    cat.svgId = catType == 'e.PctCatalog' and "svgDemo" or "svgCustom"
                end
            else --> comment out to get subcategories in the menu
                for _, parent in pairs(parents) do
                    if parent.productCategoryTypeEnumId == 'e.PctCatalog' then
                        if not parent.items then
                            parent.items = {}
                        end
                        parent.items[#parent.items + 1] = cat
                    end
                end
            end
        end 
    end
    return topCats
end
local function buildCatTree(categories)
    local topCats = {}
    local catMap = {}
    for i = 1, #categories, 1 do
        local cat = categories[i]

        local seq = cat.sequenceNum
        if seq then
            if seq < 100 then
                topCats[#topCats + 1] = cat
            end

            local catSeq = seq % 100
            if catMap[catSeq] then
                cat.items = catMap[catSeq].items
                catMap[catSeq] = cat
            else
                cat.items = {}
            end

            local parentSeq = math.floor(seq/100)
            while parentSeq > 0 do
                catSeq = parentSeq % 100
                if catMap[catSeq] then
                    local items = catMap[catSeq].items
                    items[#items + 1] = cat
                else
                    catMap[catSeq] = {items = {cat}}
                end
                parentSeq = math.floor(parentSeq/100)
            end
        end
    end
end

return {
    tableName = "ProductStore",
    key = eifo.storeId,
    outputFile = true,
    createPageContext = function (self, context)
        local record = context.record
        local categories = record.categories
        local cats = {}
        -- for i = 1, #categories, 1 do 
        --     local cat = categories[i]
        --     if cat.productCategoryTypeEnumId == 'e.PctCatalog' and not next(cat.parents) then
        --         cat:getTreeDisplayStrs(cats, {productCategoryTypeEnumId = 'e.PctCatalog'}, "+", " ", "+", "+", "+")
        --     end 
        -- end 
        -- local catTreeArray = {}
        -- for i = 1, #cats, 1 do
        --     local treeNodeName = cats[i]:getMetaValue("treeNodeName")
        --     -- treeNodeName = string.encode(treeNodeName) --> encode utf-8 characters
        --     catTreeArray[i] = {key = cats[i].key, treeNodeName = treeNodeName}
        -- end
        local store = eifo.store
        return {
            main = "{* main *}",
            token = store:getSessionToken(),
            storeId = store.productStoreId,
            currencyUomId = store.defaultCurrencyUomId or "undefined",
            lang = 'EN',
            --catTreeArray = catTreeArray,
            mainMenuItems = {
                {key = "mmiLang", title = "EN", svgId = "dropdown", 
                    items = {
                        {key = "EN", title = "EN", href = ".?lang=en"}, 
                        {key = "VI", title = "VI", href = ".?lang=vi"}, 
                        {key = "CN", title = "CN", href = ".?lang=cn"}
                    }},
                {key = "mmiSignIn", title = "Sign In", userAccount = "window.userAccount", forLoggedIn = false, event = "open-login"},
                {key = "mmiCart", title = "Cart", userAccount = "window.userAccount", forLoggedIn = true, event = "open-cart"},
                {key = "mmiOrders", title = "Orders", userAccount = "window.userAccount", forLoggedIn = true, event = "open-orders"},
                {key = "mmiReturns", title = "Returns", userAccount = "window.userAccount", forLoggedIn = true, event = "open-returns"},
            },
            catMenuItems = buildCatMenuData(categories)
        }
    end
}