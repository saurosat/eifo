local log = ngx.log
log(ngx.INFO, "Initilizing EIFO...")
local conn = eifo.db.comm
local utils = eifo.utils
local view = eifo.view
local vmodel = eifo.VModelBuilder

local log = ngx.log
local vmIndex, vmCategory, vmCatRollup, vmCatMem, vmProduct, err
vmIndex, err = vmodel.new("index", "_Index")
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
vmCatRollup:leftJoin("parentProductCategoryId", "children")

vmCatMem, err = vmCategory:rightJoin("ProductCategoryMember", "productCategoryId", "catMems")
if not vmCatMem then
    return error(err)
end

vmProduct = vmCatMem:leftJoin("productId", "products")
if not vmProduct then
    return error(err)
end
local vmPrdContent = vmProduct:rightJoin("ProductContent", "productId", "productContents", "entity.productContentTypeEnumId == \"PcntImageUrlSmall\"")

function eifo.getAllProducts(cat)
    local products = {}
    local catMems = cat.catMems
    for i = 1, #catMems, 1 do 
        products[#products + 1] = catMems[i].product
    end
    local childCats = cat.children
    for i = 1, #childCats, 1 do 
        local childCat = childCats[i].productCategory
        local childCatPrds = eifo.getAllProducts(childCat)
        for j = 1, #childCatPrds, 1 do 
            products[#products + 1] = childCatPrds[j]
        end
    end
    return products
end
eifo.view.home = view.new(nil, "index.view.html", vmIndex, 0)
