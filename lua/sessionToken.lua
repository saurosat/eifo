---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by tnguyen.
--- DateTime: 12/8/23 12:06 AM
---
local store = require("eifo.store")
if store.hashValue == 0 then
    store:load()
end
local token = store:getSessionToken()
ngx.say("const sessionToken = '"..token.."';")
ngx.say("const storeId = '"..store.storeId.."';")
ngx.say("alert(sessionToken);")