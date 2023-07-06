local cli = {}

--- ask input to the user to know the facing direction
---@return number dir the facing pos as defined
function cli.load_facing_direction()
    -- north = -Z = 0
    -- west = -X = 1
    -- south = +Z = 2
    -- east = +X = 3
    local dir = nil
    repeat
        print("In which direction the turtle is facing ?\n[0]: North\n[1]: West\n[2]: South\n[3]: East")
        local input = string.lower(read())
        print("\n")

        dir = tonumber(input)

        if dir == nil then
            print(("Error: you must enter a valid number\n you typed '%s'"):format(input))
            dir = -1
        end
    until (dir >= 0 and dir <= 3) and type(dir) == "number"
    return dir
end

--- load the mining direction of the turtle
---@param facing_dir number the direction it will go forth
---@return number mining_dir the direction it will mine
function cli.load_mining_direction(facing_dir)
    -- north = -Z = 0
    -- west = -X = 1
    -- south = +Z = 2
    -- east = +X = 3
    local input = nil
    local mining_dir = nil
    repeat
        print("In which direction the turtle is going to mine ?\n")
        if (facing_dir % 2 == 0) then
            print("[1]: West\n[3]: East")
        else
            print("[0]: North\n[2]: South")
        end

        input = string.lower(read())
        print("\n")

        mining_dir = tonumber(input)

        if mining_dir == nil then
            print(("Error: you muste enter a valid number\nYou typed %s"):format(input))
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

--- ask for the user's input the X and Z of the starting point of the turtle
---@return number pos_x the X position of the turtle at the start
---@return number pos_z the Z position oft he turtle at the start
function cli.load_start_point()
    -- Ask for the x starting point of the turtle
    local pos_x = nil
    while type(pos_x) ~= "number" do
        print("X=")
        local input_x = string.lower(read())
        print("\n")

        pos_x = tonumber(input_x)
    end

    -- Ask for the Z starting point of the turtle
    local pos_z = nil
    while type(pos_z) ~= "number" do
        print("Z=")
        local input_z = string.lower(read())
        print("\n")

        pos_z = tonumber(input_z)
    end

    return pos_x, pos_z
end

function cli.askForFuel()
    repeat
        print("\nDid you put fuel in the first slot ? [Y/n]")
        local input = string.lower(read())
    until input == "y"
end

return cli
