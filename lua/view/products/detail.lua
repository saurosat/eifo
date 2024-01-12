ngx.log(ngx.INFO, "Initilizing product detail's models....")
local vmProduct, vmAssocs, vmFeature, vmFeatureAppl, err

vmProduct, err = eifo.VModelBuilder.new("productDetail", "Product")
if not vmProduct then
    return error(err)
end

vmAssocs, err = vmProduct:rightJoin("ProductAssoc", "productId", "assocs")
if not vmAssocs then
    return error(err)
end
local vmProductTo
vmProductTo, err = vmAssocs:leftJoin("toProductId", "frAssocs")
if not vmProductTo then
    return error(err)
end

vmFeatureAppl, err = vmProduct:rightJoin("ProductFeatureAppl", "productId", "applFeatures")
if not vmFeatureAppl then
    return error(err)
end
vmFeature, err = vmFeatureAppl:leftJoin("productId", "productFeatureId", "applProducts")
if not vmFeature then
    return error(err)
end

ngx.log(ngx.INFO, "Product's models initialized.")

return vmProduct
