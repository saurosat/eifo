local utils = eifo.utils
local params = eifo.utils.splitStr(ngx.var.params, "/")
if not params or #params == 0 then
    ngx.say("Please pass in a message")
    return
end
local imgDir = params[1]
if imgDir then
    eifo.store:getProductImages(imgDir)
end
