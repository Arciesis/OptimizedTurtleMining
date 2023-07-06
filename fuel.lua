local cli = require "cli"
local logger = require "logger"

local fuel = {}

-- coal is 80 unit fuel

function fuel.init_fuel()
    cli.askForFuel()
    local level = turtle.getFuelLevel()
    if level == "unlimited" then error("Turtle does not need fuel\n", 0) end

    if level % 80 == 0 or turtle.getFuelLevel == 0 then
        local ok, err = turtle.refuel()
        if ok then
            local new_level = turtle.getFuelLevel()
            logger.log(("Refuelled %d, current level is %d\n"):format(new_level - level, new_level))
        else
            printError(err)
        end
    end
end

function fuel.refuelTurtle()
    local fuel_level = turtle.getFuelLevel()
    if fuel_level < 160 then
        local ok, err = turtle.refuel()

        if ok then
            local new_level = turtle.getFuelLevel()
            logger.log(("Refuelled %d, current level is %d\n"):format(new_level - fuel_level, new_level))
        else
            printError(err)
        end
    end
end

return fuel
