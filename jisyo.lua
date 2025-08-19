-- jisyo.lua : Minimal SKK-JISYO parser (expects UTF-8 input)
--
-- API:
--   local jisyo = require("jisyo")
--   local dict = jisyo.load("SKK-JISYO.S") -- in UTF-8
--   dict:lookup(reading)
--     -> { "候補1", "候補2", ... } for okuri-nasi
--   dict:lookup_okuri(key, okuri_kana?)
--     -> candidates for okuri-ari; key like "もt"
--
-- Notes:
--   - This parser ignores annotations (e.g., "候補;note") and returns raw
--     strings.
--   - Okuri blocks ( [た/…/] ) are supported for per-okuri candidates.
--   - Convert your SKK dictionary to UTF-8 beforehand
--     (e.g., via nkf or iconv).

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function load(path)
	local dict = { okuri_ari = {}, okuri_nasi = {} }

	local fp = io.open(path, "rb")

	if fp then
		local section = nil -- "ari" | "nasi"

		for raw in fp:lines() do
			local line = trim(raw)

			-- Section markers in SKK-JISYO:
			--   ;; okuri-ari entries.
			--   ;; okuri-nasi entries.
			if line:find("^;;%s*okuri%-ari entries%.") then
				section = "ari"
			elseif line:find("^;;%s*okuri%-nasi entries%.") then
				section = "nasi"
			elseif line:find("^;") then
			-- Header or comment line: ignore
			elseif section == "ari" or section == "nasi" then
				-- Entry line format:
				--   <key><space>/<cand1>/<cand2>/.../ [<okuri-blocks>]
				-- Example (okuri-ari):
				--   もt /持/ [た/持た/][ち/持ち/]
				local key, rest = line:match("^(%S+)%s+(.+)$")
				if key and rest then
					-- Extract okuri blocks like: [た/持た/][ち/持ち/]
					local blocks = {}
					local rest_wo_blocks = rest:gsub("%b[]", function(b)
						table.insert(blocks, b:sub(2, -2)) -- strip [ ]
						return " " -- keep spacing where block was
					end)

					-- Parse top-level default candidates: /.../
					local defaults = {}
					for c in rest_wo_blocks:gmatch("/([^/]+)/") do
						table.insert(defaults, c)
					end

					if section == "nasi" then
						-- Okuri-nasi entries are a simple reading
						--   -> candidates list
						dict.okuri_nasi[key] = defaults
					else
						-- Okuri-ari entries may have per-okuri blocks
						local entry = { default = defaults, blocks = {} }
						for _, blk in ipairs(blocks) do
							-- Block format: <okuri-kana>/<cand1>/<cand2>/.../
							local okuri = blk:match("^([^/]+)/")
							if okuri then
								-- remove "<okuri>/"
								local cand_part = blk:sub(#okuri + 2)

								local arr = {}
								for c in cand_part:gmatch("/([^/]+)/") do
									table.insert(arr, c)
								end
								entry.blocks[okuri] = arr
							end
						end
						dict.okuri_ari[key] = entry
					end
				end
			end
		end

		fp:close()
	end

	-- Lookup for okuri-nasi (no okuri): returns an array of candidates or nil
	function dict:lookup(reading)
		return self.okuri_nasi[reading]
	end

	-- Lookup for okuri-ari:
	--   key:    "stem-kana + first romaji letter" (e.g., "もt")
	--   okuri:  optional okuri kana to prefer block candidates (e.g., "た")
	-- Returns an array of candidates or nil.
	function dict:lookup_okuri(key, okuri_kana)
		local e = self.okuri_ari[key]
		if not e then
			return nil
		end
		if okuri_kana and e.blocks and e.blocks[okuri_kana] and #e.blocks[okuri_kana] > 0 then
			return e.blocks[okuri_kana]
		end
		return e.default
	end

	return dict
end

-------------
-- Exports --
-------------

local M = {}

M.load = load

return M
