ngx.log(ngx.INFO, "Base path: "..eifo.basePath)
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
eifo._lazyObjs = {}
eifo._lazyObjs["store"] = require "eifo.store"

eifo.db.conn = require "eifo.db.conn"
eifo.db.table = require "eifo.db.table.init"

local viewClass = require "eifo.view"
local viewPath = eifo.basePath.."/lua/view"
local startPos = string.len(viewPath) + 1
local templates = {}

local cmd = "find "..viewPath.." -name '*.view.html'"
ngx.log(ngx.INFO, "Searching views: "..cmd)
local pfile, err = io.popen(cmd, "r")
if not pfile then
    ngx.log(ngx.DEBUG, err or ("Can not open directory: "..viewPath))
    return nil, err
end
local line = pfile:read('*l')
while line do
    ngx.log(ngx.INFO, "Initializing view "..line)
    local uri = string.sub(line, startPos, -11) --remove ".view.html"
    templates[uri] = true
    line = pfile:read('*l')
end
pfile:close()

local __route = {
    getRoute = function (self, params)
        local node = self
        local route = self.view and self or nil
        for i = self.pos + 1, #params, 1 do
            if node[params[i]] then
                if node[params[i]].view then
                    route = node[params[i]]
                end
                node = node[params[i]]
            end
        end
        return route
    end
}
eifo.route = setmetatable({pos = 0}, {__index = __route})
local function addRoute(paths, view)
    local route = eifo.route
    for i = 1, #paths, 1 do
        if paths[i] ~= "index" then
            if not route[paths[i]] then
                route[paths[i]] = setmetatable({pos = i}, {__index = __route})
            end
            route = route[paths[i]]
        end
    end
    assert(route.view == nil, "There is another view routed to this path: "..(route.view and route.view.name or "nil"))
    route.view = view
end
cmd = "find "..viewPath.." -name '*.lua'"
pfile, err = io.popen(cmd, "r")
if not pfile then
    ngx.log(ngx.DEBUG, err or ("Can not open directory: "..viewPath))
    return nil, err
end
line = pfile:read('*l')
local utils = eifo.utils
while line do
    ngx.log(ngx.INFO, "Initializing view "..line)
    local uri = string.sub(line, startPos, -5) --remove .lua
    local paths = utils.splitStr(string.sub(uri, 1), "/")
    local template = templates[uri] and uri..".view.html" or nil
    local view = viewClass:new(paths, template)
    if view then
        view.contentType = template and "text/html; charset=utf-8" or "application/json; charset=utf-8"
        addRoute(paths, view)
    else
        ngx.log(ngx.WARN, "Ignored view "..table.concat(paths, "/")..": empty configuration")
    end
    line = pfile:read('*l')
end
pfile:close()

-- local log = ngx.log
-- local vmIndex, vmCategory, vmCatRollup, vmCatMem, vmProduct, vmAssocs, vmFeature, vmFeatureAppl, err

-- log(ngx.INFO, "Initilizing EIFO...")
-- if not table.unpack then
--     table.unpack = unpack
-- end
-- eifo.utils = require "eifo.utils"
-- eifo.db.conn = require "eifo.dbconn"
-- eifo.db.ed = require "eifo.dao"
-- eifo.workPermit = require "eifo.workpermit"
-- eifo._lazyObjs["store"] = require "eifo.store"
-- eifo.VModelBuilder = require "eifo.vmodel"
-- eifo.view = require "eifo.view"

-- vmIndex, err = eifo.VModelBuilder.new("masterLayout", "_Index")
-- if not vmIndex then
--     return error(err)
-- end

-- log(ngx.INFO, "RIGHT JOIN: Index to ProductCategory")
-- vmCategory, err = vmIndex:rightJoin("ProductCategory", "_idx", "categories")
-- if not vmCategory then
--     log(ngx.ERR, "RIGHT JOIN: Index to ProductCategory FAILED")
--     return error(err)
-- end
-- vmCatRollup, err = vmCategory:rightJoin("ProductCategoryRollup", "productCategoryId", "parents")
-- if not vmCatRollup then
--     return error(err)
-- end
-- --vmCatRollup:leftJoin("parentProductCategoryId", "children")
-- vmCatRollup, err = vmCategory:rightJoin("ProductCategoryRollup", "parentProductCategoryId", "children")
-- if not vmCatRollup then
--     return error(err)
-- end
-- vmCatRollup.removeExpired = true
-- vmCatMem, err = vmCategory:rightJoin("ProductCategoryMember", "productCategoryId", "catMems")
-- if not vmCatMem then
--     return error(err)
-- end
-- vmCatMem.removeExpired = true

-- vmProduct, err = vmIndex:rightJoin("Product", "_idx", "products")
-- if not vmProduct then
--     return error(err)
-- end

-- vmCatMem, err = vmProduct:rightJoin("ProductCategoryMember", "productId", "catMems")
-- if not vmCatMem then
--     return error(err)
-- end
-- vmProduct = vmCatMem:leftJoin("productId", "catMems")
-- if not vmProduct then
--     return error(err)
-- end

-- vmAssocs, err = vmProduct:rightJoin("ProductAssoc", "toProductId", "frAssocs")
-- if not vmAssocs then
--     return error(err)
-- end
-- vmAssocs, err = vmProduct:rightJoin("ProductAssoc", "productId", "assocs")
-- if not vmAssocs then
--     return error(err)
-- end

-- vmFeatureAppl, err = vmProduct:rightJoin("ProductFeatureAppl", "productId", "applFeatures")
-- if not vmFeatureAppl then
--     return error(err)
-- end

-- vmFeature, err = vmFeatureAppl:leftJoin("productFeatureId", "applProducts")
-- if not vmFeature then
--     return error(err)
-- end

-- -- local vmIndex = require "view.index"
-- -- local vmProduct = require "view.products.detail"
-- -- local vmProductIdx = require "view.products.index"

-- eifo.view.layout = eifo.view.new("layouts", "layout/master.view.html", vmIndex, 0)
-- eifo.view.layout.ignoredTables = "Product"

-- eifo.view.index = eifo.view.new(nil, "index.view.html", vmIndex, 0)
-- local productDetailView = eifo.view.index:createSub("products", "products/detail.view.html", vmProduct, 1)
-- -- productDetailView.ignoredTables = "ProductCategoryMember"
-- -- local vProductIdx = vProduct:createSub("index", "products/index.view.html", vmProductIdx, 0)

-- -- local vmCats = require "view.layout.index"
-- -- eifo.view.index:createSub("layouts", "layout/master.view.html", vmCats, 0)
