local connFactory = eifo.db.conn
local utils = eifo.utils
local conn, errMsg = connFactory.redis()
if not conn then
    ngx.log(ngx.CRIT, "Failed to get DB connection "..errMsg)
    return
end
local ok, error = conn:connect()
if ok then
    local enumEvs = utils.newTable(0, 163)
    enumEvs[#enumEvs+1] = {description="Accessory", enumId="PftAccessory", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Amount", enumId="PftAmount", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Net Weight", enumId="PftNetWeight", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Artist", enumId="PftArtist", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Billing", enumId="PftBilling", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Brand", enumId="PftBrand", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Care", enumId="PftCare", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Color", enumId="PftColor", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Dimension", enumId="PftDimension", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Equipment Class", enumId="PftEquipClass", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Fabric", enumId="PftFabric", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Genre", enumId="PftGenre", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Hardware", enumId="PftHardware", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="License", enumId="PftLicense", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Origin", enumId="PftOrigin", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Other", enumId="PftOther", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Packaging Component", enumId="PftPackagingComponent", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Packaging Type", enumId="PftPackagingType", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Product Quality", enumId="PftProdQuality", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Size", enumId="PftSize", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Software", enumId="PftSoftware", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Style", enumId="PftStyle", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Symptom", enumId="PftSymptom", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Topic", enumId="PftTopic", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Type", enumId="PftType", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Warranty", enumId="PftWarranty", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Model Year", enumId="PftModelYear", enumTypeId="ProductFeatureType"}
    enumEvs[#enumEvs+1] = {description="Year Made", enumId="PftYearMade", enumTypeId="ProductFeatureType"}

    enumEvs[#enumEvs+1] = {description="Asset (Good)", enumId="PtAsset", enumTypeId="ProductType"}
    enumEvs[#enumEvs+1] = {description="Digital and Asset", enumId="PtDigitalAsset", enumTypeId="ProductType"}
    enumEvs[#enumEvs+1] = {description="Digital (download)", enumId="PtDigital", enumTypeId="ProductType"}
    enumEvs[#enumEvs+1] = {description="Asset Use", enumId="PtAssetUse", enumTypeId="ProductType"}
    enumEvs[#enumEvs+1] = {description="Facility Use", enumId="PtFacilityUse", enumTypeId="ProductType"}
    enumEvs[#enumEvs+1] = {description="Service", enumId="PtService", enumTypeId="ProductType"}
    enumEvs[#enumEvs+1] = {description="Virtual (with variants)", enumId="PtVirtual", enumTypeId="ProductType"}
    enumEvs[#enumEvs+1] = {description="Pick Assembly", enumId="PtPickAssembly", enumTypeId="ProductType"}
    enumEvs[#enumEvs+1] = {description="Configurable Good", enumId="PtConfigurable", enumTypeId="ProductType"}

    enumEvs[#enumEvs+1] = {description="Gift Card or Certificate", enumId="PclsGiftCard", enumTypeId="ProductClass"}

    enumEvs[#enumEvs+1] = {description="Up-Sell (Upgrade)", enumId="PatUpsell", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Down-Sell (Downgrade)", enumId="PatDownSell", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="New Version, Replacement", enumId="PatReplacement", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Equivalent or Substitute", enumId="PatEquivalent", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Accessory", enumId="PatAccessory", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Add On For", enumId="PatAddOn", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Repair Service", enumId="PatRepairService", enumTypeId="ProductAssocType"}

    enumEvs[#enumEvs+1] = {description="Cross-Sell (Complementary)", enumId="PatCrossSell", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Also Bought", enumId="PatAlsoBought", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Alternative Packaging", enumId="PatAlternativePkg", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Refurbished Equivalent", enumId="PatRefurbished", enumTypeId="ProductAssocType"}

    enumEvs[#enumEvs+1] = {description="Product Variant", enumId="PatVariant", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Requires", enumId="PatRequires", enumTypeId="ProductAssocType"}

    enumEvs[#enumEvs+1] = {description="Incompatible", enumId="PatIncompatible", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Unique Item", enumId="PatUniqueItem", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Auto Reorder (needs recurrenceInfoId)", enumId="PatAutoReorder", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Revision", enumId="PatRevision", enumTypeId="ProductAssocType"}

    enumEvs[#enumEvs+1] = {description="Manufacturing Bill of Materials", parentEnumId="PatComponent", enumId="PatMfgBom", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Engineering Bill of Materials", parentEnumId="PatComponent", enumId="PatEngBom", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Product Manufactured As", enumId="PatMfgAs", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Used to Produce", enumId="PatUsedToProduce", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Configurable Product Instance", enumId="PatConfigInstance", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Actual Product Component", enumId="PatComponent", enumTypeId="ProductAssocType"}
    enumEvs[#enumEvs+1] = {description="Packaging For", enumId="PatPackagingFor", enumTypeId="ProductAssocType"}

    enumEvs[#enumEvs+1] = {description="Product Name", enumId="PcntProductName", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Description", enumId="PcntDescription", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Description - Long", enumId="PcntDescriptionLong", enumTypeId="ProductContentType"}

    enumEvs[#enumEvs+1] = {description="Delivery Info", enumId="PcntDeliveryInfo", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Digital Download", enumId="PcntDownload", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Directions", enumId="PcntDirections", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Fulfillment Email", enumId="PcntEmail", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Frequently Asked Questions", enumId="PcntFAQ", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Ingredients", enumId="PcntIngredients", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Ingredients - Unique", enumId="PcntUniqueIngred", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Installation", enumId="PcntInstallation", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Label Image", enumId="PcntLabelImage", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Label Text", enumId="PcntLabelText", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Online Access", enumId="PcntOnline", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Price Detail Text", enumId="PcntPriceDetail", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Short Sales Pitch", enumId="PcntShortSalesPitch", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Special Instructions", enumId="PcntSpecialInstr", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Specification", enumId="PcntSpecification", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Terms and Conditions", enumId="PcntTermsConditions", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Testimonials", enumId="PcntTestimonials", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Warnings", enumId="PcntWarnings", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Warranty", enumId="PcntWarranty", enumTypeId="ProductContentType"}

    enumEvs[#enumEvs+1] = {description="Image - Small", enumId="PcntImageSmall", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Image - Medium", enumId="PcntImageMedium", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Image - Large", enumId="PcntImageLarge", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Image - Detail", enumId="PcntImageDetail", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Image - Original", enumId="PcntImageOriginal", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Image URL - Small", enumId="PcntImageUrlSmall", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Image URL - Medium", enumId="PcntImageUrlMedium", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Image URL - Large", enumId="PcntImageUrlLarge", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Image URL - Detail", enumId="PcntImageUrlDetail", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Image URL - Original", enumId="PcntImageUrlOriginal", enumTypeId="ProductContentType"}

    enumEvs[#enumEvs+1] = {description="Add To Cart Label", enumId="PcntAddToCartLabel", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Add To Cart Image", enumId="PcntAddToCartImage", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Meta-Keywords", enumId="PcntMetaKeywords", enumTypeId="ProductContentType"}
    enumEvs[#enumEvs+1] = {description="Meta-Description", enumId="PcntMetaDescription", enumTypeId="ProductContentType"}

    enumEvs[#enumEvs+1] = {description="Sales Required Info", enumId="PfmtSalesRequired", enumTypeId="ProductFormType"}
    enumEvs[#enumEvs+1] = {description="Sales Optional Info", enumId="PfmtSalesOptional", enumTypeId="ProductFormType"}
    enumEvs[#enumEvs+1] = {description="Post Sale Survey", enumId="PfmtPostSaleSurvey", enumTypeId="ProductFormType"}

    enumEvs[#enumEvs+1] = {description="Purchase Include", enumId="PgpPurchaseInclude", enumTypeId="ProductGeoPurpose"}
    enumEvs[#enumEvs+1] = {description="Purchase Exclude", enumId="PgpPurchaseExclude", enumTypeId="ProductGeoPurpose"}
    enumEvs[#enumEvs+1] = {description="Shipment Include", enumId="PgpShipmentInclude", enumTypeId="ProductGeoPurpose"}
    enumEvs[#enumEvs+1] = {description="Shipment Exclude", enumId="PgpShipmentExclude", enumTypeId="ProductGeoPurpose"}

    enumEvs[#enumEvs+1] = {description="ISBN", enumId="PidtIsbn", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="Mfg Model Number", enumId="PidtMfgModelNum", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="Other", enumId="PidtOther", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="SKU", enumId="PidtSku", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="UPC-A", enumId="PidtUpca", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="UPC-E", enumId="PidtUpce", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="EAN", enumId="PidtEan", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="GTIN", enumId="PidtGtin", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="Library of Congress", enumId="PidtLoc", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="URL Slug", enumId="PidtUrlSlug", enumTypeId="ProductIdentificationType"}
    enumEvs[#enumEvs+1] = {description="HTS (Tariff)", enumId="PidtHts", enumTypeId="ProductIdentificationType"}

    enumEvs[#enumEvs+1] = {description="List Price", enumId="PptList", enumTypeId="ProductPriceType"}
    enumEvs[#enumEvs+1] = {description="Current Price", enumId="PptCurrent", enumTypeId="ProductPriceType"}
    enumEvs[#enumEvs+1] = {description="Average Cost", enumId="PptAverage", enumTypeId="ProductPriceType"}
    enumEvs[#enumEvs+1] = {description="Minimum Price", enumId="PptMinimum", enumTypeId="ProductPriceType"}
    enumEvs[#enumEvs+1] = {description="Maximum Price", enumId="PptMaximum", enumTypeId="ProductPriceType"}
    enumEvs[#enumEvs+1] = {description="Promotional Price", enumId="PptPromotional", enumTypeId="ProductPriceType"}
    enumEvs[#enumEvs+1] = {description="Competitive Price", enumId="PptCompetitive", enumTypeId="ProductPriceType"}
    enumEvs[#enumEvs+1] = {description="Wholesale Price", enumId="PptWholesale", enumTypeId="ProductPriceType"}
    enumEvs[#enumEvs+1] = {description="Special Promo Price", enumId="PptSpecialPromo", enumTypeId="ProductPriceType"}

    enumEvs[#enumEvs+1] = {description="Purchase/Initial", enumId="PppPurchase", enumTypeId="ProductPricePurpose"}
    enumEvs[#enumEvs+1] = {description="Recurring Charge", enumId="PppRecurring", enumTypeId="ProductPricePurpose"}
    enumEvs[#enumEvs+1] = {description="Usage Charge", enumId="PppUsage", enumTypeId="ProductPricePurpose"}
    enumEvs[#enumEvs+1] = {description="Component Price", enumId="PppComponent", enumTypeId="ProductPricePurpose"}

    enumEvs[#enumEvs+1] = {enumId="SpoMain", sequenceNum="1", description="Main Supplier", enumTypeId="SupplierPreferredOrder"}
    enumEvs[#enumEvs+1] = {enumId="SpoAlternate", sequenceNum="2", description="Alternate Supplier", enumTypeId="SupplierPreferredOrder"}

    enumEvs[#enumEvs+1] = {description="Product Price Modify", enumId="ProductPriceModify", enumTypeId="ServiceRegisterType"}

    enumEvs[#enumEvs+1] = {description="Catalog", enumId="PctCatalog", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Industry", enumId="PctIndustry", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Internal", enumId="PctInternal", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Materials", enumId="PctMaterials", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Quick Add", enumId="PctQuickAdd", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Search", enumId="PctSearch", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Usage", enumId="PctUsage", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Mix and Match", enumId="PctMixMatch", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Cross Sell", enumId="PctCrossSell", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Tax", enumId="PctTax", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Gift Card", enumId="PctGiftCard", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Best Selling", enumId="PctBestSelling", enumTypeId="ProductCategoryType"}
    enumEvs[#enumEvs+1] = {description="Inventory Group", enumId="PctInventoryGroup", enumTypeId="ProductCategoryType"}

    enumEvs[#enumEvs+1] = {description="Category Name", enumId="PcctCategoryName", enumTypeId="ProductCategoryContentType"}
    enumEvs[#enumEvs+1] = {description="Description", enumId="PcctDescription", enumTypeId="ProductCategoryContentType"}
    enumEvs[#enumEvs+1] = {description="Description - Long", enumId="PcctDescriptionLong", enumTypeId="ProductCategoryContentType"}
    enumEvs[#enumEvs+1] = {description="Category Image URL", enumId="PcctImageUrl", enumTypeId="ProductCategoryContentType"}
    enumEvs[#enumEvs+1] = {description="Category Image Alt Text", enumId="PcctImageAltText", enumTypeId="ProductCategoryContentType"}
    enumEvs[#enumEvs+1] = {description="Footer", enumId="PcctFooter", enumTypeId="ProductCategoryContentType"}
    enumEvs[#enumEvs+1] = {description="Meta-Keywords", enumId="PcctMetaKeywords", enumTypeId="ProductCategoryContentType"}
    enumEvs[#enumEvs+1] = {description="Meta-Description", enumId="PcctMetaDescription", enumTypeId="ProductCategoryContentType"}

    enumEvs[#enumEvs+1] = {description="URL Slug", enumId="PcitUrlSlug", enumTypeId="ProductCategoryIdentType"}

    enumEvs[#enumEvs+1] = {description="Standard", enumId="PfatStandard", enumTypeId="ProductFeatureApplType"}
    enumEvs[#enumEvs+1] = {description="Selectable", enumId="PfatSelectable", enumTypeId="ProductFeatureApplType"}
    enumEvs[#enumEvs+1] = {description="Distinguishing", enumId="PfatDistinguishing", enumTypeId="ProductFeatureApplType"}
    enumEvs[#enumEvs+1] = {description="Optional", enumId="PfatOptional", enumTypeId="ProductFeatureApplType"}

    enumEvs[#enumEvs+1] = {description="Dependency", enumId="PfitDependency", enumTypeId="ProductFeatureIactnType"}
    enumEvs[#enumEvs+1] = {description="Compatible", enumId="PfitCompatible", enumTypeId="ProductFeatureIactnType"}
    enumEvs[#enumEvs+1] = {description="Incompatible", enumId="PfitIncompatible", enumTypeId="ProductFeatureIactnType"}
    enumEvs[#enumEvs+1] = {description="Composition", enumId="PfitComposition", enumTypeId="ProductFeatureIactnType"}

    enumEvs[#enumEvs+1] = {description="Product", enumId="StProduct", enumTypeId="SubscriptionType"}

    local tbl = eifo.db.table["Enumeration"]:new({leftColumns = {}, rightColumns = {}})
    for i = 1, #enumEvs, 1 do
        local record = tbl:newRecord(enumEvs[i])
        local _, _, err = record:persist(conn)
        if err then
            ngx.print(record:toJson()..":"..err)
        end
    end
    conn:disconnect()
else
    ngx.print("Cannot get connection: "..(error or "unknown error"))
end
ngx.eof()
