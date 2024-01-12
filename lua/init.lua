ngx.log(ngx.INFO, "Initilizing EIFO...")
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

local vmIndex = require "view.index"
local vmProduct = require "view.products.detail"
local vmProductIdx = require "view.products.index"

eifo.view.index = eifo.view.new(nil, "index.view.html", vmIndex, 0)
local vProduct = eifo.view.index:createSub("products", "products/detail.view.html", vmProduct, 1)
local vProductIdx = vProduct:createSub("index", "products/index.view.html", vmProductIdx, 0)
