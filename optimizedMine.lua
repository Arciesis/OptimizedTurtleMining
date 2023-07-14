-- globals

cpt_main_way = tonumber(0)

-- My own vector implementation
local Vec = {}

--- Create a new instance of Vec
---@field x number the X axis
---@field y number the y axis
---@field z number the z axis
function Vec.new(x, y, z)
    local self = {}
    self.x = x
    self.y = y
    self.z = z

    function self.toCCVec()
        return vector.new(x, y, z)
    end

    function self.getX()
        return x
    end

    function self.getY()
        return y
    end

    function self.getZ()
        return z
    end

    function self.addX()
        x = x + 1
    end

    function self.subX()
        x = x - 1
    end

    ---@public
    function self.addY()
        y = y + 1
    end

    ---@public
    function self.subY()
        y = y - 1
    end

    function self.addZ()
        z = z + 1
    end

    function self.subZ()
        z = z - 1
    end

    return self
end

-- Movement management related

local SMovementManagement = {}

local SPos_mt = { __index = SMovementManagement }

local instance

--- Singleton Pos management
---@param ori_pos Vec the original pos of the turtle
---@param heading_dir number the dir of the length
---@param mining_dir number the dir of the width
---@public
function SMovementManagement.new(ori_pos, heading_dir, mining_dir)
    if instance then
        return instance
    end

    local self = {}
    self.ORIGINAL_POS = ori_pos
    self.HEADING_DIR = heading_dir
    self.MINING_DIR = mining_dir
    self.dist_from_ori_pos = Vec.new(0, 0, 0)
    self.actual_heading = heading_dir
    local level = 0
    local is_mining = true

    ---@param move string the direction of the movement
    ---@private
    function self.updateDist(move)
        if self.actual_heading == 0 then
            if move == "forth" then
                self.dist_from_ori_pos.subZ()
            elseif move == "back" then
                self.dist_from_ori_pos.addZ()
            else
                error("updateDist")
            end
        elseif self.actual_heading == 1 then
            if move == "forth" then
                self.dist_from_ori_pos.subX()
            elseif move == "back" then
                self.dist_from_ori_pos.addX()
            else
                error("updateDist")
            end
        elseif self.actual_heading == 2 then
            if move == "forth" then
                self.dist_from_ori_pos.addZ()
            elseif move == "back" then
                self.dist_from_ori_pos.subZ()
            else
                error("updateDist")
            end
        elseif self.actual_heading == 3 then
            if move == "forth" then
                self.dist_from_ori_pos.addX()
            elseif move == "back" then
                self.dist_from_ori_pos.subX()
            else
                error("updateDist")
            end
        else
            error("updateDist")
        end
    end

    function self.left()
        turtle.turnLeft()
        self.actual_heading = ((self.actual_heading + 1) % 4)
    end

    function self.right()
        turtle.turnRight()
        self.actual_heading = ((self.actual_heading - 1) % 4)
    end

    ---move the turtle forward, gravel insensitive
    ---@public
    function self.moveForward()
        local moved
        repeat
            moved = turtle.forward()
            if not moved then
                turtle.dig()
            end
        until moved
        self.updateDist("forth")
    end

    ---move the turtle back, gravel insensitive
    ---@public
    function self.moveBackward()
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
        --self.dist_from_ori_pos.
        self.updateDist("back")
    end

    ---move the turtle up, gravel insensitive
    ---@public
    function self.moveUp()
        local moved
        repeat
            moved = turtle.up()
            if not moved then
                turtle.digUp()
            end
        until moved
        self.dist_from_ori_pos.addY()
    end

    ---move the turtle down, gravel insensitive
    ---@public
    function self.moveDown()
        local moved
        repeat
            moved = turtle.down()
            if not moved then
                turtle.digDown()
            end
        until moved
        self.dist_from_ori_pos.subY()
    end

    local function returnXHome()
        -- north = -Z = 0
        -- west = -X = 1
        -- south = +Z = 2
        -- east = +X = 3
        repeat
            local pos_x = self.dist_from_ori_pos.getX()
            if pos_x ~= 0 then
                self.moveBackward()
            end
        until pos_x == 0
    end

    ---@private
    local function returnYHome()
        repeat
            if self.dist_from_ori_pos.getY() < 0 then
                self.moveUp()
            elseif self.dist_from_ori_pos.getY() > 0 then
                -- is_full_home this case really necessary ?
                -- I think if I want to dig up in the future...
                self.moveDown()
            end
        until self.dist_from_ori_pos.getY() == 0
    end

    --- Return to the middle level of a mine
    local function returnToMiningLevel()
        local pos_y = math.abs(self.dist_from_ori_pos.getY())
        local has_to_move = ((pos_y % 4) ~= 0)
        local has_to_move_up, has_to_move_down

        if not has_to_move then
            return
        end

        if level == 0 then
            if pos_y == 0 then
                return
            end

            pos_y = self.dist_from_ori_pos.getY()
            if pos_y < 0 then
                repeat
                    self.moveUp()
                    pos_y = self.dist_from_ori_pos.getY()
                until pos_y == 0
                return
            end

            if pos_y > 0 then
                repeat
                    self.moveDown()
                    pos_y = self.dist_from_ori_pos.getY()
                until pos_y == 0
            end
        end

        has_to_move_up = ((level * 4) - pos_y) < 0
        has_to_move_down = ((level * 4) - pos_y) > 0
        if has_to_move_up then
            repeat
                self.moveUp()

                pos_y = math.abs(self.dist_from_ori_pos.getY())
                has_to_move_up = ((level * 4) - pos_y) < 0
            until has_to_move_up
            return
        end

        if has_to_move_down then
            repeat
                self.moveDown()

                pos_y = math.abs(self.dist_from_ori_pos.getY())
                has_to_move_down = ((level * 4) - pos_y) > 0
            until has_to_move_down
            return
        end
    end

    ---@private
    local function returnZHome()
        repeat
            local pos_z = self.dist_from_ori_pos.getZ()
            if pos_z ~= 0then
                self.moveBackward()
            end
        until pos_z ~= 0
    end

    --- return home, if is_full_home is true then it return to the start point otherwise
    ---it just return to the center
    ---@param is_full_home boolean whether it need to return to the start point
    function self.returnHome(is_full_home)
        returnToMiningLevel()

        if is_mining then
            -- north = -Z = 0
            -- west = -X = 1
            -- south = +Z = 2
            -- east = +X = 3
            if self.MINING_DIR == 0 or self.MINING_DIR == 2 then
                returnZHome()
                returnXHome()
            elseif self.MINING_DIR == 1 or self.MINING_DIR == 3 then
                returnXHome()
                returnZHome()
            else
                error("returnHome")
            end
            returnYHome()
            return
        end

        if self.HEADING_DIR == 0 or self.HEADING_DIR == 2 then
            returnZHome()
        elseif self.HEADING_DIR == 1 or self.HEADING_DIR == 3 then
            returnXHome()
        else
            error("returnHome")
        end

        if is_full_home then
            returnYHome()
        end
    end

    setmetatable(self, SPos_mt)
    instance = self
    return instance
end

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

--- refuel the turtle
local function refuelTurtle()
    for i = 1, 16 do
        turtle.select(i)
        turtle.refuel()
    end
    turtle.select(1)
end

--- first refuel of the turtle.
---Prompt
local function init_fuel()
    askForFuel()
    local level = turtle.getFuelLevel()
    if level == "unlimited" then
        error("Turtle does not need fuel")
    end

    refuelTurtle()
end

---refuel the turtle


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
        print("")

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

local function askForLength()
    local input
    local length

    repeat
        print("What length the turtle should mine ?\n")
        input = string.lower(read())

        length = tonumber(input)

        if length and length >= 0 then
            return length
        else
            print("Error: type a valid number (i.e: >= 0)")
            length = -1
        end
    until type(length) == "number" and length >= 0
end

local function askForWidth()
    local input, width
    repeat
        print("What width the turtle should mine ?\n")
        input = string.lower(read())

        width = tonumber(input)

        if width and width >= 0 then
            return width
        else
            print("Error: type a valid number (i.e: >= 0)")
            width = -1
        end
    until type(width) == "number" and width >= 0
end

--- ask for the user's input the X and Z of the starting point of the turtle
---@return number, number, number the original pos of the turtle (X, Y, Z)
local function askForStartPoint()
    -- Ask for the x starting point of the turtle
    local pos_x, input_x
    while type(pos_x) ~= "number" do
        print("X=")
        input_x = string.lower(read())
        print("")
        pos_x = tonumber(input_x)
    end
    -- Ask for the Z starting point of the turtle
    local pos_z, input_z
    while type(pos_z) ~= "number" do
        print("Z=")
        input_z = string.lower(read())
        print("")
        pos_z = tonumber(input_z)
    end

    local pos_y, input_y
    while type(pos_y) ~= "number" do
        print("Y=")
        input_y = string.lower(read())
        print("")
        pos_y = tonumber(input_y)
    end

    return pos_x, pos_y, pos_z
end

-- optimizedMine

---move the turtle forward, gravel insensitive
local function moveForward()

end

---move the turtle back, gravel insensitive
local function moveBackward()

end

---move the turtle up, gravel insensitive
local function moveUp()

end

---move the turtle down, gravel insensitive (event I don't see why gravel is a problem here)
local function moveDown()

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

--@TODO:updateDist modify to user the move functions instead
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
local function mineStraight(limit)
    local ores
    for _ = 1, limit, 1 do
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

    end

    refuelTurtle()
    makeSpace()

    for _ = 1, limit, 1 do
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
    cpt_main_way = cpt_main_way + 3
end

---
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

--- Tell whether the limit has been reached
---@return boolean whether the limit reached
local function isLimitReached(limit)
    if cpt_main_way < limit then
        return false
    else
        return true
    end
end

-- Instructions

init_fuel()

-- local posX, posZ = load_start_point()
local facing_dir = load_facing_direction()
local mining_dir = load_mining_direction(facing_dir)
local length = askForLength()
local width = askForWidth()
local ori_x, ori_y, ori_z = askForStartPoint()

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
local is_limit_reached = isLimitReached(length)
while has_available_slot and not is_limit_reached do
    if (facing_dir == 0 and mining_dir == 1) or (facing_dir == 1 and mining_dir == 2) or
            (facing_dir == 2 and mining_dir == 3) or (facing_dir == 3 and mining_dir == 0) then
        -- if the turtle needs to mine to its left at the beginning
        local side = "left"
        turtle.turnLeft()
        mineStraight(width)
        shift(side)

    elseif (facing_dir == 0 and mining_dir == 3) or (facing_dir == 1 and mining_dir == 0) or
            (facing_dir == 2 and mining_dir == 1) or (facing_dir == 3 and mining_dir == 2) then
        -- if the turtle needs to mine to its right at the beginning
        local side = "right"
        turtle.turnRight()
        mineStraight(width)
        shift(side)
    end

    has_available_slot = hasAvailableSlot()
    is_limit_reached = isLimitReached(length)
end

--- need to return home
for _ = cpt_main_way, 1, -1 do
    moveBackward()
end