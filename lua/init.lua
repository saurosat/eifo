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
eifo.contentTypes = {
    json = "application/json; charset=utf-8",
    xml = "application/xml; charset=utf-8",
    html = "text/html; charset=utf-8",
    js = "text/javascript; charset=utf-8",
    css = "text/css; charset=utf-8"
}
eifo.pathPrefixes = {
    js = "js",
    css = "css"
}

require "eifo.db.conn"
require "eifo.db.table.init"
local View = require("eifo.view")
local Route = require("eifo.route")

string._specialChars_ = {
    ["\\"] = "\\\\",
    ["\""] = "\\\"",
    ["'"]  = "\\'",
    ["\a"] = "\\a",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
    ["\v"] = "\\v",
}
string.escape = function(s)

    -- Replace known special characters
    s = s:gsub(".", string._specialChars_)

    -- Optionally, escape other non-printable characters
    -- s = s:gsub("([^%z\32-\126])", function(c)
    --     return string.format("\\x%02X", string.byte(c))
    -- end)

    return s
end
local function _encode_char(char)
    return string.format('%%%0X', string.byte(char))
end

string.encode = function (s)
    return (string.gsub(s, "[^%a%d%-_%.!~%*'%(%);/%?:@&=%+%$,#]", _encode_char))
end

local viewPath = eifo.basePath.."/lua/view"
local startPos = string.len(viewPath) + 1
local templatePaths = {}

ngx.log(ngx.INFO, "Base path: "..eifo.basePath)

eifo.route = Route:new{pos=0, basePath=eifo.basePath.."/home"}

local cmd = "find "..viewPath.." -name '*.view.*'"
ngx.log(ngx.INFO, "Searching views: "..cmd)
local pfile, err = io.popen(cmd, "r")
if not pfile then
    ngx.log(ngx.DEBUG, err or ("Can not open directory: "..viewPath))
    return nil, err
end
local filePath = pfile:read('*l')
while filePath do
    local fr, to = string.find(filePath, "%.view%.%a+$")
    if fr then
        local uri = string.sub(filePath, startPos, fr - 1) --remove ".view.*"
        templatePaths[uri] = filePath
    else
        ngx.log(ngx.WARN, "Ignoring invalid path "..filePath)
    end
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
    local templatePath = templatePaths[uri]
    local view = View.loadView(viewName, templatePath)
    templatePaths[uri] = nil
    if view then
        local fileExt
        if templatePath then
            _, _ , fileExt = string.find(templatePath, "%.view%.(%a+)$")
        end
        eifo.route:addView(paths, view, fileExt)
    else
        ngx.log(ngx.WARN, "Ignored view "..table.concat(paths, "/")..": empty or invalid view configuration")
    end
    filePath = pfile:read('*l')
end
pfile:close()

for uri, tmplFile in pairs(templatePaths) do
    local paths = eifo.utils.splitStr(string.sub(uri, 1), "/")
    eifo.route:addView(paths, {filePath = tmplFile})
end