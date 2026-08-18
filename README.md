# CMDLine

[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate/?hosted_button_id=ZDB5ZSNJNK9XQ)

CmdLine is a prompt component, which has a few extra features to fit better into
a VCL environment.

## Notice

This is a fork of the Original CMDLine from [Julian Schutsch](https://wiki.lazarus.freepascal.org/CmdLine).

Changes you can find in CHANGELOG.md

## Features

- Dynamic line length: lines which are too long are wrapped (Word wrapping or
Char wrapping)
- Independent input buffer so you can still write during input
- Input history
- Copy/paste/cut for input
- Multispace font support
- ANSI escape codes or CmdBox special escape codes (or none if you switch them
off)

## ANSI / BBS terminal mode

Set `EscapeCodeType := esctAnsi` and, for classic ANSI art, leave
`TerminalColumns := 80`. The ANSI parser is streaming: escape sequences may be
split across any number of `Write` or `WriteStream` calls, and UTF-8 text remains
intact.

Implemented terminal controls include:

- C0: BEL, backspace, horizontal tab (8-column stops), LF/VT/FF and CR
- ESC: save/restore cursor (`7`/`8`), index, reverse index, next line and reset
- CSI cursor movement/position: `A B C D E F G H f d e a` and `` ` ``
- Erase display/line: `J` and `K` modes 0, 1 and 2 (ED mode 3 clears scrollback)
- Insert/delete/erase characters: `@`, `P`, `X`; insert/delete lines: `L`, `M`
- Scroll up/down: `S`, `T`; save/restore cursor: `s`, `u`
- SGR attributes: bold, faint, italic, underline, blink, inverse, conceal and
  strikeout, including their individual reset codes
- SGR colors: normal and bright 16-color foreground/background, defaults 39/49,
  xterm 256-color (`38/48;5;n`) and 24-bit RGB (`38/48;2;r;g;b`)
- DEC private modes `?7h/l` (autowrap) and `?25h/l` (cursor visibility)

`AnsiAutoWrap`, `AnsiCursorVisible`, and `TerminalColumns` expose the relevant
terminal state. Blink is rendered by the component timer; inverse/conceal and
font attributes are applied while painting.

This is practical VT100/xterm screen-output compatibility for BBS software, not
an implementation of every control family ever standardized. OSC/DCS strings,
device-status replies, alternate-screen buffers, configurable scroll regions,
and terminal-to-host reply generation are intentionally not implemented because
`TCmdBox` currently has no transport/output channel for such replies.

