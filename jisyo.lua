-- jisyo.lua - SKK-JISYO (UTF-8) over CDB backend
-- API:
--   local jisyo = require("jisyo")
--   local dict = jisyo.open("SKK-JISYO.L.cdb")
--   dict:lookup(reading)
--   dict:lookup_okuri(key, okuri_kana)

local config = import("micro/config")
local plug_path = config.ConfigDir .. "/plug/?.lua"
if not package.path:find(plug_path, 1, true) then
	package.path = package.path .. ";" .. plug_path
end

local CDB = require("skk/cdb")

local M = {}

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function strip_note(cand)
	local body = cand:match("^([^;]+)")
	return body or cand
end

local function parse_skk_line(v)
	v = trim(v)
	local blocks = {}
	local body = v:gsub("%b[]", function(b)
		blocks[#blocks + 1] = b:sub(2, -2)
		return " "
	end)
	local defaults = {}
	for c in body:gmatch("/([^/]+)") do
		local t = strip_note(trim(c))
		if t ~= "" then
			defaults[#defaults + 1] = t
		end
	end
	return { defaults = defaults, blocks = {} }
end

local Dict = {}
Dict.__index = Dict

function M.open(cdb_path)
	local db, err = CDB.open(cdb_path)
	if not db then
		return nil, err
	end
	return setmetatable({ db = db }, Dict)
end

function Dict:close()
	if self.db then
		self.db:close()
		self.db = nil
	end
end

function Dict:lookup(reading)
	if not self.db then
		return {}
	end
	local line = self.db:get(reading)
	if not line then
		return {}
	end
	local e = parse_skk_line(trim(line))
	return e.defaults or {}
end

function Dict:lookup_okuri(key, okuri_kana)
	if not self.db then
		return {}
	end
	local line = self.db:get(key)
	if not line then
		return {}
	end
	local e = parse_skk_line(trim(line))
	if okuri_kana and e.blocks and e.blocks[okuri_kana] and #e.blocks[okuri_kana] > 0 then
		return e.blocks[okuri_kana]
	end
	return e.defaults or {}
end

return M
