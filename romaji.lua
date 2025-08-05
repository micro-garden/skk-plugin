VERSION = "0.0.0"

local micro = import("micro")
local config = import("micro/config")

-- constants
local TextEventInsert = 1
local TextEventRemove = -1

-- conversion tables - concrete definitions are at the bottom of the file
local romaji_to_hiragana = {}
local romaji_to_katakana = {}
local sokuon = {}

-- states
local romaji_mode = false
local katakana_mode = false
local kana_buffer = ""

local function show_mode(kana)
	local mark
	if romaji_mode then
		if katakana_mode then
			mark = "ア"
		else
			mark = "あ"
		end
	else
		mark = "aA"
	end
	if kana then
		micro.InfoBar():Message(mark .. "[" .. kana .. "]")
	else
		micro.InfoBar():Message(mark .. "[" .. kana_buffer .. "]")
	end
end

function RomajiCmd()
	romaji_mode = true
	katakana_mode = false
	kana_buffer = ""
	show_mode()
end

local function bytes_to_string(array)
	local buf = {}
	for i = 1, #array do
		table.insert(buf, string.char(array[i]))
	end
	return table.concat(buf)
end

function onBeforeTextEvent(buf, ev)
	if not romaji_mode then
		return true
	end

	if ev.EventType == TextEventRemove and #kana_buffer > 0 then
		kana_buffer = string.sub(kana_buffer, 1, -2)
		show_mode()
		return false
	end

	if ev.EventType ~= TextEventInsert then
		return true
	end

	if #ev.Deltas ~= 1 then
		return true
	end

	-- Text is byte array
	local text = bytes_to_string(ev.Deltas[1].Text)

	if #text ~= 1 then
		return true
	end

	if text == "l" then
		romaji_mode = false
		kana_buffer = ""
		show_mode()
		return false
	end

	if text == "q" then
		katakana_mode = not katakana_mode
		show_mode()
		return false
	end

	kana_buffer = kana_buffer .. text

	local kana
	if sokuon[kana_buffer] then
		if katakana_mode then
			kana = "ッ"
		else
			kana = "っ"
		end
		kana_buffer = string.sub(kana_buffer, 2)
	else
		if katakana_mode then
			kana = romaji_to_katakana[kana_buffer]
		else
			kana = romaji_to_hiragana[kana_buffer]
		end
		if kana then
			kana_buffer = ""
		end
	end

	if kana then
		ev.Deltas[1].Text = kana
	else
		ev.Deltas[1].Text = ""
	end

	show_mode(kana)
	return true
end

function init()
	config.MakeCommand("romaji", RomajiCmd, config.NoComplete)
	config.TryBindKey("Ctrl-j", "lua:romaji.RomajiCmd", true)
	config.AddRuntimeFile("romaji", config.RTHelp, "help/romaji.md")
end

romaji_to_hiragana = {
	-- あ
	["a"] = "あ",
	["i"] = "い",
	["u"] = "う",
	["e"] = "え",
	["o"] = "お",
	-- か
	["ka"] = "か",
	["ki"] = "き",
	["ku"] = "く",
	["ke"] = "け",
	["ko"] = "こ",
	-- さ
	["sa"] = "さ",
	["si"] = "し",
	["su"] = "す",
	["se"] = "せ",
	["so"] = "そ",
	-- た
	["ta"] = "た",
	["ti"] = "ち",
	["tu"] = "つ",
	["te"] = "て",
	["to"] = "と",
	-- な
	["na"] = "な",
	["ni"] = "に",
	["nu"] = "ぬ",
	["ne"] = "ね",
	["no"] = "の",
	-- は
	["ha"] = "は",
	["hi"] = "ひ",
	["hu"] = "ふ",
	["he"] = "へ",
	["ho"] = "ほ",
	-- ま
	["ma"] = "ま",
	["mi"] = "み",
	["mu"] = "む",
	["me"] = "め",
	["mo"] = "も",
	-- や
	["ya"] = "や",
	["yu"] = "ゆ",
	["yo"] = "よ",
	-- ら
	["ra"] = "ら",
	["ri"] = "り",
	["ru"] = "る",
	["re"] = "れ",
	["ro"] = "ろ",
	-- わ
	["wa"] = "わ",
	["wi"] = "うぃ",
	["we"] = "うぇ",
	["wo"] = "を",
	-- ん
	["nn"] = "ん",
	-- が
	["ga"] = "が",
	["gi"] = "ぎ",
	["gu"] = "ぐ",
	["ge"] = "げ",
	["go"] = "ご",
	-- ざ
	["za"] = "ざ",
	["zi"] = "じ",
	["zu"] = "ず",
	["ze"] = "ぜ",
	["zo"] = "ぞ",
	-- だ
	["da"] = "だ",
	["di"] = "ぢ",
	["du"] = "づ",
	["de"] = "で",
	["do"] = "ど",
	-- ば
	["ba"] = "ば",
	["bi"] = "び",
	["bu"] = "ぶ",
	["be"] = "べ",
	["bo"] = "ぼ",
	-- ぱ
	["pa"] = "ぱ",
	["pi"] = "ぴ",
	["pu"] = "ぷ",
	["pe"] = "ぺ",
	["po"] = "ぽ",
	-- きゃ
	["kya"] = "きゃ",
	["kyi"] = "きぃ",
	["kyu"] = "きゅ",
	["kye"] = "きぇ",
	["kyo"] = "きょ",
	-- しゃ
	["sya"] = "しゃ",
	["syi"] = "しぃ",
	["syu"] = "しゅ",
	["sye"] = "しぇ",
	["syo"] = "しょ",
	-- ちゃ
	["tya"] = "ちゃ",
	["tyi"] = "ちぃ",
	["tyu"] = "ちゅ",
	["tye"] = "ちぇ",
	["tyo"] = "ちょ",
	-- てゃ
	["tha"] = "てゃ", -- てぁ (IBus SKK)
	["thi"] = "てぃ",
	["thu"] = "てゅ",
	["the"] = "てぇ",
	["tho"] = "てょ",
	-- にゃ
	["nya"] = "にゃ",
	["nyi"] = "にぃ",
	["nyu"] = "にゅ",
	["nye"] = "にぇ",
	["nyo"] = "にょ",
	-- ひゃ
	["hya"] = "ひゃ",
	["hyi"] = "ひぃ",
	["hyu"] = "ひゅ",
	["hye"] = "ひぇ",
	["hyo"] = "ひょ",
	-- みゃ
	["mya"] = "みゃ",
	["myi"] = "みぃ",
	["myu"] = "みゅ",
	["mye"] = "みぇ",
	["myo"] = "みょ",
	-- りゃ
	["rya"] = "りゃ",
	["ryi"] = "りぃ",
	["ryu"] = "りゅ",
	["rye"] = "りぇ",
	["ryo"] = "りょ",
	-- ふぁ
	["fa"] = "ふぁ",
	["fi"] = "ふぃ",
	["fe"] = "ふぇ",
	["fo"] = "ふぉ",
	-- ふゃ
	["fya"] = "ふゃ",
	["fyu"] = "ふゅ",
	["fyo"] = "ふょ",
	-- ぎゃ
	["gya"] = "ぎゃ",
	["gyi"] = "ぎぃ",
	["gyu"] = "ぎゅ",
	["gye"] = "ぎぇ",
	["gyo"] = "ぎょ",
	-- じゃ
	["zya"] = "じゃ",
	["zyi"] = "じぃ",
	["zyu"] = "じゅ",
	["zye"] = "じぇ",
	["zyo"] = "じょ",
	-- ぢゃ
	["dya"] = "ぢゃ",
	["dyi"] = "ぢぃ",
	["dyu"] = "ぢゅ",
	["dye"] = "ぢぇ",
	["dyo"] = "ぢょ",
	-- でゃ
	["dha"] = "でゃ",
	["dhi"] = "でぃ",
	["dhu"] = "でゅ",
	["dhe"] = "でぇ",
	["dho"] = "でょ",
	-- びゃ
	["bya"] = "びゃ",
	["byi"] = "びぃ",
	["byu"] = "びゅ",
	["bye"] = "びぇ",
	["byo"] = "びょ",
	-- ぴゃ
	["pya"] = "ぴゃ",
	["pyi"] = "ぴぃ",
	["pyu"] = "ぴゅ",
	["pye"] = "ぴぇ",
	["pyo"] = "ぴょ",
	-- ゔぁ
	["va"] = "ゔぁ",
	["vi"] = "ゔぃ",
	["vu"] = "ゔ",
	["ve"] = "ゔぇ",
	["vo"] = "ゔぉ",
	-- ぁ
	["xa"] = "ぁ",
	["xi"] = "ぃ",
	["xu"] = "ぅ",
	["xe"] = "ぇ",
	["xo"] = "ぉ",
	-- ゃ
	["xya"] = "ゃ",
	["xyu"] = "ゅ",
	["xyo"] = "ょ",
	-- っ
	["xtu"] = "っ",
}

romaji_to_katakana = {
	-- ア
	["a"] = "ア",
	["i"] = "イ",
	["u"] = "ウ",
	["e"] = "エ",
	["o"] = "オ",
	-- カ
	["ka"] = "カ",
	["ki"] = "キ",
	["ku"] = "ク",
	["ke"] = "ケ",
	["ko"] = "コ",
	-- サ
	["sa"] = "サ",
	["si"] = "シ",
	["su"] = "ス",
	["se"] = "セ",
	["so"] = "ソ",
	-- タ
	["ta"] = "タ",
	["ti"] = "チ",
	["tu"] = "ツ",
	["te"] = "テ",
	["to"] = "ト",
	-- ナ
	["na"] = "ナ",
	["ni"] = "ニ",
	["nu"] = "ヌ",
	["ne"] = "ネ",
	["no"] = "ノ",
	-- ハ
	["ha"] = "ハ",
	["hi"] = "ヒ",
	["hu"] = "フ",
	["he"] = "ヘ",
	["ho"] = "ホ",
	-- マ
	["ma"] = "マ",
	["mi"] = "ミ",
	["mu"] = "ム",
	["me"] = "メ",
	["mo"] = "モ",
	-- ヤ
	["ya"] = "ヤ",
	["yu"] = "ユ",
	["yo"] = "ヨ",
	-- ラ
	["ra"] = "ラ",
	["ri"] = "リ",
	["ru"] = "ル",
	["re"] = "レ",
	["ro"] = "ロ",
	-- ワ
	["wa"] = "ワ",
	["wi"] = "ウィ",
	["we"] = "ウェ",
	["wo"] = "ヲ",
	-- ン
	["nn"] = "ン",
	-- ガ
	["ga"] = "ガ",
	["gi"] = "ギ",
	["gu"] = "グ",
	["ge"] = "ゲ",
	["go"] = "ゴ",
	-- ザ
	["za"] = "ザ",
	["zi"] = "ジ",
	["zu"] = "ズ",
	["ze"] = "ゼ",
	["zo"] = "ゾ",
	-- ダ
	["da"] = "ダ",
	["di"] = "ヂ",
	["du"] = "ヅ",
	["de"] = "デ",
	["do"] = "ド",
	-- バ
	["ba"] = "バ",
	["bi"] = "ビ",
	["bu"] = "ブ",
	["be"] = "ベ",
	["bo"] = "ボ",
	-- パ
	["pa"] = "パ",
	["pi"] = "ピ",
	["pu"] = "プ",
	["pe"] = "ペ",
	["po"] = "ポ",
	-- キャ
	["kya"] = "キャ",
	["kyi"] = "キィ",
	["kyu"] = "キュ",
	["kye"] = "キェ",
	["kyo"] = "キョ",
	-- シャ
	["sya"] = "シャ",
	["syi"] = "シィ",
	["syu"] = "シュ",
	["sye"] = "シェ",
	["syo"] = "ショ",
	-- チャ
	["tya"] = "チャ",
	["tyi"] = "チィ",
	["tyu"] = "チュ",
	["tye"] = "チェ",
	["tyo"] = "チョ",
	-- テャ
	["tha"] = "テャ", -- テァ (IBus SKK)
	["thi"] = "ティ",
	["thu"] = "テュ",
	["the"] = "テェ",
	["tho"] = "テョ",
	-- ニャ
	["nya"] = "ニャ",
	["nyi"] = "ニィ",
	["nyu"] = "ニュ",
	["nye"] = "ニェ",
	["nyo"] = "ニョ",
	-- ヒャ
	["hya"] = "ヒャ",
	["hyi"] = "ヒィ",
	["hyu"] = "ヒュ",
	["hye"] = "ヒェ",
	["hyo"] = "ヒョ",
	-- ミャ
	["mya"] = "ミャ",
	["myi"] = "ミィ",
	["myu"] = "ミュ",
	["mye"] = "ミェ",
	["myo"] = "ミョ",
	-- リャ
	["rya"] = "リャ",
	["ryi"] = "リィ",
	["ryu"] = "リュ",
	["rye"] = "リェ",
	["ryo"] = "リョ",
	-- ファ
	["fa"] = "ファ",
	["fi"] = "フィ",
	["fe"] = "フェ",
	["fo"] = "フォ",
	-- フャ
	["fya"] = "フャ",
	["fyu"] = "フュ",
	["fyo"] = "フョ",
	-- ギャ
	["gya"] = "ギャ",
	["gyi"] = "ギィ",
	["gyu"] = "ギュ",
	["gye"] = "ギェ",
	["gyo"] = "ギョ",
	-- ジャ
	["zya"] = "ジャ",
	["zyi"] = "ジィ",
	["zyu"] = "ジュ",
	["zye"] = "ジェ",
	["zyo"] = "ジョ",
	-- ヂャ
	["dya"] = "ヂャ",
	["dyi"] = "ヂィ",
	["dyu"] = "ヂュ",
	["dye"] = "ヂェ",
	["dyo"] = "ヂョ",
	-- デャ
	["dha"] = "デャ",
	["dhi"] = "ディ",
	["dhu"] = "デュ",
	["dhe"] = "デェ",
	["dho"] = "デョ",
	-- ビャ
	["bya"] = "ビャ",
	["byi"] = "ビィ",
	["byu"] = "ビュ",
	["bye"] = "ビェ",
	["byo"] = "ビョ",
	-- ピャ
	["pya"] = "ピャ",
	["pyi"] = "ピィ",
	["pyu"] = "ピュ",
	["pye"] = "ピェ",
	["pyo"] = "ピョ",
	-- ヴァ
	["va"] = "ヴァ",
	["vi"] = "ヴィ",
	["vu"] = "ヴ",
	["ve"] = "ヴェ",
	["vo"] = "ヴォ",
	-- ァ
	["xa"] = "ァ",
	["xi"] = "ィ",
	["xu"] = "ゥ",
	["xe"] = "ェ",
	["xo"] = "ォ",
	-- ャ
	["xya"] = "ャ",
	["xyu"] = "ュ",
	["xyo"] = "ョ",
	-- ッ
	["xtu"] = "ッ",
}

sokuon = {
	["kk"] = true,
	["ss"] = true,
	["tt"] = true,
	["hh"] = true,
	["mm"] = true,
	["yy"] = true,
	["rr"] = true,
	["ww"] = true,
	["gg"] = true,
	["zz"] = true,
	["dd"] = true,
	["bb"] = true,
	["pp"] = true,
	["ff"] = true,
	["vv"] = true,
	["xx"] = true,
}
