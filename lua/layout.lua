if not eifo.view.layout then
    ngx.log(ngx.ERR, "root view is not initialized")
    eifo.utils.responseError(ngx.HTTP_SERVICE_UNAVAILABLE, "Service is temporarily down")
    return
end
ngx.log(ngx.INFO, "URI: ____"..ngx.var.request_uri.."_____")
local params = eifo.utils.getPathParam(ngx.var.request_uri)
if params[1] == "layouts" then
    table.remove(params, 1)
end

ngx.log(ngx.INFO, table.concat(params, ","))
eifo.view.layout:process(params)