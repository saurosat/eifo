return {
    tableName = "Enumeration",
    leftColumns = {},
    rightColumns = {"categories"},
    skippedTables = {"ProductAssoc"}, -- not needed if rightColumns is empty
    outputFile = false,
    -- toJson = function (self, record)
    --     local tbl = model._rightTables["ProductCategory"]
    --     tbl.toJsonColumns = {"products"}
    --     return tbl:toJson()
    -- end
}