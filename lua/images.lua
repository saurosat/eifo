local function responseError(status, msg)
    ngx.status = status
    ngx.header["Content-type"] = "text/html"
    ngx.say(msg or "not found")
    ngx.exit(0)
end

local pseudoId, sig, size, fileName, ext = ngx.var.pseudoId,
  ngx.var.sig, ngx.var.size, ngx.var.fileName, ngx.var.ext

local store = eifo.store
local signature = store:getSignature(fileName.."."..size)
if signature ~= sig then
    responseError(ngx.HTTP_FORBIDDEN, "Invalid signature: sig = "..sig..", signature="..signature)
    return
end

local imgDir = eifo.basePath.."/home/img/"..pseudoId
local srcFile = imgDir.."/"..fileName.."."..ext

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