local ok, async = pcall(require, "nio")
if not ok then async = require("neotest.async") end
local logger = require("neotest.logging")

local M = {}
local separator = ":"

--- Replace paths in a string
---@param str string
---@param what string
---@param with string
---@return string
local function replace_paths(str, what, with)
    -- Taken from: https://stackoverflow.com/a/29379912/3250992
    what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") -- escape pattern
    with = string.gsub(with, "[%%]", "%%%%")                       -- escape replacement
    return string.gsub(str, what, with)
end

---@param position neotest.Position The position to return an ID for
---@param namespace neotest.Position[] Any namespaces the position is within
---@return string
M.generate_treesitter_id = function(position)
    local cwd = async.fn.getcwd()
    local test_path = "." .. replace_paths(position.path, cwd, "")
    -- Treesitter starts line numbers from 0 so we subtract 1
    local id = test_path .. separator .. (tonumber(position.range[1]) + 1)

    logger.debug("Cwd:", { cwd })
    logger.debug("Path to test file:", { position.path })
    logger.debug("Treesitter id:", { id })

    return id
end
