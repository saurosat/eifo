
local log = ngx.log
local vmIndex, vmCategory, vmCatRollup, vmCatMem, vmProduct, vmAssocs, vmFeature, vmFeatureAppl, err

log(ngx.INFO, "Initilizing EIFO...")
if not table.unpack then
    table.unpack = unpack
end
eifo.utils = require "eifo.utils"
eifo.db.conn = require "eifo.dbconn"
eifo.db.ed = require "eifo.dao"
eifo.workPermit = require "eifo.workpermit"
eifo._lazyObjs["store"] = require "eifo.store"
eifo.VModelBuilder = require "eifo.vmodel"
eifo.view = require "eifo.view"

vmIndex, err = eifo.VModelBuilder.new("masterLayout", "_Index")
if not vmIndex then
    return error(err)
end

log(ngx.INFO, "RIGHT JOIN: Index to ProductCategory")
vmCategory, err = vmIndex:rightJoin("ProductCategory", "_idx", "categories")
if not vmCategory then
    log(ngx.ERR, "RIGHT JOIN: Index to ProductCategory FAILED")
    return error(err)
end
vmCatRollup, err = vmCategory:rightJoin("ProductCategoryRollup", "productCategoryId", "parents")
if not vmCatRollup then
    return error(err)
end
--vmCatRollup:leftJoin("parentProductCategoryId", "children")
vmCatRollup, err = vmCategory:rightJoin("ProductCategoryRollup", "parentProductCategoryId", "children")
if not vmCatRollup then
    return error(err)
end
vmCatRollup.removeExpired = true
vmCatMem, err = vmCategory:rightJoin("ProductCategoryMember", "productCategoryId", "catMems")
if not vmCatMem then
    return error(err)
end
vmCatMem.removeExpired = true

vmProduct, err = vmIndex:rightJoin("Product", "_idx", "products")
if not vmProduct then
    return error(err)
end

vmCatMem, err = vmProduct:rightJoin("ProductCategoryMember", "productId", "catMems")
if not vmCatMem then
    return error(err)
end
vmProduct = vmCatMem:leftJoin("productId", "catMems")
if not vmProduct then
    return error(err)
end

vmAssocs, err = vmProduct:rightJoin("ProductAssoc", "toProductId", "frAssocs")
if not vmAssocs then
    return error(err)
end
vmAssocs, err = vmProduct:rightJoin("ProductAssoc", "productId", "assocs")
if not vmAssocs then
    return error(err)
end

vmFeatureAppl, err = vmProduct:rightJoin("ProductFeatureAppl", "productId", "applFeatures")
if not vmFeatureAppl then
    return error(err)
end

vmFeature, err = vmFeatureAppl:leftJoin("productFeatureId", "applProducts")
if not vmFeature then
    return error(err)
end

-- local vmIndex = require "view.index"
-- local vmProduct = require "view.products.detail"
-- local vmProductIdx = require "view.products.index"

eifo.view.layout = eifo.view.new("layouts", "layout/master.view.html", vmIndex, 0)
eifo.view.layout.ignoredTables = "Product"

eifo.view.index = eifo.view.new(nil, "index.view.html", vmIndex, 0)
local productDetailView = eifo.view.index:createSub("products", "products/detail.view.html", vmProduct, 1)
-- productDetailView.ignoredTables = "ProductCategoryMember"
-- local vProductIdx = vProduct:createSub("index", "products/index.view.html", vmProductIdx, 0)

-- local vmCats = require "view.layout.index"
-- eifo.view.index:createSub("layouts", "layout/master.view.html", vmCats, 0)
