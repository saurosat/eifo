local log = ngx.log
local vmIndex, vmCategory, vmCatRollup, vmCatMem, vmProduct, err
vmIndex, err = eifo.VModelBuilder.new("index", "_Index")
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
return vmIndex