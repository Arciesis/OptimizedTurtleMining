local logger = require "logger"
local inventory = {}


function inventory.makeSpace()
    for i = 1, 16, 1 do
        local detail = turtle.getItemDetail(i, true)
        if detail ~= nil then
            -- print(textutils.serialise(detailed_data))
            if not (detail.tags and (detail.tags["forge:ores"] or detail.tags["forge:raw_materials"] or detail.tags["minecraft:coals"]
                    or detail.tags["forge:gems"] or detail.tags["forge:ingots"])) then
                turtle.select(i)
                turtle.drop()
            end
        end
    end
    turtle.select(1)
end

function inventory.hasAvailableSlot()
    for i = 1, 16, 1 do
        if turtle.getItemCount(i) == 0 then
            logger.log("there is space in the inventory")
            return true
        end
    end
    return false
end

function inventory.hasTrashable()
    for i = 1, 16, 1 do
        if turtle.getItemCount(i) ~= 0 then
            local detailed_data = turtle.getItemDetail(i, true)

            if not (detailed_data.tags and (detailed_data.tags["forge:ores"] or detailed_data.tags["forge:raw_materials"] or detailed_data.tags["minecraft:coals"]
                    or detailed_data.tags["forge:gems"] or detailed_data.tags["forge:ingots"])) then
                logger.log("There is trash-able in the inventory")
                return true
            end
        end
    end
    return false
end

local function test()
    local data = turtle.getItemDetail(1, true)
    print(textutils.serialise(data))
end
-- test()

return inventory
