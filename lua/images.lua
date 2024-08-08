local function responseError(status, msg)
    ngx.status = status
    ngx.header["Content-type"] = "text/html"
    ngx.say(msg or "not found")
    ngx.exit(0)
end

local pseudoId, sig, size, fileName, ext = ngx.var.pseudoId,
  ngx.var.sig, ngx.var.size, ngx.var.fileName, ngx.var.ext

if size == "000x000" then
    size = ""
end
if (sig == nil or sig == "" or sig == "_NA_") and size ~= "" then
    responseError(ngx.HTTP_FORBIDDEN, "Token is required ")
    return
end

local store = eifo.store
local srcFile = nil
if fileName == "_NA_" then -- get image file names
    fileName = nil
    local tblClass = eifo.db.table.Product
    local productId = tblClass._prefix.."."..pseudoId
    local conn = eifo.db.conn.redis()
    if not conn then
        responseError(ngx.HTTP_INTERNAL_SERVER_ERROR, "Got some problems! We will fix it soon. Please come back later")
        return
    end
    conn:connect()
    local tblAssoc = eifo.db.table.ProductAssoc:new({conn = conn})
    local assocs = tblAssoc:loadByFk("toProductId", productId, conn)
    if not assocs or #assocs == 0 then
        ngx.log(ngx.INFO, "Product assocs of "..productId.." is not found")
        responseError(ngx.HTTP_NOT_FOUND, "Product assocs of "..productId.." is not found")
        return
    end
    local assoc = nil
    for i = #assocs, 1, -1 do
        if assocs[i].productAssocTypeEnumId == "e.PatVariant" then
            assoc = assocs[i]
            break
        end
    end
    if not assoc then
        ngx.log(ngx.INFO, "Product assocs of "..productId.." is not found")
        responseError(ngx.HTTP_NOT_FOUND, "Product assocs of "..productId.." is not found")
        return
    end
    pseudoId = assoc.product.pseudoId
    conn:disconnect()
    local imgNames = store:getProductImageFileNames(pseudoId)
    if #imgNames == 0 then
        responseError(ngx.HTTP_NOT_FOUND, "Product ID  "..productId.." has no images")
        return
    end
    local featureMap = assoc.toProduct.distinguishFeatures
    local destUrl = nil
    for i = #imgNames, 1, -1 do -- search for image fileName and destUrl:
        local fr, to = imgNames[i]:find("^[^%.]+%.")
        if fr == 1 and to > 1 then
            local matched = true
            local namePart = imgNames[i]:sub(fr, to - 1)
            local featurePart = namePart:find("_%a+$")
            if featurePart then
                for _, feature in pairs(featureMap) do
                    if feature.noImageDiff ~= 'Y' then
                        local abbrev = feature.abbrev
                        if not featurePart:find(abbrev) then
                            matched = false
                            break
                        end
                    end
                end
                if matched then
                    local iFr, iTo = imgNames[i]:find("%d%d%d?%d?[xX]%d%d%d?%d?")
                    local fSize = fr and imgNames[i]:sub(iFr, iTo) or nil
                    ngx.log(ngx.DEBUG, "fSize = "..(fSize or "nil")..", size = "..size)
                    if fSize == size then
                        destUrl = imgNames[i]
                        break
                    end
                    if fSize == nil then
                        srcFile = imgNames[i]
                        fileName = namePart
                    end
                end
            end
        end
    end
    if destUrl ~= nil then
        destUrl = "/"..pseudoId.."/"..destUrl
        ngx.log(ngx.DEBUG, "Redirecting to "..destUrl)
        ngx.exec(destUrl)
        return
    end
    if fileName == nil or srcFile == nil then
        ngx.log(ngx.INFO, "Not found any image for product "..pseudoId)
        responseError(ngx.HTTP_NOT_FOUND, "Not found any image for product "..pseudoId)
        return
    end
    local sessionToken = store:getSessionToken()
    if sig ~= sessionToken then
        ngx.log(ngx.INFO, "Invalid token: "..sig..", expected token: "..sessionToken)
        responseError(ngx.HTTP_FORBIDDEN, "Invalid token "..sig)
        return
    end
    sig = nil
    local fr, to = srcFile:find("%.%a+$")
    if fr then
        ext = srcFile:sub(fr + 1, to)
    end
end

local signature = store:getSignature(fileName.."."..size)
if sig == nil or signature ~= sig then
    responseError(ngx.HTTP_FORBIDDEN, "Invalid signature: sig = "..sig..", signature="..signature)
    return
end

local imgDir = eifo.basePath.."/home/img/"..pseudoId
if srcFile == nil then
    srcFile = imgDir.."/"..fileName.."."..ext
else
    srcFile = imgDir.."/"..srcFile
end

-- make sure the file exists
local file = io.open(srcFile, "r")
if not file then
    responseError(ngx.HTTP_NOT_FOUND, "File not found")
    return
else
    file:close()
end

-- resize the image
local destFile = "/"..fileName.."."..signature.."."..size.."."..ext
local magick = require("resty.imagick")
local img = assert(magick.load_image(srcFile))
img:thumb(size)
local ok, err = img:write(imgDir..destFile)
if not ok then
    responseError(ngx.HTTP_INTERNAL_SERVER_ERROR, err or "Cann't write file")
    return
end

local destUrl = "/"..pseudoId..destFile
ngx.log(ngx.DEBUG, "Redirecting to "..destUrl)
ngx.exec(destUrl)