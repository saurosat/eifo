if fileName == "_NA_" then -- get image file names
    fileName = nil
    local productKey = eifo.db.table.Product:generateKey({pkValue = pseudoId}) -- pseudoId in this case is actually productId
    local conn = ngx.ctx.conn
    local shouldDisconnect = false
    if not conn then
        conn = eifo.db.conn.redis()
        if not conn then
            responseError(ngx.HTTP_INTERNAL_SERVER_ERROR, "Got some problems! We will fix it soon. Please come back later")
            return
        end
        conn:connect()
        shouldDisconnect = true
    end
    local tblAssoc = eifo.db.table.ProductAssoc:new({conn = conn})
    local assocs = tblAssoc:loadByFk("toProductId", productKey, conn)
    if not assocs or #assocs == 0 then
        ngx.log(ngx.INFO, "Product assocs of "..productKey.." is not found")
        responseError(ngx.HTTP_NOT_FOUND, "Product assocs of "..productKey.." is not found", shouldDisconnect and conn or nil)
        return
    end
    local assoc = nil
    for i = #assocs, 1, -1 do
        if assocs[i].productAssocTypeEnumId == "e.PatVariant" then
            assoc = assocs[i]
            break
        end
    end
    if not assoc then
        ngx.log(ngx.INFO, "PatVariant assoc of "..productKey.." is not found")
        responseError(ngx.HTTP_NOT_FOUND, "Product assocs of "..productKey.." is not found", shouldDisconnect and conn or nil)
        return
    end
    pseudoId = assoc.product.pseudoId
    local featureMap = assoc.toProduct.distinguishFeatures
    local sFeatures = ""
    for _, feature in pairs(featureMap) do
        if feature.noImageDiff ~= 'Y' then
            sFeatures = sFeatures..feature.abbrev.."_"
        end
    end
    if sFeatures ~= "" then
        sFeatures = sFeatures:sub(1, -2) -- remove last "_"
    end
    local imgNames = store:getProductImageFileNames(pseudoId.."."..sFeatures)
    if #imgNames == 0 then
        responseError(ngx.HTTP_NOT_FOUND, "Product ID  "..productKey.." has no images", shouldDisconnect and conn or nil)
        return
    end
    if shouldDisconnect then
        conn:disconnect()
    end

    local destUrl = nil
    for i = #imgNames, 1, -1 do -- search for image fileName and destUrl:
        local fr, to = imgNames[i]:find("^[^%.]+%.")
        if fr == 1 and to > 1 then
            local namePart = imgNames[i]:sub(fr, to - 1)
            local iFr, iTo = imgNames[i]:find("%d%d%d?%d?[xX]%d%d%d?%d?")
            local fSize = iFr and imgNames[i]:sub(iFr, iTo) or nil
            ngx.log(ngx.DEBUG, "fSize = "..(fSize or "nil")..", size = "..size)
            if fSize == size then
                destUrl = imgNames[i]
                break
            end
            if fSize == nil then
                srcFile = imgNames[i]
                fileName = namePart
            end
        end
    end
    if destUrl ~= nil then
        destUrl = "/"..pseudoId.."/"..destUrl
        ngx.log(ngx.DEBUG, "Redirecting to "..destUrl)
        ngx.exec(destUrl)
        return
    end
    if fileName == nil or srcFile == nil then
        ngx.log(ngx.INFO, "Not found any image for product "..pseudoId)
        responseError(ngx.HTTP_NOT_FOUND, "Not found any image for product "..pseudoId)
        return
    end
    local sessionToken = store:getSessionToken()
    if sig ~= sessionToken then
        ngx.log(ngx.INFO, "Invalid token: "..sig..", expected token: "..sessionToken)
        responseError(ngx.HTTP_FORBIDDEN, "Invalid token "..sig)
        return
    end
    sig = nil
    local fr, to = srcFile:find("%.%a+$")
    if fr then
        ext = srcFile:sub(fr + 1, to)
    end
end