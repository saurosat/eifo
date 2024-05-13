local utils = require "eifo.utils"
local Record = require "eifo.db.record.Record"
if not eifo.db.record.Product then
    return eifo.db.record.Product
end
eifo.db.record.Product = Record:createSubClass()
local record = eifo.db.record.Product

local function getEditedFileName(image, editKey)
    local resizedFName = eifo.store:getResizedFileName(image.key, editKey)
    image[editKey] = resizedFName
    return resizedFName
end
function record:newImageObj(rawFileName)
    return setmetatable({key = rawFileName}, {__index = getEditedFileName})
end
function record:get_images()
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

function record:onLoaded()
    local tbl = self._table
    local applFeatures = self.applFeatures
    if applFeatures and #applFeatures > 0 then
        local features = tbl.selectableFeatures
        if not features then
            features = {}
            tbl.selectableFeatures = features
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

return record