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
    local images = rawget(self, "images")
    if images then
        return images
    end
    images = {}
    local pseudoId = self.pseudoId
    ngx.log(ngx.DEBUG, pseudoId..".getImages()")
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
        ngx.log(ngx.DEBUG, "Image file "..fileNames[i])
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
        ngx.log(ngx.DEBUG, "/"..pseudoId.."/"..fileName)
    end
    return images
end
function record:getSelectableFeatures()
    if self.selectableFeatures then
        return self.selectableFeatures
    end
    local features = {}
    self:setMetaValue("selectableFeatures", features)
    local featureAppls = self.featureAppls
    if not featureAppls or not next(featureAppls) then
        return features
    end
    for i = 1, #featureAppls, 1 do
        if featureAppls.applTypeEnumId == "PfatSelectable" then
            local feature = featureAppls.productFeature
            if feature then
                local fType = feature.productFeatureTypeEnumId
                if not features[fType] then
                    features[fType] = utils.ArraySet:new()
                end
                features[fType]:add(feature)
            end
        end
    end
    return features
end
function record:getDistinguishFeatures()
    if self.distinguishFeatures then
        return self.distinguishFeatures
    end
    local features = {}
    self:setMetaValue("distinguishFeatures", features)
    local featureAppls = self.featureAppls
    if not featureAppls or not next(featureAppls) then
        return features
    end
    for i = 1, #featureAppls, 1 do
        if featureAppls.applTypeEnumId == "PfatDistinguishing" then
            local feature = featureAppls.productFeature
            if feature then
                local fType = feature.productFeatureTypeEnumId
                features[fType] = feature --> for Distinguishing, should only one per fType
            end
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