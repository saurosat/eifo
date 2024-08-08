local utils = require "eifo.utils"
local baseRecord = require "eifo.db.record.Record"
local record = baseRecord:createSubClass({className = "ProductCategory"})
function record:getParents()
    local parents = self:getMetaValue("parents", true) 
    if parents then
        return parents
    end
    local tbl = self._table
    parents = {}
    local rollups = self.rollups or {}
    for i = #rollups, 1, -1 do
        local rollup = rollups[i]
        local parent = rollup.parentProductCategory
        if not parent then
            rollups:remove(rollup)
            rollup._table:remove(rollup)
        else
            parents[parent.productCategoryTypeEnumId] = parent
        end
    end
    self.setMetaValue("parents", parents)
    return parents
end
function record:getChildren()
    local children = self:getMetaValue("children", true) 
    if children then
        return children
    end
    local tbl = self._table
    if not tbl then
        ngx.log(ngx.ERR, self.className.." record "..utils.toJson(self).." has no associated table")
        return {}
    end
    children = {}
    local rollups = self.childRollups or {}
    for i = #rollups, 1, -1 do
        local rollup = rollups[i]
        local child = rollup.productCategory
        if not child then
            rollups:remove(rollup)
            rollup._table:remove(rollup)
        else
            local childCatType = child.productCategoryTypeEnumId
            if not children[childCatType] then
                children[childCatType] = utils.ArraySet:new()
            end
            children[childCatType]:add(child)
        end
    end
    self.setMetaValue("children", children)
    return children
end
function record:getProducts (catType)
    --ngx.log(ngx.DEBUG, "catType = "..(catType or "nil"))
    catType = catType or nil
    local products = {}
    local catMems = self.catMems
    if catMems then
        for i = 1, #catMems, 1 do 
            products[#products + 1] = catMems[i].product
        end
    else
        ngx.log(ngx.DEBUG, self.key..": No catMems found")
    end
    local directOnly = not catType
    if not directOnly then
        local children = self.children
        for childCatType, childCats in pairs(children) do
            if catType == nil or catType == childCatType then
                for i = 1, #childCats, 1 do 
                    local childCat = childCats[i]
                    local childCatPrds = childCat:getProducts(catType)
                    for j = 1, #childCatPrds, 1 do 
                        products[#products + 1] = childCatPrds[j]
                    end
                end
            end
        end
    end
    ngx.log(ngx.DEBUG, "Numbers of products: " ..#products.."cat:getProducts, catMems: "..(catMems and tostring(#catMems) or "nil"))
    return products
end
function record:convertTreeToString(pattern, propNames, categoryType)
    if categoryType and self.productCategoryTypeEnumId ~= categoryType then
        return ''
    end
    local values = utils.newArray(#propNames)
    for i = 1, #propNames, 1 do
        values[i] = self[propNames[i]]
    end
    ngx.log(ngx.DEBUG, "Convert tree to string"..utils.toJson(values))
    local str = string.format(pattern, table.unpack(values))
    local childs = self.children
    if not childs then
       return str 
    end
    for i = 1, #childs, 1 do
        if childs[i] then
            local subCat = self._table:keys(childs[i].productCategoryId)
            str = str..subCat:convertTreeToString(pattern, propNames, categoryType)
        end
    end
    return str;
end

return record