---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by tnguyen.
--- DateTime: 9/5/23 12:44 PM
---
--[[

-- 1. Read Request data:
function responseError(httpStatus, errMessage)
    ngx.status = httpStatus
    ngx.say("{'message':'" .. errMessage .. "'}")
    ngx.eof()
end
local reqargs = require "resty.reqargs"
local getData, postData, fileData = reqargs()
local reqData
if getData then
    reqData = getData
else
    reqData = postData
end

if not reqData then
    responseError(ngx.HTTP_NO_CONTENT, "Request data is missing")
    return
end

local idxName = reqData.indexName
reqData.indexName = nil
if not idxName then
    responseError(ngx.HTTP_BAD_REQUEST, "Index Name is expected with key 'indexName'")
    return
end
]]

-- Connect to Redis:
local redisAgent = require "resty.redis"
redisAgent.register_module_prefix("ft") -- Register module FT to create/search indexes
local redis = redisAgent:new()
redis:set_timeouts(1000, 1000, 1000) -- 1 sec
local ok, errConn = redis:connect("127.0.0.1", 6379)
if not ok then
    responseError(ngx.HTTP_INTERNAL_SERVER_ERROR, "failed to connect to Redis: " .. errConn)
    return
end

-- Check/create indexes:

local cjson = require "cjson"
local indexes = redis:ft():_list()
local cExist, pExist, promoExist
for k, v in pairs(indexes) do
    if(v == "idx:c") then
        ngx.say("Catalog index is already exists")
        cExist = true
    elseif v == "idx:p" then
        ngx.say("Product index is already exists")
        pExist = true
    elseif v == "idx:promo" then
        ngx.say("Promotion index is already exists")
        promoExist = true
    end
end
if not cExist then
    assert(redis:ft():create("idx:c", "ON", "HASH", "SCHEMA", "categoryName", "TEXT", "WEIGHT", "1.0", "description", "TEXT", "WEIGHT", "0.8"))
end
if not pExist then
    idxInfo = assert(redis:ft():create("idx:p", "ON", "HASH", "SCHEMA", "productName", "TEXT", "WEIGHT", "1.2", "description", "TEXT", "WEIGHT", "1.0"))
end
if not promoExist then
    idxInfo = assert(redis:ft():create("idx:promo", "ON", "HASH", "SCHEMA", "itemDescription", "TEXT", "WEIGHT", "1.0"))
end

ngx.status = ngx.HTTP_OK
ngx.eof()
redis:set_keepalive(10000, 50) -- maintain 50 connections in connection pool, with 10s timeout
