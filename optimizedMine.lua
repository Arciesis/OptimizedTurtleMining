-- inventory

--- Tell whether there are slot left in the inventory of the turtle
--- assume the inventory has been sorted before the call of that function
---@return boolean whether there is available slot in the inventory of the turtle
local function hasAvailableSlot()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return true
        end
    end
    return false
end

--- make space in the inventory by dropping the unnecessary items
local function makeSpace()
    for i = 1, 16, 1 do
        local detail = turtle.getItemDetail(i, true)
        if detail ~= nil then
            if not (detail.tags and (detail.tags["forge:ores"] or detail.tags["forge:raw_materials"]
                    or detail.tags["minecraft:coals"] or detail.tags["forge:gems"]
                    or detail.tags["forge:ingots"] or detail.tags["forge:dusts/redstone"]
                    or detail.tags["forge:storage_blocks/coal"]
                    or detail.tags["forge:storage_blocks/charcoal"])) then
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

--- place a stack of ore/gems/redstone/coal et in the first slot possible
---iterate 16 * 16 times so it takes time
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
---iterate 16 * 16 times so it takes time
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

--- sortInventory the inventory by stacking items together if possible
local function sortInventory()
    local has_available_slot = hasAvailableSlot()
    if not has_available_slot then
        stackItems()
        sortStacks()
        turtle.select(1)
    end
end

-- fuel

--- prompt the user to remind their to refuel the turtle before it start
local function askForFuel()
    repeat
        print("\nDid you put fuel in the first slot ? [Y/n]")
        local input = string.lower(read())
    until input == "y"
end

--- first refuel of the turtle.
---Prompt
local function init_fuel()
    askForFuel()
    local level = turtle.getFuelLevel()
    if level == "unlimited" then
        error("Turtle does not need n")
    end

    if level % 80 == 0 or turtle.getFuelLevel == 0 then
        local ok, err = turtle.refuel()
        if not ok then
            printError(err)
        end
    end
end

---refuel the turtle
local function refuelTurtle()
    local level = turtle.getFuelLevel()
    if level <= 400 then
        local ok, err = turtle.refuel()

        if not ok then
            printError(err)
        end
    end
end

-- cli

---ask input to the user to know the facing direction
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

    -- backward pathfinding, its deleted the last entry of the table
    if not has_ore then
        reverse_side = table.remove(ore_path)
        if reverse_side then
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
        end

        -- forward ore finding, it insert the direction one the table
        -- 1: front
        -- 2: right
        -- 3: back
        -- 4: left
        -- 5: down
        -- 6: up
    elseif has_ore_side then
        if side then
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
        end
    elseif has_ore_down then

        turtle.digDown()
        turtle.down()
        table.insert(ore_path, 5)
    elseif has_ore_up then
        turtle.digUp()
        turtle.up()
        table.insert(ore_path, 6)
    end

    if ((not has_ore) and (#ore_path == 0)) then
        return
    else
        orePathFinder(ore_path)
    end
end

--- mine straight for 64 blocks and then come backward
local function mineStraight()
    local ores
    for _ = 1, 65, 1 do
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
        local side = "left"
        turtle.turnLeft()
        mineStraight()
        shift(side)

    elseif (facing_dir == 0 and mining_dir == 3) or (facing_dir == 1 and mining_dir == 0) or
            (facing_dir == 2 and mining_dir == 1) or (facing_dir == 3 and mining_dir == 2) then
        -- if the turtle needs to mine to its right at the beginning
        local side = "right"
        turtle.turnRight()
        mineStraight()
        shift(side)
    end
    has_available_slot = hasAvailableSlot()
end