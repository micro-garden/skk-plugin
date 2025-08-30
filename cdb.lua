-- cdb.lua - tiny pure-Lua CDB reader for Lua 5.1 (read-only)
-- Format: djb CDB (https://cr.yp.to/cdb.html)

local CDB = {}
CDB.__index = CDB

local U32 = 4294967296 -- 2^32

local function u32_wrap(x)
	x = x % U32
	if x < 0 then
		x = x + U32
	end
	return x
end

local function bxor(a, b)
	local res, p = 0, 1
	while a > 0 or b > 0 do
		local abit = a % 2
		local bbit = b % 2
		if abit ~= bbit then
			res = res + p
		end
		a = math.floor(a / 2)
		b = math.floor(b / 2)
		p = p * 2
	end
	return res
end

local function rshift(x, n)
	if n <= 0 then
		return x
	end
	return math.floor(x / (2 ^ n))
end

local function u32le(s)
	local b1, b2, b3, b4 = s:byte(1, 4)
	return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local function read_at(f, pos, n)
	f:seek("set", pos)
	return f:read(n)
end

-- djbhash: h = ((h<<5) + h) ^ c, initial: 5381
local function cdb_hash(key)
	local h = 5381
	for i = 1, #key do
		h = u32_wrap(h * 33)
		h = bxor(h, key:byte(i))
	end
	return h
end

function CDB.open(path)
	local f, err = io.open(path, "rb")
	if not f then
		return nil, err
	end
	local self = setmetatable({ f = f, toc = {} }, CDB)

	local hdr = f:read(2048)
	if not hdr or #hdr < 2048 then
		f:close()
		return nil, "bad cdb header"
	end
	for i = 0, 255 do
		local off = i * 8
		local pos = u32le(hdr:sub(off + 1, off + 4))
		local len = u32le(hdr:sub(off + 5, off + 8))
		self.toc[i] = { pos = pos, nslots = len }
	end
	return self
end

function CDB:close()
	if self.f then
		self.f:close()
		self.f = nil
	end
end

function CDB:get(key)
	local f = self.f
	if not f then
		return nil, "closed"
	end
	if key == nil then
		return nil
	end

	local h = cdb_hash(key)
	local tab = h % 256
	local ent = self.toc[tab]
	local nslots = ent and ent.nslots or 0
	if nslots == 0 then
		return nil
	end

	local table_pos = ent.pos
	local start = rshift(h, 8) % nslots

	for i = 0, nslots - 1 do
		local slot = (start + i) % nslots
		local rec = read_at(f, table_pos + slot * 8, 8)
		local h2 = u32le(rec:sub(1, 4))
		local p = u32le(rec:sub(5, 8))
		if p == 0 then
			return nil
		end
		if h2 == h then
			local kd = read_at(f, p, 8)
			local klen = u32le(kd:sub(1, 4))
			local dlen = u32le(kd:sub(5, 8))
			local k = f:read(klen)
			if k == key then
				local v = f:read(dlen)
				return v
			end
		end
	end
	return nil
end

return CDB
