local micro = import("micro")
local time = import("time")

local TICK_DURATION = time.ParseDuration("0ms")

local function after(duration, fn)
	-- micro.After requires micro v2.0.14-rc1
	if type(micro.After) == "function" then
		micro.After(duration, fn)
	elseif
		-- time.AfterFunc requires micro before v2.0.14-rc1
		type(time.AfterFunc) == "function"
	then
		time.AfterFunc(duration, fn)
	else
		micro.TermMessage("** skk environment error **\ncannot find After* method")
	end
end

local function next_tick(fn, n)
	if not n or n < 2 then
		after(TICK_DURATION, fn)
	else
		next_tick(fn, n - 1)
	end
end

-------------
-- Exports --
-------------

local M = {}

M.after = after
M.next_tick = next_tick

return M
