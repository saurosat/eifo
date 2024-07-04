ngx.log(ngx.INFO, "Initilizing products index model....")
local vmIndex, vmProduct, err
vmIndex, err = eifo.VModelBuilder.new("allProducts", "_Index")
if not vmIndex then
    return error(err)
end

vmProduct, err = vmIndex:rightJoin("Product", "_idx", "products")
if not vmProduct then
    return error(err)
end

ngx.log(ngx.INFO, "Product's index model initialized.")

return vmIndex

---
--- http://gleecy.io/products/DEMO__2
--- step 1: go to location /api
--- step 2: go to view location: "/" params: {products, DEMO__2} eifo.view.index:process()
--- step 3: check sub-view --> subview name products, matched with first param: --> go to sub-view
--- step 4: sub view products: {DEMO__2}: check sub view --> vProduct
--- step 5: call process: vProduct:process(DEMO__002)