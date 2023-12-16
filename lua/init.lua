local log = ngx.log
log(ngx.INFO, "Initilizing EIFO...")
local conn = eifo.db.comm
local utils = eifo.utils
local view = eifo.view
local vmodel = eifo.VModelBuilder

local indexVModel = vmodel.new("index", "_Index")
local productVModel = indexVModel:rightJoin("Product", "_idx", "products")
local contentVModel = productVModel:rightJoin("ProductContent", "productId", "productContents")

eifo.home = view.new(nil, "index.view.html", indexVModel, 0)
