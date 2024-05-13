local utils = eifo.utils

eifo.vrecord = {}
function eifo.vrecord:getKey(key)
    local meta = getmetatable(self)
    local metaVal = rawget(meta, key)
    if metaVal then
        return metaVal
    end
    local keySub = key:sub(1, 1)
    if keySub == "_" then
        local getterKey = "get"..key
        local getter = self[getterKey]
        if getter then
            return type(getter) == "function" and getter(self) or getter
        end
    end
    local vModel = meta.vModel
    if vModel then
        if key == "ids" then
            local fnIds = vModel.ed.fnIds
            local ids = utils.newArray(#fnIds)
            for i = #fnIds, 1, -1 do
                ids[i] = self[fnIds[i]]
            end
            return ids
        end

        local common = vModel.recordCommons
        if common and common[key] then
            return common[key]
        end
        local rightInfo = vModel.rightCols[key]
        if rightInfo then
            local rightVModel = vModel.rightTables[rightInfo[1]] --> rightInfo[1] is table name
            if rightVModel then
                local groupBy = rightVModel.groupBy[rightInfo[2]] --> rightInfo[2] is joined column name
                return groupBy and groupBy[self.key] or nil
                end
        end
        local fkKey = (string.match(key, "Obj$") and key:sub(1, -4)) or key.."Id"
        local leftInfo = vModel.leftCols[fkKey]
        if leftInfo then
            local leftVModel = self.vModel.leftTables[leftInfo.eName]
            if leftVModel then
                return leftVModel.keys[self[fkKey]]
            end
        end
    end
    return meta[key]
end


function eifo.vrecord:new(obj)
    local o = obj or {}
    setmetatable(o, self)
    self.__index = self.getKey
    return o
end
function eifo.vrecord:newInstance(vModel, recordData)
    local _mt = self:new({ vModel = vModel or {} })
    return _mt:new(recordData or {})
end
function eifo.vrecord:toJson()
    return utils.toJson(self)
end
eifo.vrecord.ProductCategory = eifo.vrecord:new()
function eifo.vrecord.ProductCategory:getAllProducts (catType, directOnly)
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
            local subCat = self.vModel.keys[childs[i].productCategoryId]
            str = str..convertTreeToString(subCat, pattern, propNames, categoryType)
        end
    end
    return str;
end
eifo.vrecord.ProductCategory.convertTreeToString = convertTreeToString;

eifo.vrecord.Product = eifo.vrecord:new()
local function getEditedFileName(image, editKey)
    local resizedFName = eifo.store:getResizedFileName(image.key, editKey)
    image[editKey] = resizedFName
    return resizedFName
end
function eifo.vrecord.Product:newImageObj(rawFileName)
    return setmetatable({key = rawFileName}, {__index = getEditedFileName})
end
function eifo.vrecord.Product:get_images()
    local pseudoId = self.pseudoId
    local fileNames = eifo.store:getProductImageFileNames(pseudoId)
    if not fileNames then
        return {}
    end
    for i = #fileNames, 1, -1 do
        if fileNames[i]:sub(1, 1) == "." then
            table.remove(fileNames, i)
        end
    end
    local images = {}
    local num = #fileNames
    for i = 1, num, 1 do
        local nameParts = utils.newArray(4)
        for part in fileNames[i]:gmatch("([^/%.]+)") do
            nameParts[#nameParts+1] = part
        end
        local numParts = #nameParts
        local fileName = nameParts[1].."."..nameParts[numParts]
        assert(fileName, "invalid image fileName: "..fileNames[i])
        local image = images[fileName]
        if not image then
            image = self:newImageObj("/"..pseudoId.."/"..fileName)
            images[fileName] = image
        end
        if numParts == 4 then
            local signature, size = nameParts[2], nameParts[3]
            image[size] = "/"..pseudoId.."."..signature.."."..size.."."..fileName
        end
    end
    return images
end
local function addToArrayField(tbl, fieldName, value)
    local array = tbl[fieldName]
    if not array then
        array = utils.ArraySet.new()
        tbl[fieldName] = array
    end
    array[#array+1] = value
    return array
end

function eifo.vrecord.Product:onLoaded()
    local vmodel = self.vModel
    local applFeatures = self.applFeatures
    if applFeatures and #applFeatures > 0 then
        local features = vmodel.selectableFeatures
        if not features then
            features = {}
            vmodel.selectableFeatures = features
        end
        for i = #applFeatures, 1, -1 do
            local applFeature = applFeatures[i]
            local feature = applFeature.productFeature
            local applType = applFeature.applTypeEnumId
            local featureType = feature.productFeatureTypeEnumId
            if applType == "Selectable" then
                addToArrayField(features, featureType, feature)
            else
                addToArrayField(getmetatable(feature), "products", self)
            end
        end
    end
    local assocs = self.assocs
    if assocs and #assocs > 0 then
        local meta = getmetatable(self)
        for j = #assocs, 1, -1 do
            local assoc = assocs[j]
            local assocType = assoc.productAssocTypeEnumId
            addToArrayField(meta, assocType, assoc.toProduct) --without 'Id', to get the object instead of the Id only
        end
    end
end