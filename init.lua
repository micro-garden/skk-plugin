VERSION = "0.0.0"

local micro = import("micro")
local config = import("micro/config")

local plug_name = "skk"
local plug_path = config.ConfigDir .. "/plug/" .. plug_name .. "/?.lua"
if not package.path:find(plug_path, 1, true) then
	package.path = package.path .. ";" .. plug_path
end

local download = require("download")
local romaji = require("romaji")
local jisyo = require("jisyo")
local test = require("test")

local d

-- internal constants
local TextEventInsert = 1
local TextEventReplace = 0
local TextEventRemove = -1

-- romaji modes
local DirectMode = 0 -- no conversion
local HiraganaMode = 1
local KatakanaMode = 2
local AlphabetMode = 3 -- wide alphabet

-- states
local romaji_mode = DirectMode
local kana_buffer = ""

local function show_mode(kana)
	local mark
	if romaji_mode == DirectMode then
		mark = "aA"
	elseif romaji_mode == HiraganaMode then
		mark = "あ"
	elseif romaji_mode == KatakanaMode then
		mark = "ア"
	elseif romaji_mode == AlphabetMode then
		mark = "ａＡ"
	else -- program error
		micro.InfoBar():Error("show_mode: invalid mode = " .. romaji_mode)
		return
	end
	if kana then
		micro.InfoBar():Message(mark .. "[" .. kana .. "]")
	else
		micro.InfoBar():Message(mark .. "[" .. kana_buffer .. "]")
	end
end

function Skk()
	if not d then
		d = skk.load(config.ConfigDir .. "/SKK-JISYO.S")
	end

	romaji_mode = HiraganaMode
	kana_buffer = ""
	show_mode()
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

function onBeforeTextEvent(buf, ev)
	if romaji_mode == DirectMode then
		return true
	end

	if ev.EventType == TextEventRemove then
		if #kana_buffer > 0 then
			-- expects only backspace
			kana_buffer = string.sub(kana_buffer, 1, -2)
			show_mode()

			local cursor = micro.CurPane().Buf:GetActiveCursor()
			cursor:ResetSelection()
			cursor.Loc.X = cursor.Loc.X + 1
			return false
		else
			return true
		end
	end

	if ev.EventType == TextEventReplace then
		return true
	end

	-- assert
	if ev.EventType ~= TextEventInsert then -- program error
		micro.InfoBar():Error("Invalid text event type = ev.EventType")
		return true
	end

	if #ev.Deltas ~= 1 then
		return true
	end

	-- Text is byte array
	local text = bytes_to_string(ev.Deltas[1].Text)

	if romaji_mode == AlphabetMode then
		local alphabet = romaji.to_alphabet[text]
		if alphabet then
			ev.Deltas[1].Text = alphabet
		end
		return true
	end

	-- now in Hiragana or Katakana mode

	if not romaji.to_kigou[text] then
		if not text:match("^%a+$") then
			return true
		end
	end

	-- pass through pasted long text
	if #text ~= 1 then
		return true
	end

	if text == "l" then
		romaji_mode = DirectMode
		kana_buffer = ""
		show_mode()

		ev.Deltas[1].Text = ""
		return true
	elseif text == "q" then
		if romaji_mode == HiraganaMode then
			romaji_mode = KatakanaMode
		elseif romaji_mode == KatakanaMode then
			romaji_mode = HiraganaMode
		else -- program error
			micro.InfoBar():Error("q: invalid mode = " .. romaji_mode)
			return true
		end
		show_mode()

		ev.Deltas[1].Text = ""
		return true
	elseif text == "L" then
		romaji_mode = AlphabetMode
		kana_buffer = ""
		show_mode()

		ev.Deltas[1].Text = ""
		return true
	end

	kana_buffer = kana_buffer .. text

	local kana = romaji.to_kigou[kana_buffer]
	if kana then
		kana_buffer = ""
	else
		if romaji.is_sokuon[kana_buffer] then
			if romaji_mode == HiraganaMode then
				kana = "っ"
			elseif romaji_mode == KatakanaMode then
				kana = "ッ"
			else -- program error
				micro.InfoBar():Error("sokuon: invalid mode = " .. romaji_mode)
				return false
			end
			kana_buffer = string.sub(kana_buffer, 2)
		elseif romaji.is_n[kana_buffer] then
			if romaji_mode == HiraganaMode then
				kana = "ん"
			elseif romaji_mode == KatakanaMode then
				kana = "ン"
			else -- program error
				micro.InfoBar():Error("n: invalid mode = " .. romaji_mode)
				return false
			end
			kana_buffer = string.sub(kana_buffer, 2)
		else
			local lookup = kana_buffer
			if romaji.aliases[lookup] then
				lookup = romaji.aliases[lookup]
			end

			if romaji_mode == HiraganaMode then
				kana = romaji.to_hiragana[lookup]
			elseif romaji_mode == KatakanaMode then
				kana = romaji.to_katakana[lookup]
			else -- program error
				micro.InfoBar():Error("kana: invalid mode = " .. romaji_mode)
				return false
			end

			if kana then
				kana_buffer = ""
			end
		end
	end

	show_mode(kana)

	if kana then
		ev.Deltas[1].Text = kana
	else
		ev.Deltas[1].Text = ""
	end
	return true
end

function SkkTest()
	test.run()
end

function init()
	config.MakeCommand("skk", Skk, config.NoComplete)
	config.MakeCommand("skkget", SkkGet, config.NoComplete)
	config.TryBindKey("Ctrl-j", "lua:skk.Skk", false)
	config.AddRuntimeFile("skk", config.RTHelp, "help/skk.md")

	config.MakeCommand("skktest", SkkTest, config.NoComplete)
end
