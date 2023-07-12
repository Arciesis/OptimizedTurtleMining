-- Functions

-- logger

----- getTime the time for all the function of this file
-----@return string the time in DD/MM/YYYY HH:MM:SS
--local function getTime()
--    -- %d%m%Y -> DD/MM/YYYY => %d-%m-%Y
--    -- %T => HH:MM:SS
--    local date = os.date("%d-%m-%Y %T")
--    local s_date
--    if type(date) ~= "string" then
--        -- meaning its a table
--        error("that should never happened but luanalysis ask me to")
--    else
--        s_date = date
--    end
--    return s_date
--end

-----
-----@param msg string The msg to put into the log
-----@param level string the level of the log (INFO, WARN, ERROR), DEBUG = INFO
--local function write(msg, level)
--    --@TODO if file exists then remove it to not use too much space on the server
--    local str = string.format("\n%s %s: %s.", getTime(), level, msg)
--
--    local handle = io.open("miner.log", "a")
--    if handle then
--        io.output(handle)
--        io.write(str)
--        handle.flush(handle)
--        local has_been_closed = io.close(handle)
--
--        if not has_been_closed then
--            error(string.format("failed to close the log file"))
--        end
--        return has_been_closed
--    end
--    error("could not open the log file")
--end

----- Log a message into a file with the info level
-----@param msg string the message to log with INFO level
--local function log(msg)
--    local level = "[INFO]"
--    write(msg, level)
--end
--
----- Log a message into a file with the warn level
-----@param msg string the msg to log
--local function warn(msg)
--    local level = "[WARN]"
--    write(msg, level)
--end
--
----- Log a message into a file with the error level
-----@param msg string the msg to log
--local function error(msg)
--    local level = "[ERROR]"
--    write(msg, level)
--end
-----@TODO log make a log per file or something

-- inventory

--- Tell whether there are slot left in the inventory of the turtle
--- assume the inventory has been sorted before the call of that function
local function hasAvailableSlot()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            --log("there is space in the inventory")
            return true
        end
    end
    return false
end

local function hasTrashable()
    for i = 1, 16, 1 do
        if turtle.getItemCount(i) ~= 0 then
            local detailed_data = turtle.getItemDetail(i, true)

            if not (detailed_data.tags and (detailed_data.tags["forge:ores"] or
                    detailed_data.tags["forge:raw_materials"] or
                    detailed_data.tags["minecraft:coals"] or
                    detailed_data.tags["forge:gems"] or
                    detailed_data.tags["forge:ingots"] or
                    detailed_data.tags["forge:dusts/redstone"])) then
                --log("There is trash-able in the")
                return true
            end
        end
    end
    return false
end

local function makeSpace()
    for i = 1, 16, 1 do
        local detail = turtle.getItemDetail(i, true)
        if detail ~= nil then
            -- print(textutils.serialise(detailed_data))
            if not (detail.tags and (detail.tags["forge:ores"] or detail.tags["forge:raw_materials"]
                    or detail.tags["minecraft:coals"] or detail.tags["forge:gems"]
                    or detail.tags["forge:ingots"] or detail.tags["forge:dusts/redstone"])) then
                turtle.select(i)
                turtle.drop()
            end
        end
    end
    turtle.select(1)
end

--- tell whether the slot is already taken or not
---@param slot number the number of the slot
local function isSlotTaken(slot)
    turtle.select(slot)
    local itemCount = turtle.getItemCount()
    if itemCount >= 0 then
        return false
    else
        return true
    end
end

--- place a stack of ore/gems/redstone et in the first slot possible
local function sortStacks()
    for i = 1, 16 do
        for j = 1, 16 do
            turtle.select(j)
            local is_slot_taken = isSlotTaken(i)
            if not is_slot_taken then
                turtle.transferTo(i)
            end
        end
    end
end

---stack the item together if possible
local function stackItems()
    for i = 1, 16 do
        for j = 1, 16 do
            turtle.select(j)
            local isEqual = turtle.compareTo(i)
            if isEqual then
                local nbrToTransfer = turtle.getItemCount(j)
                local firstSlotSpaceLeft = turtle.getItemSpace(i)
                if ((firstSlotSpaceLeft - nbrToTransfer) <= 64) then
                    turtle.transferTo(i, nbrToTransfer)
                else
                    turtle.transferTo(i, firstSlotSpaceLeft)
                end
            end

        end
    end
end

local function sortInventory()
    local has_available_slot = hasAvailableSlot()
    if not has_available_slot then
        stackItems()
        sortStacks()
        turtle.select(1)
    end
end

-- fuel

local function askForFuel()
    repeat
        print("\nDid you put fuel in the first slot ? [Y/n]")
        local input = string.lower(read())
    until input == "y"
end

local function init_fuel()
    askForFuel()
    local level = turtle.getFuelLevel()
    if level == "unlimited" then
        error("Turtle does not need n")
    end

    if level % 80 == 0 or turtle.getFuelLevel == 0 then
        local ok, err = turtle.refuel()
        if ok then
            local new_level = turtle.getFuelLevel()
            --log(("Reed %d, current level is %d\n"):format(new_level - level, new_level))
        else
            printError(err)
        end
    end
end

local function refuelTurtle()
    local level = turtle.getFuelLevel()
    if level < 160 then
        local ok, err = turtle.refuel()

        if ok then
            local new_level = turtle.getFuelLevel()
            --log(("Reed %d, current level is %d\n"):format(new_level - level, new_level))
        else
            printError(err)
        end
    end
end

-- cli

--- ask input to the user to know the facing direction
---@return number dir the facing pos as defined
local function load_facing_direction()
    -- north = -Z = 0
    -- west = -X = 1
    -- south = +Z = 2
    -- east = +X = 3
    local dir
    repeat
        print("In which direction the turtle is facing ?\n[0]: North\n[1]: West\n[2]: South\n[3]: East")
        local input = string.lower(read())
        print("\n")

        dir = tonumber(input)

        if not dir then
            print(("Error: you must enter a valid number\n you typed '%s'"):format(input))
            dir = -1
        end
    until (dir >= 0 and dir <= 3) and type(dir) == "number"
    return dir
end

--- load the mining direction of the turtle
---@param facing_dir number the direction it will go forth
---@return number mining_dir the direction it will mine
local function load_mining_direction(facing_dir)
    -- north = -Z = 0
    -- west = -X = 1
    -- south = +Z = 2
    -- east = +X = 3
    local input
    local mining_dir
    repeat
        print("In which direction the turtle is going to mine ?\n")
        if (facing_dir % 2 == 0) then
            print("[1]: West\n[3]: East")
        else
            print("[0]: North\n[2]: South")
        end

        input = string.lower(read())
        print("")

        mining_dir = tonumber(input)

        if not mining_dir then
            print(("Error: you must enter a valid number\nYou typed %s"):format(input))
            print("")
            mining_dir = -1
        end

        -- check if the values are correct e.g: not opposite one from another
        if ((facing_dir % 2 == 0) and (mining_dir == 0 or mining_dir == 2)) or ((facing_dir % 2 == 1) and (mining_dir == 1 or mining_dir == 3)) then
            print(("Error: check the choices !\n"))
            mining_dir = -1
        end
    until (mining_dir >= 0 and mining_dir <= 3) and type(mining_dir) == "number"

    return mining_dir
end

----- ask for the user's input the X and Z of the starting point of the turtle
-----@return number pos_x the X position of the turtle at the start
-----@return number pos_z the Z position oft he turtle at the start
-----@deprecated Should not be used unless a wireless system is integrated even then it's not useful
--local function load_start_point()
--    -- Ask for the x starting point of the turtle
--    local pos_x
--    while type(pos_x) ~= "number" do
--        print("X=")
--        local input_x = string.lower(read())
--        print("\n")
--
--        pos_x = tonumber(input_x)
--    end
--
--    -- Ask for the Z starting point of the turtle
--    local pos_z
--    while type(pos_z) ~= "number" do
--        print("Z=")
--        local input_z = string.lower(read())
--        print("\n")
--
--        pos_z = tonumber(input_z)
--    end
--
--    return pos_x, pos_z
--end

-- optimizedMine

---move the turtle forward, gravel insensitive
local function moveForward()
    repeat
        local moved = turtle.forward()
        if not moved then
            turtle.dig()
        end
    until moved
end

---move the turtle back, gravel insensitive
local function moveBackward()
    local moved
    repeat
        moved = turtle.back()
        if not moved then
            turtle.turnRight()
            turtle.turnRight()
            turtle.dig()
            turtle.turnRight()
        end
    until moved

end

---move the turtle up, gravel insensitive
local function moveUp()
    local moved
    repeat
        moved = turtle.up()
        if not moved then
            turtle.digUp()
        end
    until moved
end

---move the turtle down, gravel insensitive (event I don't see why gravel is a problem here)
local function moveDown()
    local moved
    repeat
        moved = turtle.down()
        if not moved then
            turtle.digDown()
        end
    until moved
end


--- inspect each sides  of the turtle to find ores i.e:
---
---1= front
---
---2= right
---
---3= back
---
---4:= left
---@return boolean, number whether there is ore and the side which it found it
local function detectOreEachSide()
    for i = 1, 4 do
        local has_block, data = turtle.inspect()
        if has_block then
            if data and data.tags and (data.tags["forge:ores"] or
                    data.tags["forge:raw_materials"] or
                    data.tags["minecraft:coals"] or
                    data.tags["forge:gems"] or
                    data.tags["forge:ingots"] or
                    data.tags["forge:dusts/redstone"])
            then
                ---@TODO make the turtle turn until it found its original facing
                for _ = i - 1, 1, -1 do
                    turtle.turnLeft()
                end
                return true, i
            end
        end
        turtle.turnRight()
    end
    return false, 0
end

--- detect whether there is or on the up side
---@return boolean whether there is ore
local function detectOreUp()
    local has_block, data = turtle.inspectUp()
    if has_block then
        if data and data.tags and (data.tags["forge:ores"] or
                data.tags["forge:raw_materials"] or
                data.tags["minecraft:coals"] or
                data.tags["forge:gems"] or
                data.tags["forge:ingots"] or
                data.tags["forge:dusts/redstone"])
        then
            return true
        else
            return false
        end
    else
        return false
    end
end

--- detect whether there is or on the down side
---@return boolean whether there is ore
local function detectOreDown()
    local has_block, data = turtle.inspectDown()
    if has_block then
        if data and data.tags and (data.tags["forge:ores"] or
                data.tags["forge:raw_materials"] or
                data.tags["minecraft:coals"] or
                data.tags["forge:gems"] or
                data.tags["forge:ingots"] or
                data.tags["forge:dusts/redstone"])
        then
            return true
        else
            return false
        end
    else
        return false
    end
end

--- A recursive function that dig all the ores and go back with the exact same path
---@param ore_path table the path of the ores
local function orePathFinder(ore_path)
    local has_ore_side, side = detectOreEachSide()
    local has_ore_up = detectOreUp()
    local has_ore_down = detectOreDown()
    local has_ore = has_ore_side or has_ore_up or has_ore_down
    local reverse_side

    --print(has_ore)
    -- backward ore finding
    if not has_ore then
        reverse_side = table.remove(ore_path)
        if reverse_side then
            --print(string.format("removed side: %d", reverse_side))

            -- 1: front => back
            -- 2: right => left
            -- 3: back => front
            -- 4: left => right
            -- 5: down => up
            -- 6: up => down
            if reverse_side == 1 then
                turtle.back()
            elseif reverse_side == 2 then
                turtle.back()
                turtle.turnLeft()
            elseif reverse_side == 3 then
                turtle.back()
                turtle.turnLeft()
                turtle.turnLeft()
            elseif reverse_side == 4 then
                turtle.back()
                turtle.turnRight()
            elseif reverse_side == 5 then
                turtle.up()
            elseif reverse_side == 6 then
                turtle.down()
            end
            --orePathFinder(ore_path)
        end

        --print(has_ore_side)
        -- forward ore finding, its returning insert the same heading facing_dir after each move
        -- 1: front
        -- 2: right
        -- 3: back
        -- 4: left
        -- 5: down
        -- 6: up
        ---@TODO: make it gravel protected
    elseif has_ore_side then
        if side then
            --print(string.format("inserted side: %d", side))
            if side == 1 then
                turtle.dig()
                moveForward()
                table.insert(ore_path, side)
            elseif side == 2 then
                turtle.turnRight()
                turtle.dig()
                moveForward()
                table.insert(ore_path, side)
            elseif side == 3 then
                turtle.turnRight()
                turtle.turnRight()
                turtle.dig()
                moveForward()
                table.insert(ore_path, side)
            elseif side == 4 then
                turtle.turnLeft()
                turtle.dig()
                moveForward()
                table.insert(ore_path, side)
            end
            --orePathFinder(ore_path)
        end
    elseif has_ore_down then
        --print("inserted side: 5")

        turtle.digDown()
        turtle.down()
        table.insert(ore_path, 5)
        --orePathFinder(ore_path)
    elseif has_ore_up then
        --print("inserted side: 6")
        turtle.digUp()
        turtle.up()
        table.insert(ore_path, 6)
        --orePathFinder(ore_path)
    end

    if ((not has_ore) and (#ore_path == 0)) then
        return
    else
        orePathFinder(ore_path)
    end
end

----- Inspect the block in front of the turtle
-----@return boolean  whether there is a block or not
--local function detectBlock(side)
--    -- select the method to suck up
--    local has_solid_block
--    if side == "front" then
--        has_solid_block = turtle.detect()
--    elseif side == "up" then
--        has_solid_block = turtle.detectUp()
--    elseif side == "down" then
--        has_solid_block = turtle.detectDown()
--    else
--        error("It should not happened, its commonly known as a bug")
--    end
--    return has_solid_block
--
--    -- tell the turtle whether it need to suck the block or not
--    --if has_solid_block then
--    --    if has_block then
--    --        if data.tags and (data.tags["forge:ores"] or data.tags["forge:gems"] or
--    --                data.tags["forge:coals"] or data.tags["forge:raw_materials"] or
--    --                data.tags['forge:ingots']) then
--    --            -- need to suck
--    --            log("there is ore/coal/ingots/raw_materials in front of me")
--    --            return true
--    --        end
--    --    else
--    --        log("that's trash, don't suck")
--    --        return true
--    --    end
--    --    log("that's trash, don't suck")
--    --    return true
--    --else
--    --    log("that's trash, don't suck")
--    --    return false
--    --end
--end

-----suck the item in front of the turtle
-----@deprecated Not useful since the turtle suck the block automatically when digging
-----@param side string the side which the turtle needs to suck, could be "front", "up" or "down"
-----@return boolean has_been_picked_up whether the item has been sucked up
--local function suckBlock(side)
--    local has_been_picked_up, reason = nil, nil
--
--    if side == "front" then
--        has_been_picked_up, reason = turtle.suck()
--
--        if has_been_picked_up then
--            --log("an item has been sucked ")
--        else
--            --warn(string.format("no item has been sucked: ", reason))
--        end
--    elseif side == "up" then
--        has_been_picked_up, reason = turtle.suckUp()
--
--        if has_been_picked_up then
--            --log("an item has been sucked ")
--        else
--            --warn(string.format("no item has been sucked: ", reason))
--        end
--    elseif side == "down" then
--        has_been_picked_up, reason = turtle.suckDown()
--
--        if has_been_picked_up then
--            --log("an item has been sucked ")
--        else
--            --warn(string.format("no item has been sucked: ", reason))
--        end
--    end
--
--    if not has_been_picked_up then
--        error(string.format("Error: the block has not been picked up: %s", reason))
--    end
--    return has_been_picked_up
--end

--- mine straight for 64 blocks and then come backward
local function mineStraight()
    local ores
    for _ = 1, 65, 1 do
        --miningStep("front")
        ores = {}
        orePathFinder(ores)
        moveForward()

        -- do the up step
        moveUp()
        ores = {}
        orePathFinder(ores)
        moveDown()

        -- do the final step: the down one
        moveDown()
        ores = {}
        orePathFinder(ores)
        moveUp()

        if not hasAvailableSlot then
            makeSpace()
        end

        refuelTurtle()
        ---@TODO implement that feature
        --local fuel_level = turtle.getFuelLevel()
        --if fuel_level < travel_dist then
        --    -- return home
        --    break
        --end
    end

    makeSpace()

    for _ = 1, 65, 1 do
        moveBackward()
    end

    sortInventory()
end

local function mine3BlocksStraight()
    for _ = 1, 3 do
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
        error("Should not happened")
    end
end


-- Instructions

init_fuel()

-- local posX, posZ = load_start_point()
local facing_dir = load_facing_direction()
local mining_dir = load_mining_direction(facing_dir)

-- start
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
--local fuel_level = turtle.getFuelLevel()
local has_available_slot = hasAvailableSlot()
refuelTurtle()
while has_available_slot do
    if (facing_dir == 0 and mining_dir == 1) or (facing_dir == 1 and mining_dir == 2) or
            (facing_dir == 2 and mining_dir == 3) or (facing_dir == 3 and mining_dir == 0) then
        -- if the turtle needs to mine to its left at the beginning
        --warn("New entry on the mine")
        local side = "left"
        turtle.turnLeft()
        mineStraight()
        shift(side)

    elseif (facing_dir == 0 and mining_dir == 3) or (facing_dir == 1 and mining_dir == 0) or
            (facing_dir == 2 and mining_dir == 1) or (facing_dir == 3 and mining_dir == 2) then
        -- if the turtle needs to mine to its right at the beginning
        --warn("New entry on the mine")
        local side = "right"
        turtle.turnRight()
        mineStraight()
        shift(side)
    end
    has_available_slot = hasAvailableSlot()
end