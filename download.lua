local micro = import("micro")
local config = import("micro/config")
local http = import("net/http")
local path = import("path/filepath")
local oslib = import("os")
local goio = import("io")

local function dict_dir()
	local d = path.Join(config.ConfigDir, "skk-dict")
	oslib.MkdirAll(d, tonumber("755", 8))
	return d
end

local function http_get_to_file(url, outpath)
	local resp, err = http.Get(url)
	if err ~= nil then
		micro.InfoBar():Error("HTTP error: " .. tostring(err))
		return false
	end
	if resp.StatusCode < 200 or resp.StatusCode >= 300 then
		if resp.Body ~= nil then
			resp.Body:Close()
		end
		micro.InfoBar():Error("HTTP status: " .. tostring(resp.Status))
		return false
	end

	oslib.MkdirAll(path.Dir(outpath), tonumber("755", 8)) -- 0755

	local f, ferr = oslib.Create(outpath)
	if ferr ~= nil then
		resp.Body:Close()
		micro.InfoBar():Error("Create failed: " .. tostring(ferr))
		return false
	end

	local _, cerr = goio.Copy(f, resp.Body)

	f:Close()
	resp.Body:Close()

	if cerr ~= nil then
		micro.InfoBar():Error("Copy error: " .. tostring(cerr))
		return false
	end

	oslib.Chmod(outpath, tonumber("644", 8)) -- 0644

	return true
end

local function skk_dicts(names)
	local base = "https://raw.githubusercontent.com/akikareha/skk-dict-utf8/main/utf8/"
	local saved = {}
	for _, name in ipairs(names) do
		local url = base .. name
		local dest = path.Join(dict_dir(), name)
		if http_get_to_file(url, dest) then
			table.insert(saved, dest)
		end
	end
	if #saved > 0 then
		micro.InfoBar():Message("Saved: " .. table.concat(saved, ", "))
	end
end

function defaults()
	skk_dicts({
		"SKK-JISYO.L",
		"SKK-JISYO.propernoun",
		"SKK-JISYO.geo",
		"SKK-JISYO.jinmei",
	})
end

-------------
-- Esports --
-------------

local M = {}

M.defaults = defaults

return M
