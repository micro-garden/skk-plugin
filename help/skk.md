# SKK Plugin

**SKK** is a plugin that provides a Japanese input method inspired by the
SKK.
It allows typing Japanese Hiragana, Katakana, and full-width (Zenkaku) Latin
characters **without any external input method (IME)**.

## Features

- Romaji (Latin alphabet) to Kana (Hiragana/Katakana) conversion
- Toggle between:
    - Hiragana mode
    - Katakana mode
    - Zenkaku alphabet mode (full-width Latin)
    - Direct mode (no conversion)
- Insert common Japanese punctuation (、 。 ー)
- Handles small Kana (ぁぃぅ etc.), double consonants (っ), and "ん"
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
