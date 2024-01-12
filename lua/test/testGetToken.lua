local params = eifo.utils.splitStr(ngx.var.params, "/")
if not params or #params == 0 then
    ngx.say("Please pass in a message")
    return
end
local store = eifo.store
if store.hashValue == 0 then
    store:load()
end
ngx.log(ngx.DEBUG, "Signing "..params[1])
local token = store:getSignature(params[1])
ngx.say("Signature of '"..params[1].."' is "..token)