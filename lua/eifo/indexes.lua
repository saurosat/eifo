local ngx = ngx
local utils = require "eifo.utils"
local indexes = utils.ArraySet:new()
function indexes:load(conn)
    if self.isLoaded then
        return
    end
    conn = conn or ngx.ctx.conn
    local shouldDisconnect = false
    if not conn then
        conn = eifo.db.conn.redis()
        conn:connect()
        shouldDisconnect = true
    end 

    local dbIndexes = conn:ftlist() or {}
    self:reset(dbIndexes)
    for _, tbl in pairs(eifo.db.table) do
        local indexName = "idx:"..tbl._prefix
        local indexFields = tbl.indexFields
        if indexFields and not self:index(indexName) then
            ngx.log(ngx.INFO, "Initializing index "..indexName)
            local params = {indexName, "ON", "HASH", "SCHEMA"}
            for key, value in pairs(indexFields) do
                params[#params+1] = key
                params[#params+1] = value
            end
            local res, err = conn:ftcreate(table.unpack(params))
            ngx.log(ngx.INFO, "FT.CREATE result: "..(res and utils.toString(res) or "nil")..", err: "..(err or "nil"))
            self:add(indexName)
        end
    end

    if shouldDisconnect then
        conn:disconnect()
    end

    self.isLoaded = true
end
function indexes:search(tbl, keywords, conn)
    if not tbl.indexFields then
        return nil, "No index fields defined for table "..tbl._name
    end
    local indexName = "idx:"..tbl._prefix
    return conn:ftsearch(indexName, table.unpack(keywords))
end