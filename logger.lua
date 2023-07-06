--- getTime the time for all the function of this file
---@return string the time in DD/MM/YYYY HH:MM:SS
local function getTime()
    -- %d%m%Y -> DD/MM/YYYY => %d-%m-%Y
    -- %T => HH:MM:SS
    local s_time = os.date("%d-%m-%Y %T")
    return s_time
end

---
---@param msg string The msg to put into the log
---@param level string the level of the log (INFO, WARN, ERROR), DEBUG = INFO
local function write(msg, level)
    local str = string.format("\n%s %s: %s.", getTime(), level, msg)

    local handle = io.open("miner.log", "a")
    if handle then
        io.output(handle)
        io.write(str)
        handle.flush(handle)
        local has_been_closed, reason = io.close(handle)

        if not has_been_closed then
            error(string.format("failed to close the log file: %s", reason))
        end
        return has_been_closed
    end
    error("could not open the log file")
end

local logger = {}

--- Log a message into a file with the info level
---@param msg string the message to log with INFO level
function logger.log(msg)
    local level = "[INFO]"
    write(msg, level)
end

--- Log a message into a file with the warn level
---@param msg string the msg to log
function logger.warn(msg)
    local level = "[WARN]"
    write(msg, level)
end

--- Log a message into a file with the error level
---@param msg string the msg to log
function logger.error(msg)
    local level = "[ERROR]"
    write(msg, level)
end

--logger.log("test")
--logger.warn("this is a warning")
--logger.error("this is an error")

return logger

---@TODO log make a log per file or something