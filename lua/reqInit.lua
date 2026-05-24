local ngx = ngx
local utils = require "eifo.utils"

local ck = require "resty.cookie"
local cookie, err = ck:new()
if not cookie then
    ngx.log(ngx.ERR, err)
    --ngx.ctx.lang = "en"
    return
end
local lang = ngx.var.lang
--ngx.log(ngx.INFO, "lang from var: ", lang or "NIL")
if lang ~= ngx.var.clang then
    cookie:set({
        key = "lang",
        value = ngx.var.lang,
        path = "/",
        max_age = 365*24*60*60,  --one year
        httponly = true
    })
end

-- get all cookies
utils.mergeRef(ngx.ctx, cookie:get_all())