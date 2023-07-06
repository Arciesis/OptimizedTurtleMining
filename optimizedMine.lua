-- module related
local cli = require "cli"
local inventory = require "inventory"
local fuel = require "fuel"
local logger = require "logger"

-- Functions

local function moveForward()
    local moved = turtle.forward()
    if not moved then
        logger.error("returning home, the turtle could not moved")
        ---@TODO need to implement this
        -- return_home()
        error()
    end
end

local function moveBackward()
    local moved = turtle.backward()
    if not moved then
        logger.error("returning home, the turtle could not moved")
        -- return_home()
        error()
    end
end

--- Inspect the block in front of the turtle
---@return boolean  whether there is a block or not
local function inspectBlock(side)
    -- select the method to suck up
    local has_block, has_solid_block, data = nil, nil, nil
    if side == "front" then
        has_block, data = turtle.inspect()
        has_solid_block = turtle.detect()
    elseif side == "up" then
        has_block, data = turtle.inspectUp()
        has_solid_block = turtle.detectUp()
    elseif side == "down" then
        has_block, data = turtle.inspectDown()
        has_solid_block = turtle.detectDown()
    else
        error("It should not happened, its commonly known as a bug")
    end

    -- tell the turtle whether it need to suck the block or not
    if has_solid_block then
        if has_block then
            if data.tags and (data.tags["forge:ores"] or data.tags["forge:gems"] or
                    data.tags["forge:coals"] or data.tags["forge:raw_materials"] or
                    data.tags['forge:ingots']) then
                -- need to suck
                logger.log("there is ore/coal/ingots/raw_materials in front of me")
                return true
            else
                logger.log("that's trash, don't suck")
                return true
            end
        else
            logger.log("that's trash, don't suck")
            return false
        end
        logger.log("that's trash, don't suck")
        return true
    else
        logger.log("that's trash, don't suck")
        return false
    end
end

---suck the item in front of the turtle
---@deprecated Not useful since the turtle suck the block automatically when digging
---@param side string the side which the turtle needs to suck, could be "front", "up" or "down"
---@return boolean has_been_picked_up whether the item has been sucked up
local function suckBlock(side)
    local has_been_picked_up, reason = nil, nil

    if side == "front" then
        has_been_picked_up, reason = turtle.suck()

        if has_been_picked_up then
            logger.log("an item has been sucked ")
        else
            logger.warn(string.format("no item has been sucked: ", reason))
        end
    elseif side == "up" then
        has_been_picked_up, reason = turtle.suckUp()

        if has_been_picked_up then
            logger.log("an item has been sucked ")
        else
            logger.warn(string.format("no item has been sucked: ", reason))
        end
    elseif side == "down" then
        has_been_picked_up, reason = turtle.suckDown()

        if has_been_picked_up then
            logger.log("an item has been sucked ")
        else
            logger.warn(string.format("no item has been sucked: ", reason))
        end
    end

    if not has_been_picked_up then
        logger.error("Error: the block has not been picked up: ", reason)
    end
    return has_been_picked_up
end

--- Do one of the three step of the mining phase (dig (and suck))
---@param side string the side which must be compute (front, up, down)
local function miningStep(side)
    local has_solid_block = true
    repeat
        local has_block = inspectBlock(side)
        logger.log(string.format("there is a block: ", tostring(has_block)))
        if has_block then
            if side == "front" then
                local has_dug, reason = turtle.dig()
                logger.log(string.format("turtle has mined front: ", tostring(has_dug)))
                if not has_dug then
                    logger.error(string.format("turtle has not dug: %s"), reason)
                    error(string.format("turtle has not dug: %s", reason))
                end

                sleep(0.5)
                has_solid_block = turtle.detect()
                logger.log(string.format("solid block front: ", has_solid_block))

            elseif side == "up" then
                local has_dug, reason = turtle.digUp()

                logger.log(string.format("turtle has mined up: ", tostring(has_dug)))
                if not has_dug then
                    error(string.format("turtle has not dug: %s", reason))
                end

                sleep(0.5)
                has_solid_block = turtle.detectUp()
                logger.log(string.format(string.format("has block up: ", has_solid_block)))

            elseif side == "down" then
                local has_dug, reason = turtle.digDown()

                logger.log(string.format("turtle has mined down: ", tostring(has_dug)))
                if not has_dug then
                    logger.error(string.format("turtle has not dug: %s", reason))
                    error(string.format("turtle has not dug: %s", reason))
                end

                sleep(0.5)
                has_solid_block = turtle.detectDown()
                logger.log(string.format("has block down: ", has_solid_block))

            end
        else
            if side == "front" then
                has_solid_block = turtle.detect()
            elseif side == "up" then
                has_solid_block = turtle.detectUp()
            elseif side == "down" then
                has_solid_block = turtle.detectDown()
            end
        end
        logger.log(string.format("there is solid block: ", tostring(has_solid_block)))
    until not has_solid_block
end

--- mine straight for 64 blocks and then come backward
local function mineStraight()
    for i = 1, 65, 1 do
        -- do the front step
        miningStep("front")

        -- do the up step
        miningStep("up")

        -- do the final step: the down one
        miningStep("down")

        if not inventory.hasAvailableSlot then
            inventory.makeSpace()
        end

        fuel.refuelTurtle()
        ---@TODO implement that feature
        local fuel_level = turtle.getFuelLevel()
        if fuel_level < travel_dist then
            -- return home
            break
        end
    end

    for i = 1, 65, 1 do
       moveBackward()
    end

    inventory.makeSpace()
end

local function mine3BlocksStraight()
    for i = 1, 3 do
        turtle.dig()
        moveForward()
        turtle.digUp()
        turtle.digDown()
    end
end

local function shift(side)
    if side == "left" then
        turtle.turnRight()
        mine3BlocksStraight()
    elseif side == "right" then
        turtle.turnLeft()
        mine3BlocksStraight()
    else
        logger.error("Should not happened")
    end
end


-- Instructions

fuel.init_fuel()

local posX, posZ = cli.load_start_point()
local facing_dir = cli.load_facing_direction()
local mining_dir = cli.load_mining_direction(facing_dir)

-- start)
-- north = -Z = 0
-- west = -X = 1
-- south = +Z = 2
-- east = +X = 3


-- all the mine left moves:
-- (facing_dir == 0 and mining_dir == 1)
-- (facing_dir == 1 and mining_dir == 2)
-- (facing_dir == 2 and mining_dir == 3)
-- (facing_dir == 3 and mining_dir == 0)

-- all the mine right moves
-- (facing_dir == 0 and mining_dir == 3)
-- (facing_dir == 1 and mining_dir == 0)
-- (facing_dir == 2 and mining_dir == 1)
-- (facing_dir == 3 and mining_dir == 2)
local fuel_level = turtle.getFuelLevel()
while fuel_level > 0 do
    if (facing_dir == 0 and mining_dir == 1) or (facing_dir == 1 and mining_dir == 2) or
            (facing_dir == 2 and mining_dir == 3) or (facing_dir == 3 and mining_dir == 0) then
        -- if the turtle needs to mine to its left at the beginning
        logger.warn("New entry on the mine")
        local side = "left"
        turtle.turnLeft()
        mineStraight()
        shift(side)

    elseif (facing_dir == 0 and mining_dir == 3) or (facing_dir == 1 and mining_dir == 0) or
            (facing_dir == 2 and mining_dir == 1) or (facing_dir == 3 and mining_dir == 2) then
        -- if the turtle needs to mine to its right at the beginning
        logger.warn("New entry on the mine")
        local side = "right"
        turtle.turnRight()
        mineStraight()
        shift(side)
    end
    fuel_level = turtle.getFuelLevel()
end