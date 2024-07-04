local log = ngx.log
local vmIndex, vmCategory, vmCatRollup, vmCatMem, err
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
return vmIndex
