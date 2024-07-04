return {
    tableName = "ProductCategory",
    leftColumns = {},
    rightColumns = {"catMems"},
    skippedTables = {"ProductAssoc"}, -- not needed if rightColumns is empty
    toJsonColumns = {"products"},
    outputFile = false
}