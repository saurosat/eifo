local lock = {}
function lock:unlock()
    return self.conn and self.conn:del(self.key) or ngx.shared.lock:delete(self.key)
end

return function(key, conn)
    if not key then
        return lock
    end
    local success
    if conn then
        key = "lock:"..key --.."@"..os.time()
        success = conn:setnx(key, "locked") > 0
    else
        success = ngx.shared.lock:add(key, "locked", 1000) -- expired in 1 second
    end
    return success and setmetatable({key = key, conn = conn}, {__index = lock}) or nil
end
