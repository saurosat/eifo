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
    self:setMetaValue("parents", parents)
    return parents
end
function record:getChildren()
    local children = self:getMetaValue("children", true) 
    if children then
        ngx.log(ngx.DEBUG, self.key.."'s children: "..utils.toJson(children))
        return children
    end
    local tbl = self._table
    if not tbl then
        ngx.log(ngx.ERR, self.className.." record "..utils.toJson(self).." has no associated table")
        return {}
    end
    children = utils.ArraySet:new()
    local rollups = self.childRollups or {}
    if #rollups == 0 then
        ngx.log(ngx.DEBUG, self.key.." childRollups is empty")
    end
    for i = #rollups, 1, -1 do
        local rollup = rollups[i]
        local child = rollup.productCategory
        if not child then
            rollups:remove(rollup)
            rollup._table:remove(rollup)
        else
            children:add(child)
        end
    end
    ngx.log(ngx.DEBUG, self.key.."'s children loaded: "..utils.toJson(children))
    self:setMetaValue("children", children)
    return children
end
function record:getProducts (catType)
    --ngx.log(ngx.DEBUG, "catType = "..(catType or "nil"))
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
        local childCats = self.children
        for i = 1, #childCats, 1 do 
            local childCat = childCats[i]
            if not catType or childCat.productCategoryTypeEnumId == catType then
                local childCatPrds = childCat:getProducts(catType)
                for j = 1, #childCatPrds, 1 do 
                    products[#products + 1] = childCatPrds[j]
                end
            end
        end
    end
    ngx.log(ngx.DEBUG, "Numbers of products: " ..#products.."cat:getProducts, catMems: "..(catMems and tostring(#catMems) or "nil"))
    return products
end
function record:getTreeDisplayStrs(catArray, subCatFilter, tab, space, bullet, hJoint, vJoint)
    catArray = catArray or {}
    tab = tab or "\xc2\xbb"
    space = space or "\xc2\xa0"
    bullet = bullet or "+" --"├"
    hJoint = hJoint or "-" -- "─"
    vJoint = vJoint or "-" --"│"
    local tabLen = tab:len()
    local needReplaceByVJoint = (vJoint ~= tab)

    local function buildTree(cat, gen, lastSiblingRowIdx)
        local treeNodeName = ""
        if gen > 0 then
            if gen > 1 then
                local sTab = string.rep(tab, gen - 1)
                treeNodeName = treeNodeName..sTab
            end
            if needReplaceByVJoint then
                local vJointPos = treeNodeName:len() + 1
                for i = #catArray, lastSiblingRowIdx + 1, -1 do
                    local prevCat = catArray[i]
                    local s = prevCat:getMetaValue("treeNodeName")
                    -- replacing space by vJoint:
                    s = string.sub(s, 1, vJointPos -1)..vJoint..string.sub(s, vJointPos + tabLen + 1, -1)
                    prevCat:setMetaValue("treeNodeName", s)
                end
            end
            treeNodeName = treeNodeName..bullet..space
        end
        treeNodeName = treeNodeName..cat.categoryName
        cat:setMetaValue("treeNodeName", treeNodeName)
        local thisRowIdx = #catArray + 1
        catArray[thisRowIdx] = cat
    
        local childs = cat:getChildren()
        if not childs then
           return
        end
        local sibblingRowIdx = thisRowIdx
        for i = 1, #childs, 1 do
            local subCat = childs[i]
            local pass = true
            if subCatFilter then
                for key, value in pairs(subCatFilter) do
                    if subCat[key] ~= value then
                        pass = false
                        break
                    end
                end
            end
            if pass then
                buildTree(subCat, gen + 1, sibblingRowIdx)
                sibblingRowIdx = sibblingRowIdx + 1
            end
        end
    end
    buildTree(self, 0, #catArray)

end


return record