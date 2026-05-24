local ngx = ngx
local function responseError(status, msg, conn)
    if conn then
        conn:disconnect()
    end
    ngx.status = status
    ngx.header["Content-type"] = "text/html"
    ngx.say(msg or "not found")
    ngx.exit(0)
end

local pseudoId, sig, size, fileName, ext = 
        ngx.var.pseudoId, ngx.var.sig, ngx.var.size, ngx.var.fileName, ngx.var.ext

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
    local conn = ngx.ctx.conn
    local shouldDisconnect = false
    if not conn then
        conn = eifo.db.conn.redis()
        if not conn then
            responseError(ngx.HTTP_INTERNAL_SERVER_ERROR, "Got some problems! We will fix it soon. Please come back later")
            return
        end
        conn:connect()
        shouldDisconnect = true
    end
    local productTbl = eifo.db.table.Product:new({conn = nil})
    local product = productTbl:load({pkValue = pseudoId})
    if not product then
        responseError(ngx.HTTP_NOT_FOUND, "Product ID  "..pseudoId.." is not found", shouldDisconnect and conn or nil)
        return        
    end
    local images = product and product.images or nil
    if not images then
        responseError(ngx.HTTP_NOT_FOUND, "Product ID  "..pseudoId.." has no images", shouldDisconnect and conn or nil)
        return
    end
    local destUrl = nil
    for imgName, image in pairs(images) do
        srcFile = imgName
        destUrl = image[size]
        if destUrl then
            break
        end
    end
    if shouldDisconnect then
        conn:disconnect()
    end
    if destUrl then
        ngx.log(ngx.DEBUG, "Redirecting to "..destUrl)
        ngx.exec(destUrl)
        return
    end
    if not srcFile then
        ngx.log(ngx.INFO, "Not found any image for product "..pseudoId)
        responseError(ngx.HTTP_NOT_FOUND, "Not found any image for product "..pseudoId)
        return
    end
    -- Why check token here?
    -- local sessionToken = store:getSessionToken()
    -- if sig ~= sessionToken then
    --     ngx.log(ngx.INFO, "Invalid token: "..sig..", expected token: "..sessionToken)
    --     responseError(ngx.HTTP_FORBIDDEN, "Invalid token "..sig)
    --     return
    -- end
    -- sig = nil
    local fr, to = srcFile:find("%.%a+$")
    if fr then
        ext = srcFile:sub(fr + 1, to)
        fileName = srcFile:sub(1, fr - 1)
    end
end

local signature = store:getSignature(fileName.."."..size)
if sig and signature ~= sig then
    responseError(ngx.HTTP_FORBIDDEN, "Invalid signature: sig = "..sig..", signature="..signature)
    return
end

local imgDir = eifo.basePath.."/home/img/"..pseudoId
if srcFile == nil then
    srcFile = imgDir.."/"..fileName.."."..ext
else
    srcFile = imgDir.."/"..srcFile
end

-- make sure the file exists : No neeeded?
-- local file = io.open(srcFile, "r")
-- if not file then
--     responseError(ngx.HTTP_NOT_FOUND, "File not found")
--     return
-- else
--     file:close()
-- end

-- resize the image
local destFile = "/"..fileName.."."..signature.."."..size.."."..ext
local magick = require("resty.imagick")
local img, loadingErr = magick.load_image(srcFile)
if not img then
    ngx.log(ngx.ERR, "Error loading image file "..srcFile..": "..(loadingErr or "unknown error"))
    responseError(ngx.HTTP_INTERNAL_SERVER_ERROR, loadingErr or "Cann't load image")
    return
end

img:thumb(size)
local ok, err = img:write(imgDir..destFile)
-- img:destroy()
if not ok then
    responseError(ngx.HTTP_INTERNAL_SERVER_ERROR, err or "Cann't write file")
    return
end

local destUrl = "/"..pseudoId..destFile
ngx.log(ngx.DEBUG, "Redirecting to "..destUrl)
ngx.exec(destUrl)