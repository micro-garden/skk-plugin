# SKK Plugin

**SKK** is a plugin that provides a Japanese input method inspired by the
SKK.  
It allows typing Japanese Hiragana, Katakana, and full-width (Zenkaku) Latin
characters **without any external input method (IME)**.  
Hiragana can be converted to Kanji by using SKK dictionaries.

## Features

- Romaji (Latin alphabet) to Kana (Hiragana/Katakana) conversion
- Toggle between:
    - Hiragana mode
    - Katakana mode
    - Zenkaku alphabet mode (full-width Latin)
    - Direct mode (no conversion)
- Insert common Japanese punctuation (、 。 ー)
- Handles small Kana (ぁぃぅ etc.), double consonants (っ), and "ん"
- Hiragana can be converted to Kanji by using SKK dictionaries
- Input buffer is shown in the info bar
- Works in terminal-only environments (no GUI/IME needed)

## Usage

### Start Romaji Input Mode

### Start Kana Input Mode

Press: `Ctrl-j`

Or run the command:

```
romaji
```

This switches to **Hiragana input mode** by default.

### Mode Switching (In Kana Mode)

| Key | Action                          |
| --- | ------------------------------- |
| `l` | Exit to Direct Mode             |
| `q` | Toggle Hiragana <--> Katakana   |
| `L` | Switch to Zenkaku Alphabet Mode |

### Input Examples

| Input | Hiragana          | Katakana          | Zenkaku Alphabet |
| ----- | ----------------- | ----------------- | ---------------- |
| aiueo | あいうえお        | アイウエオ        | ａｉｕｅｏ       |
| kana  | かな              | カナ              | ｋａｎａ         |
| nn    | ん                | ン                | ｎｎ             |
| kko   | っこ              | ッコ              | ｋｋｏ           |
| , . - | 、 。 ー          | Same              | ，．−            |

## Modes

| Mode           | Mark   | Description                          |
| -------------- | ------ | ------------------------------------ |
| Direct Mode    | `aA`   | No conversion (default typing)       |
| Hiragana Mode  | `あ`   | Romaji -> Hiragana conversion        |
| Katakana Mode  | `ア`   | Romaji -> Katakana conversion        |
| Alphabet Mode  | `ａＡ` | ASCII -> Full-width alphabet/numbers |

## Kanji

To install SKK dictionaries, run:

```
skkget
```

Then you can convert Hiragana to Kanji by using SKK method.

## Notes

- The plugin uses an internal Romaji-to-Kana conversion table.
- It does **not** perform Kanji conversion.
- The conversion buffer is reset when a match is found or when exiting input
  mode.
- Still under development.
- Ideal for remote environments or minimal systems without IME.

## Key Bindings

| Key       | Function                          |
| --------- | --------------------------------- |
| `Ctrl-j`  | Enter Hiragana Input Mode         |
| `l`       | Exit to Direct Mode               |
| `q`       | Toggle Hiragana <--> Katakana     |
| `L`       | Switch to Zenkaku Alphabet Mode   |

Note that use `Ctrl-j` to exit from Zenkaku Alphabet mode to Hiragana mode.

## Using SKK with the vi plugin

When using the SKK-like plugin together with the vi-like plugin for micro,
it is convenient to ensure that pressing **Esc** always does two things at
once:

1. Returns vi to **Normal mode** (also called **Command mode**)  
2. Switches SKK back to **Direct input mode**

This avoids situations where you leave Insert mode but SKK is still in a
Japanese input state, which can cause unexpected behavior.

### Recommended key bindings

Add the following entries to your `bindings.json`:

```json
{
  "Escape": "Escape,Deselect,ClearInfo,RemoveAllMultiCursors,UnhighlightSearch,lua:vi.Vi,lua:skk.SkkDirect",
  "Ctrl-[": "Escape,Deselect,ClearInfo,RemoveAllMultiCursors,UnhighlightSearch,lua:vi.Vi,lua:skk.SkkDirect"
}
```

### Why this works

- The built-in micro commands (`Escape`, `Deselect`, etc.) clear
  selections and highlights first.
- `lua:vi.Vi` then puts the vi plugin into Normal mode.
- Finally, `lua:skk.SkkDirect` ensures SKK is set to Direct input mode.
