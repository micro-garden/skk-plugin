# SKK Plugin for Micro

**SKK** is a plugin for the
[micro](https://micro-editor.github.io/) text editor that provides a Japanese
input method inspired by the SKK.  
It allows typing Japanese Hiragana, Katakana, and full-width (Zenkaku) Latin
characters **without any external input method (IME)**.  
Hiragana can be converted to Kanji by using SKK dictionaries.

See [help/skk.md](help/skk.md) for more details.

## Installation

Place the plugin folder in `~/.config/micro/plug/skk/`, or clone it
directly from the GitHub repository:

```sh
mkdir -p ~/.config/micro/plug
git clone https://github.com/akikareha/micro-skk-plugin ~/.config/micro/plug/skk
```

Alternatively, this plugin is also available through the unofficial plugin
channel:  
https://github.com/akikareha/micro-unofficial-plugin-channel  
You can install it by adding the channel and then using `plugin install`.

## License

MIT.

## Author

Aki Kareha (aki@kareha.org)
