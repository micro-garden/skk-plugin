local utf8 = import("unicode/utf8")

local to_kata_map = {
	-- あ
	["あ"] = "ア",
	["い"] = "イ",
	["う"] = "ウ",
	["え"] = "エ",
	["お"] = "オ",
	-- か
	["か"] = "カ",
	["き"] = "キ",
	["く"] = "ク",
	["け"] = "ケ",
	["こ"] = "コ",
	-- さ
	["さ"] = "サ",
	["し"] = "シ",
	["す"] = "ス",
	["せ"] = "セ",
	["そ"] = "ソ",
	-- た
	["た"] = "タ",
	["ち"] = "チ",
	["つ"] = "ツ",
	["て"] = "テ",
	["と"] = "ト",
	-- な
	["な"] = "ナ",
	["に"] = "ニ",
	["ぬ"] = "ヌ",
	["ね"] = "ネ",
	["の"] = "ノ",
	-- は
	["は"] = "ハ",
	["ひ"] = "ヒ",
	["ふ"] = "フ",
	["へ"] = "ヘ",
	["ほ"] = "ホ",
	-- ま
	["ま"] = "マ",
	["み"] = "ミ",
	["む"] = "ム",
	["め"] = "メ",
	["も"] = "モ",
	-- や
	["や"] = "ヤ",
	["ゆ"] = "ユ",
	["よ"] = "ヨ",
	-- ら
	["ら"] = "ラ",
	["り"] = "リ",
	["る"] = "ル",
	["れ"] = "レ",
	["ろ"] = "ロ",
	-- わ
	["わ"] = "ワ",
	["ゐ"] = "ヰ",
	["ゑ"] = "ヱ",
	["を"] = "ヲ",
	-- ん
	["ん"] = "ン",
	-- が
	["が"] = "ガ",
	["ぎ"] = "ギ",
	["ぐ"] = "グ",
	["げ"] = "ゲ",
	["ご"] = "ゴ",
	-- ざ
	["ざ"] = "ザ",
	["じ"] = "ジ",
	["ず"] = "ズ",
	["ぜ"] = "ゼ",
	["ぞ"] = "ゾ",
	-- だ
	["だ"] = "ダ",
	["ぢ"] = "ヂ",
	["づ"] = "ヅ",
	["で"] = "デ",
	["ど"] = "ド",
	-- ば
	["ば"] = "バ",
	["び"] = "ビ",
	["ぶ"] = "ブ",
	["べ"] = "ベ",
	["ぼ"] = "ボ",
	-- ぱ
	["ぱ"] = "パ",
	["ぴ"] = "ピ",
	["ぷ"] = "プ",
	["ぺ"] = "ペ",
	["ぽ"] = "ポ",
	-- ゔ
	["ゔ"] = "ヴ",
	-- ぁ
	["ぁ"] = "ァ",
	["ぃ"] = "ィ",
	["ぅ"] = "ゥ",
	["ぇ"] = "ェ",
	["ぉ"] = "ォ",
	-- っ
	["っ"] = "ッ",
	-- ゃ
	["ゃ"] = "ャ",
	["ゅ"] = "ュ",
	["ょ"] = "ョ",
	-- ゎ
	["ゎ"] = "ヮ",
}

local to_hira_map = {}

for k, v in pairs(to_kata_map) do
	to_hira_map[v] = k
end

local function to_kata(text)
	local buf = {}

	local str = text
	while #str > 0 do
		local _, size = utf8.DecodeRuneInString(str)
		local char = str:sub(1, size)
		str = str:sub(1 + size)

		local kata = to_kata_map[char]
		if kata then
			table.insert(buf, kata)
		else
			table.insert(buf, char)
		end
	end

	return table.concat(buf)
end

local function to_hira(text)
	local buf = {}

	local str = text
	while #str > 0 do
		local _, size = utf8.DecodeRuneInString(str)
		local char = str:sub(1, size)
		str = str:sub(1 + size)

		local hira = to_hira_map[char]
		if hira then
			table.insert(buf, hira)
		else
			table.insert(buf, char)
		end
	end

	return table.concat(buf)
end

-------------
-- Exports --
-------------

local M = {}

M.to_kata = to_kata
M.to_hira = to_hira

return M
