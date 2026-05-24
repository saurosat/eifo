local utils = require "eifo.utils"
local Record = require "eifo.db.record.Record"
local record = Record:createSubClass({className = "Product", i18nCols = utils.ArraySet:new({"productName", "description", "comments"})})

function record:newImageObj(rawFileName)
    return setmetatable({key = rawFileName}, {
        __index = function (image, editKey)
            if editKey == nil or editKey == "" or editKey == "0x0" or editKey == "0X0" or editKey == "original" then
                return rawget(image, "0x0")
            end
            local resizedFName = eifo.store:getResizedImgUrl(image.key, editKey)
            image[editKey] = resizedFName
            return resizedFName
        end
    })
end
function record:getImageUrls(size)
    local imageUrls = self:getMetaValue("imageUrlsBySize", true)
    if not imageUrls then
        imageUrls = {}
        self:setMetaValue("imageUrlsBySize", imageUrls)
    end
    if imageUrls[size] then
        return imageUrls[size]
    end

    local images = self:getImages()
    local urls = {}
    for _, image in pairs(images) do
        urls[#urls+1] = image[size]
    end
    imageUrls[size] = urls
    return urls
end

function record:getImages()
    local pseudoId = self.pseudoId
    if not pseudoId then
        utils.logWarn("pseudoId is NIL in record "..self._table._name..".key = "..self.key)
        return {}
    end
    local images = self:getMetaValue("images", true)
    if images then
        return images
    end

    images = {}
    self:setMetaValue("images", images)
    local fileNames = eifo.store:getProductImageFileNames(pseudoId)
    if not fileNames or #fileNames == 0 then
        utils.logDebug(pseudoId.." has no image files")
        return images
    end
    local num = #fileNames
    for i = 1, num, 1 do
        local fileName = fileNames[i]
        utils.logDebug("Image file "..fileName)
        local fPseudoId, ori, ext, sig, size, sFeature = eifo.store:extractImgInfo(fileName)
        if not ori or not ext then
            utils.logWarn("Invalid image fileName: "..fileName)
        else
            local oriFileName = ori..(sFeature and ("."..sFeature) or "").."."..ext
            local image = images[oriFileName]
            if not image then
                image = self:newImageObj("/"..fPseudoId.."/"..oriFileName)
                if sFeature and sFeature:len() > 0 then
                    local abbrevs = {}
                    for abbrev in string.gmatch(sFeature, "[^_]+") do
                        --utils.logDebug("fPseudoId = "..fPseudoId..", abbrev = "..abbrev)
                        abbrevs[#abbrevs+1] = abbrev
                    end
                    image.features = abbrevs
                end
                images[oriFileName] = image
            end
            -- cache uri for size
            if sig and size then
                image[size] = "/"..fPseudoId.."."..sig.."."..size.."."..oriFileName
            else
                image["0x0"] = "/"..fPseudoId.."."..oriFileName
            end
        end
        --utils.logDebug("/"..fPseudoId.."/"..fileName)
    end

    return images
end
function record:getSelectableFeatures()
    if self.productTypeEnumId ~= "e.PtVirtual" then
        return nil
    end

    if self:getMetaValue("selectableFeatures") then
        return self:getMetaValue("selectableFeatures")
    end
    local features = {}
    self:setMetaValue("selectableFeatures", features)
    local featureAppls = self.featureAppls
    if not featureAppls then
        utils.logDebug("No featureAppls")
        return features
    end
    for i = 1, #featureAppls, 1 do
        local featureAppl = featureAppls[i]
        if featureAppl.applTypeEnumId == "e.PfatSelectable" then
            local feature = featureAppl.productFeature
            if feature then
                local fType = feature.productFeatureTypeEnum
                if not features[fType] then
                    features[fType] = utils.ArraySet:new()
                end
                features[fType]:add(feature)
            end
        end
    end
    -- Keep total of prev elements in index 0
    local numFeatures = 0
    for _, fArray in pairs(features) do
        fArray[0] = numFeatures
        numFeatures = numFeatures + #fArray
    end
    return features
end
function record:getVirtualProduct()
    if self.productTypeEnumId == "e.PtVirtual" then
        return self
    end
    if self:getMetaValue("virtualProduct") then
        return self:getMetaValue("virtualProduct")
    end
    local assocs = self.fromAssocs
    if not assocs or #assocs == 0 then
        utils.logDebug("Not found assocs for product "..self.key)
        return nil
    end
    local virtualProduct = nil
    for i = 1, #assocs, 1 do
        local assoc = assocs[i]
        local product = assoc.product
        if assoc.productAssocTypeEnumId == "e.PatVariant" then
            if product.productTypeEnumId == "e.PtVirtual" then
                virtualProduct = product
                break
            end
        end
    end
    self:setMetaValue("virtualProduct", virtualProduct)
    return virtualProduct
end
function record:getVariants()
    --utils.logDebug("product:getVariants "..self.productTypeEnumId)
    if self.productTypeEnumId ~= "e.PtVirtual" then
        utils.logDebug("NOT a e.PtVirtual type: "..self.productTypeEnumId)
        return nil
    end
    if self:getMetaValue("variants") then
        return self:getMetaValue("variants")
    end
    local variants = {}
    self:setMetaValue("variants", variants)
    local features = self:getSelectableFeatures()
    if not features or not next(features) then
        utils.logDebug("Not found selectableFeatures for product "..self.key)
        return nil
    end
    -- for k, _ in pairs(features) do
    --     utils.logDebug(utils.toJson(k))
    -- end
    local assocs = self.assocs
    if not assocs then
        utils.logDebug("Not found assocs for product "..self.key)
        return nil
    end
    local maxIndex = 0
    for i = 1, #assocs, 1 do
        if assocs[i].productAssocTypeEnumId == "e.PatVariant" then
            local variant = assocs[i].toProduct
            assert(variant, assocs[i].toProductId.." is not found")
            local index = 0
            local variantFeatures = variant.distinguishFeatures
            if variantFeatures then
                for k, v in pairs(variantFeatures) do
                    local sFeature = assert(features[k], "Distinguish feature key doesn't exist in Selectable features: "..k.key)
                    index = index + sFeature[0] + sFeature:index(v)
                end
                variants[index] = variant
                --utils.logDebug("index = "..tostring(index))
                if maxIndex < index then
                    maxIndex = index
                end                
            end
        end
    end
    --utils.logDebug("maxIndex = "..tostring(maxIndex))
    for i = 1, maxIndex, 1 do
        if not variants[i] then
            variants[i] = false
        end
    end
    return variants
end
function record:getDistinguishFeatures()
    if self.productTypeEnumId ~= "e.PtAsset" then
        utils.logDebug("NOT a e.PtAsset type: "..self.productTypeEnumId)
        return nil
    end
    if self:getMetaValue("distinguishFeatures") then
        return self:getMetaValue("distinguishFeatures")
    end

    local features = {}
    self:setMetaValue("distinguishFeatures", features)
    local featureAppls = self.featureAppls
    if not featureAppls then
        utils.logDebug("No featureAppls")
        return features
    end
    for i = 1, #featureAppls, 1 do
        local featureAppl = featureAppls[i]
        utils.logDebug("featureAppls type = "..featureAppl.applTypeEnumId)
        if featureAppl.applTypeEnumId == "e.PfatDistinguishing" then
            local feature = featureAppl.productFeature
            local fType = feature.productFeatureTypeEnum
            features[fType] = feature --> for Distinguishing, should only one per fType
        end
    end
    return features
end

function record:onLoaded()
    local assocs = self.assocs
    if assocs and #assocs > 0 then
        local meta = getmetatable(self)
        for j = #assocs, 1, -1 do
            local assoc = assocs[j]
            local assocType = assoc.productAssocTypeEnumId
            if not meta[assocType] then
                meta[assocType] = utils.ArraySet:new()
            end
            if assoc.toProduct then
                meta[assocType]:add(assoc.toProduct) --without 'Id', to get the object instead of the Id only
            end
        end
    end
end
function record:toJson(columns)
    local refs = {self}
    local json = "{"
    for key, value in pairs(self) do
        json = json..'"'..key..'": '..utils.toJson(value, refs)..", "
    end
    columns = columns or self._table.toJsonColumns
    --utils.logDebug("columns = "..(columns and table.concat(columns, ", ") or "null"))
    if columns then
        for i = 1, #columns, 1 do
            local colName = columns[i]
            if colName == "featureById" then
                local featuresByType = self:getSelectableFeatures()
                if not featuresByType then
                    featuresByType = self:getDistinguishFeatures()
                end
                if featuresByType and next(featuresByType) then
                    local fIdByTypeJson = "{"
                    local fByIdJson = "{"
                    local fTypeById = "{"
                    for fType, fArray in pairs(featuresByType) do
                        if #fArray == 0 then
                            fArray = {fArray}
                            fArray[0] = -1 -- Not applicable
                        end
                        local baseIndex = fArray[0]
                        fTypeById = fTypeById..'"'..fType.enumId..'": '..utils.toJson(fType, refs)..", "
                        fIdByTypeJson = fIdByTypeJson..'"'..fType.enumId..'": '..'['
                        for i = 1, #fArray, 1 do
                            if baseIndex >= 0 then
                                fArray[i].maskIndex = baseIndex + i
                            end
                            fByIdJson = fByIdJson..'"'..fArray[i].productFeatureId..'": '..utils.toJson(fArray[i], refs)..", "
                            fIdByTypeJson = fIdByTypeJson..'"'..fArray[i].productFeatureId..'", '
                        end
                        fIdByTypeJson = fIdByTypeJson:sub(1, -3)..'], '
                    end
                    fTypeById = fTypeById:sub(1, -3).."}"
                    fIdByTypeJson = fIdByTypeJson:sub(1, -3).."}"
                    fByIdJson = fByIdJson:sub(1, -3).."}"
                    json = json..'"featureIdsByType": '..fIdByTypeJson..', '
                    json = json..'"featureById": '..fByIdJson..', '
                    json = json..'"featureTypeById": '..fTypeById..', '
                end
            elseif colName == "maskVariants" then
                local variants = self:getVariants()
                if variants and #variants > 0 then
                    json = json..'"maskVariants": [null, '
                    for j = 1, #variants, 1 do
                        json = json..(variants[j] and variants[j]:toJson(columns) or "null")..", "
                    end
                    json = json:sub(1, -3).."], "
                end
            elseif colName:sub(1, 13) == "productImages" then
                local images = self:getImages();
                if images then
                    local sSizes = colName:sub(14, -1)
                    local sizes = {}
                    if sSizes:len() > 0 then
                        for size in sSizes:gmatch("%d+[xX]%d+") do
                            sizes[#sizes+1] = size
                        end
                    else
                        sizes[#sizes+1] = ""
                    end
                    for j = 1, #sizes, 1 do
                        local size = sizes[j]
                        json = json..'"images'..size..'": ['
                        for _, image in pairs(images) do
                            json = json..'"'..image[size]..'", '
                        end
                        json = json:sub(1, -3).."], "
                    end 
                end
            else
                local colValJson = utils.toJson(utils.getPropertyValue(self, colName), refs)
                if colValJson then
                    json = json..'"'..columns[i]..'": '..colValJson..", "
                end
            end
        end
    end
    json = json:sub(1, -3).."}"
    return json
end
return record