# Romaji Plugin

**Romaji** is a plugin that provides a Japanese input method inspired by the
SKK.
It allows typing Japanese Hiragana and Katakana without relying on an external
input method (IME).

## Features

- Romaji (Latin alphabet) to Kana (Hiragana/Katakana) conversion
- Toggle between Hiragana and Katakana modes
- Insert common Japanese punctuation (、 。 ー)
- Handles small Kana (ぁぃぅ etc.), double consonants (っ), and "ん"
- Input buffer is shown in the info bar
- Minimalist and terminal-friendly design

## Usage

### Start Romaji Input Mode

Press: `Ctrl-j`

Or run the command:

```
romaji
```

This switches to **Hiragana input mode** by default.

### Exit to Direct Input Mode

Type: `l`

This cancels Kana input and returns to normal typing (Latin characters).

### Switch between Hiragana and Katakana

Type: `q`

This toggles between Hiragana and Katakana modes.

### Input Examples

| Input | Output (Hiragana) | Output (Katakana) |
| ----- | ----------------- | ----------------- |
| aiueo | あいうえお        | アイウエオ        |
| kana  | かな              | カナ              |
| nn    | ん                | ン                |
| kko   | っこ              | ッコ              |
| , . - | 、 。 ー          | Same              |

## Notes

- The plugin uses an internal Romaji-to-Kana conversion table.
- It does **not** perform Kanji conversion.
- The conversion buffer is reset when a match is found or when exiting input
  mode.

## Key Bindings

| Key    | Action                         |
| ------ | ------------------------------ |
| Ctrl-j | Start Romaji (Kana) input mode |
| l      | Exit to direct input mode      |
| q      | Toggle Hiragana/Katakana       |
