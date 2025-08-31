-- jisyo.lua - SKK-JISYO-E v1 over CDB backend
-- API:
--   local jisyo = require("jisyo")
--   local dict = jisyo.open("SKK-JISYO.L.cdb") -- in SKK-JISYO-E v1
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

local function utf8_encode(cp)
	if cp <= 0x7f then
		return string.char(cp)
	elseif cp <= 0x7ff then
		return string.char(0xc0 + math.floor(cp / 0x40), 0x80 + (cp % 0x40))
	elseif cp <= 0xffff then
		return string.char(0xe0 + math.floor(cp / 0x1000), 0x80 + (math.floor(cp / 0x40) % 0x40), 0x80 + (cp % 0x40))
	elseif cp <= 0x10ffff then
		return string.char(
			0xf0 + math.floor(cp / 0x40000),
			0x80 + (math.floor(cp / 0x1000) % 0x40),
			0x80 + (math.floor(cp / 0x40) % 0x40),
			0x80 + (cp % 0x40)
		)
	end
	return ""
end

-- \\ \/ \; \[ \] \n \t \" \' \u{...}
local function unescape_e(s)
	local out, i, len = {}, 1, #s
	while i <= len do
		local c = s:sub(i, i)
		if c ~= "\\" then
			out[#out + 1] = c
			i = i + 1
		else
			if i == len then
				out[#out + 1] = "\\"
				i = i + 1
			else
				local n = s:sub(i + 1, i + 1)
				if n == "\\" or n == "/" or n == ";" or n == "[" or n == "]" or n == "'" or n == '"' then
					out[#out + 1] = n
					i = i + 2
				elseif n == "n" then
					out[#out + 1] = "\n"
					i = i + 2
				elseif n == "t" then
					out[#out + 1] = "\t"
					i = i + 2
				elseif n == "u" then
					if s:sub(i + 2, i + 2) == "{" then
						local j = i + 3
						local k = s:find("}", j, true)
						if k then
							local hex = s:sub(j, k - 1)
							local cp = tonumber(hex, 16)
							if cp then
								out[#out + 1] = utf8_encode(cp)
							else
								out[#out + 1] = "\\u{" .. hex .. "}"
							end
							i = k + 1
						else
							out[#out + 1] = "\\u{"
							i = i + 3
						end
					else
						out[#out + 1] = "u"
						i = i + 2
					end
				else
					-- undefined
					out[#out + 1] = n
					i = i + 2
				end
			end
		end
	end
	return table.concat(out)
end

local function split_semicolon(s)
	local fields, buf, i, len, esc = {}, {}, 1, #s, false
	while i <= len do
		local ch = s:sub(i, i)
		if esc then
			buf[#buf + 1] = ch
			esc = false
		elseif ch == "\\" then
			buf[#buf + 1] = ch
			esc = true
		elseif ch == ";" then
			fields[#fields + 1] = table.concat(buf)
			buf = {}
		else
			buf[#buf + 1] = ch
		end
		i = i + 1
	end
	fields[#fields + 1] = table.concat(buf)
	return fields
end

local function first_unescaped_slash(s)
	local i, len, esc = 1, #s, false
	while i <= len do
		local ch = s:sub(i, i)
		if esc then
			esc = false
		elseif ch == "\\" then
			esc = true
		elseif ch == "/" then
			return i
		end
		i = i + 1
	end
	return nil
end

-- Returen value: { defaults={surface...}, blocks={ [okuri]= {surface...} } }
local function parse_e_body(line)
	if not line or line == "" then
		return { defaults = {}, blocks = {} }
	end
	line = trim(line)

	local defaults_raw = {}
	local blocks_raw = {}
	local buf = {}
	local in_br = false
	local br_buf = {}
	local esc = false

	local function flush_default()
		if #buf > 0 then
			local s = trim(table.concat(buf))
			if s ~= "" then
				defaults_raw[#defaults_raw + 1] = s
			end
			buf = {}
		end
	end

	local i, len = 1, #line
	while i <= len do
		local ch = line:sub(i, i)
		if esc then
			if in_br then
				br_buf[#br_buf + 1] = ch
			else
				buf[#buf + 1] = ch
			end
			esc = false
		elseif ch == "\\" then
			if in_br then
				br_buf[#br_buf + 1] = ch
			else
				buf[#buf + 1] = ch
			end
			esc = true
		elseif in_br then
			if ch == "]" then
				blocks_raw[#blocks_raw + 1] = table.concat(br_buf)
				br_buf = {}
				in_br = false
			else
				br_buf[#br_buf + 1] = ch
			end
		else
			if ch == "[" then
				in_br = true
				br_buf = {}
			elseif ch == "/" then
				flush_default()
			else
				buf[#buf + 1] = ch
			end
		end
		i = i + 1
	end
	flush_default()

	local defaults = {}
	for _, rawc in ipairs(defaults_raw) do
		local segs = split_semicolon(rawc)
		local surf = unescape_e(trim(segs[1] or ""))
		if surf ~= "" then
			defaults[#defaults + 1] = surf
		end
	end

	local blocks = {}
	for _, br in ipairs(blocks_raw) do
		br = trim(br)
		local pos = first_unescaped_slash(br)
		if pos then
			local okuri = trim(br:sub(1, pos - 1))
			local rest = br:sub(pos + 1)

			local toks, bbuf, j, blen, esc2 = {}, {}, 1, #rest, false
			while j <= blen do
				local ch2 = rest:sub(j, j)
				if esc2 then
					bbuf[#bbuf + 1] = ch2
					esc2 = false
				elseif ch2 == "\\" then
					bbuf[#bbuf + 1] = ch2
					esc2 = true
				elseif ch2 == "/" then
					local s = trim(table.concat(bbuf))
					if s ~= "" then
						toks[#toks + 1] = s
					end
					bbuf = {}
				else
					bbuf[#bbuf + 1] = ch2
				end
				j = j + 1
			end
			local last = trim(table.concat(bbuf))
			if last ~= "" then
				toks[#toks + 1] = last
			end

			if okuri ~= "" and #toks > 0 then
				local arr = {}
				for _, rawc in ipairs(toks) do
					local segs = split_semicolon(rawc)
					local surf = unescape_e(trim(segs[1] or ""))
					if surf ~= "" then
						arr[#arr + 1] = surf
					end
				end
				if #arr > 0 then
					blocks[okuri] = arr
				end
			end
		end
	end

	return { defaults = defaults, blocks = blocks }
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
	local body = self.db:get(reading)
	if not body then
		return {}
	end
	local e = parse_e_body(body)
	return e.defaults or {}
end

function Dict:lookup_okuri(key, okuri_kana)
	if not self.db then
		return {}
	end
	local body = self.db:get(key)
	if not body then
		return {}
	end
	local e = parse_e_body(body)
	if okuri_kana and e.blocks and e.blocks[okuri_kana] and #e.blocks[okuri_kana] > 0 then
		return e.blocks[okuri_kana]
	end
	return e.defaults or {}
end

return M
