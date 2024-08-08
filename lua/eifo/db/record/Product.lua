local utils = require "eifo.utils"
local Record = require "eifo.db.record.Record"
local record = Record:createSubClass({className = "Product"})

function record:newImageObj(rawFileName)
    return setmetatable({key = rawFileName}, {
        __index = function (image, editKey)
            local resizedFName = eifo.store:getResizedFileName(image.key, editKey)
            image[editKey] = resizedFName
            return resizedFName
        end
    })
end
function record:getImageUrls(size)
    if self.imageUrlsBySize then
        return self.imageUrlsBySize[size]
    end
    self.imageUrlsBySize = {}

    local images = self:getImages()
    local urls = {}
    for _, image in pairs(images) do
        urls[#urls+1] = image[size]
    end
    self.imageUrlsBySize[size] = urls
    return urls
end
function record:getImages()
    local images = {}
    local pseudoId = self.pseudoId
    --ngx.log(ngx.DEBUG, pseudoId..".getImages()")
    local fileNames = eifo.store:getProductImageFileNames(pseudoId)
    if not fileNames or #fileNames == 0 then
        ngx.log(ngx.DEBUG, pseudoId.." has no image files")
        return {}
    end
    for i = #fileNames, 1, -1 do
        if fileNames[i]:sub(1, 1) == "." then
            table.remove(fileNames, i)
        end
    end
    local num = #fileNames
    for i = 1, num, 1 do
        --ngx.log(ngx.DEBUG, "Image file "..fileNames[i])
        local nameParts = utils.newArray(4)
        for part in fileNames[i]:gmatch("([^/%.]+)") do
            nameParts[#nameParts+1] = part
        end
        local numParts = #nameParts
        local fileName = nameParts[1].."."..nameParts[numParts]
        assert(fileName and string.len(fileName) > 4, "invalid image fileName: "..fileNames[i])
        local image = images[fileName]
        if not image then
            image = self:newImageObj("/"..pseudoId.."/"..fileName)
            images[fileName] = image
        end
        if numParts == 4 then
            local signature, size = nameParts[2], nameParts[3]
            image[size] = "/"..pseudoId.."."..signature.."."..size.."."..fileName
        end
        --ngx.log(ngx.DEBUG, "/"..pseudoId.."/"..fileName)
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
        ngx.log(ngx.DEBUG, "No featureAppls")
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
    local assocs = self.assocs
    if not assocs or #assocs == 0 then
        ngx.log(ngx.DEBUG, "Not found assocs for product "..self.key)
        return nil
    end
    local virtualProduct = nil
    for i = 1, #assocs, 1 do
        if assocs[i].productAssocTypeEnumId == "e.PatVariant" then
            virtualProduct = assocs[i].product
            break
        end
    end
    self:setMetaValue("virtualProduct", virtualProduct)
    return virtualProduct
end
function record:getVariants()
    --ngx.log(ngx.DEBUG, "product:getVariants "..self.productTypeEnumId)
    if self.productTypeEnumId ~= "e.PtVirtual" then
        ngx.log(ngx.DEBUG, "NOT a e.PtVirtual type: "..self.productTypeEnumId)
        return nil
    end
    if self:getMetaValue("variants") then
        return self:getMetaValue("variants")
    end
    local variants = {}
    self:setMetaValue("variants", variants)
    local features = self.selectableFeatures
    for k, _ in pairs(features) do
        ngx.log(ngx.DEBUG, utils.toJson(k))
    end
    local assocs = self.assocs
    if not assocs then
        ngx.log(ngx.DEBUG, "Not found assocs for product "..self.key)
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
                ngx.log(ngx.DEBUG, "index = "..tostring(index))
                if maxIndex < index then
                    maxIndex = index
                end                
            end
        end
    end
    ngx.log(ngx.DEBUG, "maxIndex = "..tostring(maxIndex))
    for i = 1, maxIndex, 1 do
        if not variants[i] then
            variants[i] = false
        end
    end
    return variants
end
function record:getDistinguishFeatures()
    if self.productTypeEnumId ~= "e.PtAsset" then
        ngx.log(ngx.DEBUG, "NOT a e.PtAsset type: "..self.productTypeEnumId)
        return nil
    end
    if self:getMetaValue("distinguishFeatures") then
        return self:getMetaValue("distinguishFeatures")
    end

    local features = {}
    self:setMetaValue("distinguishFeatures", features)
    local featureAppls = self.featureAppls
    if not featureAppls then
        ngx.log(ngx.DEBUG, "No featureAppls")
        return features
    end
    for i = 1, #featureAppls, 1 do
        local featureAppl = featureAppls[i]
        ngx.log(ngx.DEBUG, "featureAppls type = "..featureAppl.applTypeEnumId)
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
            meta[assocType]:add(assoc.toProduct) --without 'Id', to get the object instead of the Id only
        end
    end
end

return record