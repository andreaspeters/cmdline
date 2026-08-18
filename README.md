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
- xterm mouse modes `?9h/l`, `?1000h/l`, `?1002h/l`, `?1003h/l` and
  SGR extended coordinates `?1006h/l`

`AnsiAutoWrap`, `AnsiCursorVisible`, and `TerminalColumns` expose the relevant
terminal state. Blink is rendered by the component timer; inverse/conceal and
font attributes are applied while painting.

### CP437 and classic ANSI BBS appearance

DOS BBS art is normally a byte stream in IBM code page 437, not UTF-8. Use the
one-call preset before writing an ANSI file or network stream:

```pascal
CmdBox1.AnsiBBSFontName := 'PxPlus IBM VGA8'; // preferred when installed
CmdBox1.AnsiBBSFontSize := 12;
CmdBox1.ApplyAnsiBBSDefaults;
CmdBox1.WriteStream(AnsiFileStream);
```

`ApplyAnsiBBSDefaults` enables ANSI parsing and `ateCP437`, selects an 80-column
character-wrapped terminal, applies black/silver terminal colors, and requests a
fixed-pitch non-antialiased font. Font selection prefers `AnsiBBSFontName`, then
tries `Perfect DOS VGA 437`, `Terminus`, `DejaVu Sans Mono`, `Courier New`, and
`Monospace` from the fonts installed on the host. Installing an IBM VGA-style
font such as `PxPlus IBM VGA8` gives the most authentic 8x16-era appearance;
the fallback fonts still render all Unicode box-drawing and block characters.

The full CP437 high-byte range is converted to Unicode, including single and
double borders, shade characters, half/full blocks, accented letters, Greek and
mathematical symbols. `WriteStream` preserves raw bytes so `.ANS` files decode
correctly. Existing applications remain compatible because `ateUTF8` is still
the default; set `AnsiTextEncoding := ateCP437` directly when only byte decoding
is required without changing colors or font settings.

### ANSI mouse reports

Assign `OnAnsiMouseReport` to forward terminal-to-host mouse bytes to your
connection. The callback receives complete xterm reports, including the ESC
byte. For example:

```pascal
procedure TMainForm.CmdBoxAnsiMouseReport(ACmdBox: TCmdBox;
  const AReport: string);
begin
  TerminalTransport.WriteBuffer(AReport[1], Length(AReport));
end;
```

The remote application selects the tracking level using DECSET/DECRST:

- `?9` reports button presses only (X10 compatibility)
- `?1000` reports presses, releases and the mouse wheel
- `?1002` additionally reports motion while a button is held
- `?1003` reports all motion
- `?1006` uses SGR reports and supports coordinates beyond the legacy
  single-byte range

Reports use 1-based, visible-terminal coordinates and include Shift, Alt and
Ctrl modifiers. While tracking is active, mouse input belongs to the terminal;
when it is disabled, the component's existing local text selection remains
unchanged. Legacy reports outside their representable 223-column/row range are
suppressed; terminals that can exceed that range should enable `?1006`.

This is practical VT100/xterm screen-output compatibility for BBS software, not
an implementation of every control family ever standardized. OSC/DCS strings,
device-status replies, alternate-screen buffers and configurable scroll regions
are intentionally not implemented. Mouse reports are the one supported
terminal-to-host response family and are exposed through `OnAnsiMouseReport`;
the application remains responsible for transporting those bytes.

