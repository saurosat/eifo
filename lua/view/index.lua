local utils = require "eifo.utils"

return {
    tableName = "ProductStore",
    key = "store.p56586a9f100000",
    layout = "/layout/master",
    outputFile = false,
    createPageContext = function (self, context)
        local store = assert(context.record, "record is nil: "..utils.toJson(context))
        local promotions = store.promotions
        local promoProducts = utils.ArraySet:new()
        for i = 1, #promotions, 1 do 
            local promoPrds = promotions[i].promoProducts
            for j = 1, #promoPrds, 1 do 
                promoProducts:add(promoPrds[i])
            end
        end
        context.promoProducts = promoProducts
        return context
    end
}