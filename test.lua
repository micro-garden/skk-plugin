local micro = import("micro")
local config = import("micro/config")

local jisyo = require("jisyo")

local d = skk.load(config.ConfigDir .. "/SKK-JISYO.S")

local function run()
	local lines = {}

	for i, cand in ipairs(d:lookup("てん") or {}) do
		table.insert(lines, i .. " " .. cand)
	end

	for i, cand in ipairs(d:lookup_okuri("もt", "た") or {}) do
		table.insert(lines, i .. " " .. cand)
	end

	micro.TermMessage(table.concat(lines, "\n"))
end

-------------
-- Exports --
-------------

local M = {}

M.run = run

return M
