local index = eifo.db.ed["_Index"]:new({id = "index"})
assert(index, "Failed in initializing app: cannot insert default index record")
local conn = eifo.db.conn.redis()
conn:connect()
index:save(conn)
conn:disconnect()
ngx.say("OK")
