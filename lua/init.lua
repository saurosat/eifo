eifo.utils = require "eifo.utils"

setmetatable(eifo, {__index = function(tbl, key)
    local lazyObj = tbl._lazyObjs[key]
    if lazyObj then
        if not lazyObj.isLoaded then 
            lazyObj:load()
        end
        return lazyObj
    end
    return nil
end})
eifo.basePath = ngx.config.prefix()
eifo._lazyObjs = {}
eifo._lazyObjs["store"] = require "eifo.store"

require "eifo.db.conn"
require "eifo.db.table.init"
local View = require("eifo.view")
local Route = require("eifo.route")


local viewPath = eifo.basePath.."/lua/view"
local startPos = string.len(viewPath) + 1
local tmplFiles = {}

ngx.log(ngx.INFO, "Base path: "..eifo.basePath)

eifo.route = Route:new{pos=0, path=eifo.basePath.."/home"}

local cmd = "find "..viewPath.." -name '*.view.html'"
ngx.log(ngx.INFO, "Searching views: "..cmd)
local pfile, err = io.popen(cmd, "r")
if not pfile then
    ngx.log(ngx.DEBUG, err or ("Can not open directory: "..viewPath))
    return nil, err
end
local filePath = pfile:read('*l')
while filePath do
    local uri = string.sub(filePath, startPos, -11) --remove ".view.html"
    tmplFiles[uri] = filePath
    filePath = pfile:read('*l')
end
pfile:close()

cmd = "find "..viewPath.." -name '*.lua'"
pfile, err = io.popen(cmd, "r")
if not pfile then
    ngx.log(ngx.DEBUG, err or ("Can not open directory: "..viewPath))
    return nil, err
end
filePath = pfile:read('*l')
while filePath do
    ngx.log(ngx.INFO, "Initializing view "..filePath)
    local uri = string.sub(filePath, startPos, -5) --remove .lua
    local paths = eifo.utils.splitStr(string.sub(uri, 1), "/")
    local viewName = "view."..table.concat(paths, ".")
    local view = View:loadView(viewName, tmplFiles[uri])
    tmplFiles[uri] = nil
    if view then
        eifo.route:addView(paths, view)
    else
        ngx.log(ngx.WARN, "Ignored view "..table.concat(paths, "/")..": empty or invalid view configuration")
    end
    filePath = pfile:read('*l')
end
pfile:close()

for uri, filePath in pairs(tmplFiles) do
    local paths = eifo.utils.splitStr(string.sub(uri, 1), "/")
    eifo.route:addView(paths, {filePath = filePath})
end