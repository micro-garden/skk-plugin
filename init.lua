VERSION = "0.0.2"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")

local plug_path = config.ConfigDir .. "/plug/?.lua"
if not package.path:find(plug_path, 1, true) then
	package.path = package.path .. ";" .. plug_path
end

local utils = require("skk/utils")
local bell = require("skk/bell")
local download = require("skk/download")
local romaji = require("skk/romaji")
local jisyo = require("skk/jisyo")

local d

-- internal constants
local TEXT_EVENT_INSERT = 1
local TEXT_EVENT_REPLACE = 0
local TEXT_EVENT_REMOVE = -1

-- romaji modes
local DIRECT_MODE = 0 -- no conversion
local HIRAGANA_MODE = 1
local KATAKANA_MODE = 2
local ALPHABET_MODE = 3 -- wide alphabet

-- conversion modes
local CONV_NONE = 0
local CONV_START = 1
local CONV_OKURI = 2

-- states
local romaji_mode = DIRECT_MODE
local kana_buffer = ""
local conv_mode = CONV_NONE
local conv_buffer = ""
local conv_list = nil
local conv_index = 1
local conv_cand = ""

local function show_mode(kana)
	local mark
	if romaji_mode == DIRECT_MODE then
		mark = "aA"
	elseif romaji_mode == HIRAGANA_MODE then
		mark = "あ"
	elseif romaji_mode == KATAKANA_MODE then
		mark = "ア"
	elseif romaji_mode == ALPHABET_MODE then
		mark = "ａＡ"
	else
		bell.fatal("show_mode: invalid mode = " .. romaji_mode)
		return
	end
	if kana then
		micro.InfoBar():Message(mark .. " " .. conv_buffer .. "[" .. conv_cand .. kana .. "]")
	else
		micro.InfoBar():Message(mark .. " " .. conv_buffer .. "[" .. conv_cand .. kana_buffer .. "]")
	end
end

function Skk()
	if not d then
		micro.InfoBar():Message("Please wait.. Loading SKK dictionaries..")
		utils.next_tick(function()
			d = jisyo.load(config.ConfigDir .. "/skk-dict/SKK-JISYO.L")
			micro.InfoBar():Message("Done. SKK dictionaries loaded.")
		end)
	end

	if conv_mode ~= CONV_NONE then
		local out = (conv_cand ~= "" and conv_cand) or conv_buffer
		if out and #out > 0 then
			local buf = micro.CurPane().Buf
			local cursor = buf:GetActiveCursor()
			local loc = buffer.Loc(cursor.X, cursor.Y)
			micro.CurPane().Buf:Insert(loc, out)
		end
	end

	romaji_mode = HIRAGANA_MODE
	kana_buffer = ""

	conv_mode = CONV_NONE
	conv_buffer = ""
	conv_list = nil
	conv_index = 1
	conv_cand = ""

	if d then
		show_mode()
	end
end

function SkkGet()
	download.defaults()
end

local function bytes_to_string(array)
	local buf = {}
	for i = 1, #array do
		table.insert(buf, string.char(array[i]))
	end
	return table.concat(buf)
end

local function utf8_chop(s)
	local i = #s
	while i > 0 do
		local b = s:byte(i)
		if b < 128 or b >= 192 then
			return s:sub(1, i - 1)
		end
		i = i - 1
	end
	return ""
end

local function reset_conv()
	conv_mode = CONV_NONE
	conv_buffer = ""
	conv_list = nil
	conv_index = 1
	conv_cand = ""
end

local function check_sokuon()
	local kana
	if romaji.is_sokuon[kana_buffer] then
		if romaji_mode == HIRAGANA_MODE then
			kana = "っ"
		elseif romaji_mode == KATAKANA_MODE then
			kana = "ッ"
		else
			bell.fatal("sokuon: invalid mode = " .. romaji_mode)
			kana = nil
		end
		kana_buffer = string.sub(kana_buffer, 2)
		return kana
	elseif romaji.is_n[kana_buffer] then
		if romaji_mode == HIRAGANA_MODE then
			kana = "ん"
		elseif romaji_mode == KATAKANA_MODE then
			kana = "ン"
		else
			bell.fatal("n: invalid mode = " .. romaji_mode)
			kana = nil
		end
		kana_buffer = string.sub(kana_buffer, 2)
		return kana
	else
		local lookup = kana_buffer
		if romaji.aliases[lookup] then
			lookup = romaji.aliases[lookup]
		end

		if romaji_mode == HIRAGANA_MODE then
			kana = romaji.to_hiragana[lookup]
		elseif romaji_mode == KATAKANA_MODE then
			kana = romaji.to_katakana[lookup]
		else
			bell.fatal("kana: invalid mode = " .. romaji_mode)
			kana = nil
		end

		if kana then
			kana_buffer = ""
		end

		return kana
	end
end

function onBeforeTextEvent(buf, ev)
	if romaji_mode == DIRECT_MODE then
		return true
	end

	if ev.EventType == TEXT_EVENT_REMOVE then
		if #kana_buffer > 0 then
			-- expects only backspace
			kana_buffer = string.sub(kana_buffer, 1, -2)
			show_mode()

			local cursor = micro.CurPane().Buf:GetActiveCursor()
			cursor:ResetSelection()
			cursor.Loc.X = cursor.Loc.X + 1
			return false
		elseif conv_mode ~= CONV_NONE and #conv_buffer > 0 then
			conv_buffer = utf8_chop(conv_buffer)
			if #conv_buffer < 1 then
				conv_mode = CONV_NONE
			end
			conv_list = nil
			conv_index = 1
			conv_cand = ""
			show_mode()

			local cursor = micro.CurPane().Buf:GetActiveCursor()
			cursor:ResetSelection()
			cursor.Loc.X = cursor.Loc.X + 1
			return false
		else
			return true
		end
	end

	if ev.EventType == TEXT_EVENT_REPLACE then
		return true
	end

	-- assert
	if ev.EventType ~= TEXT_EVENT_INSERT then
		bell.fatal("Invalid text event type = ev.EventType")
		return true
	end

	if #ev.Deltas ~= 1 then
		return true
	end
	local delta = ev.Deltas[1]
	local output = ""

	-- Text is byte array
	local text = bytes_to_string(delta.Text)

	if romaji_mode == ALPHABET_MODE then
		local alphabet = romaji.to_alphabet[text]
		if alphabet then
			delta.Text = output .. alphabet
		end
		return true
	end

	-- now in Hiragana or Katakana mode

	-- pass through pasted long text
	if #text ~= 1 then
		return true
	end

	if text == " " and conv_mode ~= CONV_NONE then
		if not d then
			micro.InfoBar():Message("Please wait.. Loading SKK dictionaries..")
			delta.Text = output
			return true
		end

		if not conv_list then
			if conv_mode == CONV_OKURI then
				conv_list = d:lookup_okuri(conv_buffer) or {}
			else
				conv_list = d:lookup(conv_buffer) or {}
			end
			conv_index = 1
			if #conv_list < 1 then
				micro.InfoBar():Message("SKK: 候補なし")
				delta.Text = output
				return true
			end
		else
			conv_index = (conv_index % #conv_list) + 1
		end
		conv_cand = conv_list[conv_index] or ""

		show_mode()
		delta.Text = output
		return true
	end

	if text == "\n" and conv_mode ~= CONV_NONE then
		local out = conv_cand ~= "" and conv_cand or conv_buffer
		delta.Text = output .. out
		reset_conv()
		show_mode()
		return true
	end

	if text == "L" then
		romaji_mode = ALPHABET_MODE
		kana_buffer = ""
		show_mode()

		delta.Text = output
		return true
	end

	if text:match("^[A-Z]$") then
		if conv_mode == CONV_NONE then
			conv_mode = CONV_START
		elseif conv_mode == CONV_START then
			if #conv_cand > 0 then
				output = output .. conv_cand
				reset_conv()
				conv_mode = CONV_START
			else
				conv_mode = CONV_OKURI
			end
		elseif conv_mode == CONV_OKURI then
			if #conv_cand > 0 then
				output = output .. conv_cand
				reset_conv()
				conv_mode = CONV_START
			else
				conv_mode = CONV_OKURI
			end
		end
		text = text:lower()
	end

	if not romaji.to_kigou[text] then
		if not text:match("^%a+$") then
			return true
		end
	end

	if text == "l" then
		romaji_mode = DIRECT_MODE
		kana_buffer = ""
		show_mode()

		delta.Text = output
		return true
	elseif text == "q" then
		if romaji_mode == HIRAGANA_MODE then
			romaji_mode = KATAKANA_MODE
		elseif romaji_mode == KATAKANA_MODE then
			romaji_mode = HIRAGANA_MODE
		else
			bell.fatal("q: invalid mode = " .. romaji_mode)
			return true
		end
		show_mode()

		delta.Text = output
		return true
	end

	kana_buffer = kana_buffer .. text

	local kana = romaji.to_kigou[kana_buffer]
	if kana then
		kana_buffer = ""
	else
		kana = check_sokuon()
	end

	if conv_mode == CONV_NONE then
		if kana then
			delta.Text = output .. kana
		else
			delta.Text = output
		end
		show_mode(kana)
		return true
	elseif conv_mode == CONV_START then
		if kana then
			conv_buffer = conv_buffer .. kana
			conv_list = nil
			conv_index = 1
			conv_cand = ""
		end
		delta.Text = output
		show_mode()
		return true
	elseif conv_mode == CONV_OKURI then
		if kana then
			kana_buffer = conv_buffer:sub(-1, -1) .. kana_buffer

			local kana_after
			kana_after = check_sokuon()

			if kana_after then
				delta.Text = output .. conv_cand .. kana_after
			else
				delta.Text = output .. conv_cand .. kana
				kana_buffer = ""
			end

			reset_conv()

			show_mode()
			return true
		else
			conv_buffer = conv_buffer .. text

			if not d then
				micro.InfoBar():Message("Please wait.. Loading SKK dictionaries..")
				delta.Text = output
				return true
			end

			conv_list = d:lookup_okuri(conv_buffer)
			conv_index = 1
			conv_cand = conv_list and conv_list[conv_index] or ""

			show_mode()
			delta.Text = output
			return true
		end
	end

	delta.Text = output
	return true
end

function init()
	config.MakeCommand("skk", Skk, config.NoComplete)
	config.MakeCommand("skkget", SkkGet, config.NoComplete)
	config.TryBindKey("Ctrl-j", "lua:skk.Skk", false)
	config.AddRuntimeFile("skk", config.RTHelp, "help/skk.md")
end
