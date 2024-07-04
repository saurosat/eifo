ngx.log(ngx.INFO, "Loading eifo.db...")
local utils = require "eifo.utils"
local tables = {
    {
        name = "Enumeration",
        prefix = "e",
        fnIds = {"enumId"}, --ID field names
        fnFKs = {} -- {enumTypeId = "EnumerationType"} -- Foreign key field names
    },
    {
        name = "ProductStore",
        prefix = "store",
        fnIds = {"productStoreId"},
        fnFKs = {}
    },
    {
        name = "ProductCategory",
        prefix = "pc",
        fnIds = {"productCategoryId"}, --ID field names
        fnFKs = {productStoreId = {"ProductStore", "categories"}, productCategoryTypeEnumId = {"Enumeration", "categories"}} -- Foreign key field names
    },
    {
        name = "Product",
        prefix = "p",
        fnIds = { "productId" },
        fnFKs = {productStoreId = {"ProductStore", "products"}, productTypeEnumId = {"Enumeration", "productsByPType"}, productClassEnumId={"Enumeration", "productsByPClass"}, assetTypeEnumId = {"Enumeration", "productsByAType"}, assetClassEnumId = {"Enumeration", "productsByAClass"}}
    },
    {
        name = "ProductContent",
        prefix = "pcnt",
        fnIds = {"productContentId"},
        fnFKs = {productId = {"Product", "contents"}, productContentTypeEnumId={"Enumeration", "productContents"}}
    },
    {
        name = "ProductAssoc",
        prefix = "pa",
        fnIds = {"productId", "toProductId", "productAssocTypeEnumId", "fromDate"},
        fnFKs = {productId = {"Product", "assocs"}, toProductId = {"Product", "fromAssocs"}, productAssocTypeEnumId = {"Enumeration", "assocs"}}
    },
    {
        name = "ProductFeature",
        prefix = "pf",
        fnIds = {"productFeatureId"},
        fnFKs = {productFeatureTypeEnumId = {"Enumeration", "features"}}
    },
    {
        name = "ProductFeatureAppl",
        prefix = "pfa",
        fnIds = {"productId", "productFeatureId", "fromDate"},
        fnFKs = {applTypeEnumId = {"Enumeration", "featureAppls"}, productId = {"Product", "featureAppls"}, productFeatureId = {"ProductFeature", "featureAppls"}}
    },
    {
        name = "ProductCategoryRollup",
        prefix = "pcr",
        fnIds = {"productCategoryId", "parentProductCategoryId"},
        fnFKs = {productCategoryId = {"ProductCategory", "rollups"}, parentProductCategoryId = {"ProductCategory", "childRollups"}}
    },
    {
        name = "ProductCategoryMember",
        prefix = "pcm",
        fnIds = {"productCategoryId", "productId", "fromDate"},
        fnFKs = {productCategoryId = {"ProductCategory", "catMems"}, productId = {"Product", "catMems"}}
    },
    {
        name = "ProductStoreCategory",
        prefix = "psc",
        fnIds = {"productStoreId", "productCategoryId", "storeCategoryTypeEnumId"},
        fnFKs = {productStoreId = {"ProductStore", "storeCategories"}, productCategoryId = {"ProductCategory", "storeCategories"}, storeCategoryTypeEnumId = {"Enumeration", "storeCategories"}}
    },
    {
        name = "ProductStoreProduct",
        prefix = "psp",
        fnIds = {"productStoreId", "productId"},
        fnFKs = {productStoreId = {"ProductStore", "storeProducts"}, productId = {"Product", "productStores"}, signatureRequiredEnumId = {"Enumeration", "storeProducts"}}
    },
    {
        name = "ProductStorePromotion",
        prefix = "psm",
        fnIds = {"storePromotionId"},
        fnFKs = {productStoreId = {"ProductStore", "promotions"}}
    },
    {
        name = "ProductStorePromoProduct",
        prefix = "pspp",
        fnIds = {"storePromotionId", "productId"},
        fnFKs = {storePromotionId = {"ProductStorePromotion", "promoProducts"}, productId = {"Product", "productPromotions"}}
    },
    {
        name = "ProductReview",
        prefix = "pr",
        fnIds = {"productReviewId"},
        fnFKs = {productId = {"Product", "reviews"}}
    }
}

local Table = require "eifo.db.table.Table"
local tbls = {}
for i = 1, #tables, 1 do
    local tbl = Table:new(tables[i])
    tbls[tbl._name] = tbl
    --ngx.log(ngx.DEBUG, tables[i].name.." --- "..tbl._name)
end
for i = 1, #tables, 1 do
    tbls[tables[i].name]:init(tbls)
end
for i = 1, #tables, 1 do
    ngx.log(ngx.DEBUG, "Table "..tables[i].name..", rightCols "..utils.toJson(tbls[tables[i].name]._rightCols))
end
ngx.log(ngx.DEBUG, utils.toJson(utils.keys(tbls["ProductStore"]._rightTables)))
return tbls