eifo.utils = require "eifo.utils"
local ngx = ngx
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
if string.sub(eifo.basePath, -1) == '/' then
    eifo.basePath = string.sub(eifo.basePath, 1, -2) -- remove last slash
end
eifo._lazyObjs = {}
eifo._lazyObjs["store"] = require "eifo.store"
eifo._lazyObjs["indexes"] = require "eifo.indexes"
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

ngx.log(ngx.INFO, "Base path: "..eifo.basePath)

eifo.route = Route:new({pos=0, basePath=eifo.basePath.."/home"})

local templatePaths = {}
do
    local cmd = "find "..viewPath.." -name '*.view.*'"
    ngx.log(ngx.INFO, "Searching all templates: "..cmd)
    local pfile, err = io.popen(cmd, "r")
    if not pfile then
        ngx.log(ngx.DEBUG, err or ("Can not open directory: "..viewPath))
        return nil, err
    end
    local templatePath = pfile:read('*l')
    while templatePath do
        local fr, _ = string.find(templatePath, "%.view%.%a+$")
        if fr then
            local uri = string.sub(templatePath, startPos, fr - 1) --remove ".view.*"
            templatePaths[uri] = templatePath
        else
            ngx.log(ngx.WARN, "Ignoring invalid path "..templatePath)
        end
        templatePath = pfile:read('*l')
    end
    pfile:close()
end

local cmd = "find "..viewPath.." -name '*.lua'"
local pfile, err = io.popen(cmd, "r")
if not pfile then
    ngx.log(ngx.DEBUG, err or ("Can not open directory: "..viewPath))
    return nil, err
end
local luaPath = pfile:read('*l')
while luaPath do
    ngx.log(ngx.INFO, "Initializing view "..luaPath)
    local uri = string.sub(luaPath, startPos, -5) --remove .lua

    local view, paths = View.loadView(uri, templatePaths[uri])
    templatePaths[uri] = nil --> remove from templatePaths, as it is already processed
    if view then
        eifo.route:addView(paths, view)
    else
        ngx.log(ngx.WARN, "Ignored view "..table.concat(paths, "/")..": empty or invalid view configuration")
    end
    luaPath = pfile:read('*l')
end
pfile:close()

for uri, tmplFile in pairs(templatePaths) do
    local paths = eifo.utils.splitStr(string.sub(uri, 1), "/")
    eifo.route:addView(paths, {filePath = tmplFile})
end