local utils = require "eifo.utils"
local Record = require "eifo.db.record.Record"
if eifo.db.record.ProductCategory then
    return eifo.db.record.ProductCategory
end
eifo.db.record.ProductCategory = Record:createSubClass()
local record = eifo.db.record.ProductCategory
function record:getAllProducts (catType, directOnly)
    --ngx.log(ngx.DEBUG, "catType = "..(catType or "nil"))
    catType = catType or nil
    local products = {}
    local catMems = self.catMems
    if not catMems then
        --ngx.log(ngx.DEBUG, "selv.ignoredTables = "..(self.ignoredTables or "nil"))
        return products
    end
    for i = 1, #catMems, 1 do 
        products[#products + 1] = catMems[i].product
    end
    if not directOnly then
        local childCats = self.children
        if childCats then
            for i = 1, #childCats, 1 do 
                local childCat = childCats[i].productCategory
                -- ngx.log(ngx.DEBUG, "childCat.productCategoryTypeEnumId = "..(childCat.productCategoryTypeEnumId or "nil"))
                if catType == nil or childCat.productCategoryTypeEnumId == catType then
                    local childCatPrds = childCat:getAllProducts(catType)
                    for j = 1, #childCatPrds, 1 do 
                        products[#products + 1] = childCatPrds[j]
                    end
                end
            end
        end
    end
    --ngx.log(ngx.DEBUG, "Numbers of products: " ..#products.."cat:getAllProducts, catMems: "..(catMems and tostring(#catMems) or "nil")..", childCats: "..(childCats and tostring(#childCats) or "nil"))
    return products
end
local function convertTreeToString(self, pattern, propNames, categoryType)
    if categoryType and self.productCategoryTypeEnumId ~= categoryType then
        return ''
    end
    local values = utils.newArray(#propNames)
    for i = 1, #propNames, 1 do
        values[i] = self[propNames[i]]
    end
    print(table.unpack(values))
    local str = string.format(pattern, table.unpack(values))
    local childs = self.children
    if not childs then
       return str 
    end
    for i = 1, #childs, 1 do
        if childs[i] then
            local subCat = self._table.keys[childs[i].productCategoryId]
            str = str..convertTreeToString(subCat, pattern, propNames, categoryType)
        end
    end
    return str;
end
record.convertTreeToString = convertTreeToString;

return record