## master

- ADD: complete IBM CP437 byte decoding for DOS ANSI/BBS artwork
- ADD: `ApplyAnsiBBSDefaults` with configurable crisp fixed-pitch VGA font
- ADD: CP437 codec and live `TCmdBox` integration regression tests
- ADD: xterm mouse tracking modes 9, 1000, 1002 and 1003
- ADD: legacy X10 and SGR 1006 mouse reports via `OnAnsiMouseReport`
- ADD: ANSI mouse reports for buttons, drag/hover motion, modifiers and wheel
- ADD: regression tests for mouse tracking state and exact wire encoding
- ADD: streaming ANSI/VT100/xterm parser for BBS terminal output
- ADD: cursor positioning, erase/insert/delete/scroll controls and C0 handling
- ADD: combinable SGR text attributes with visible blinking and font rendering
- ADD: 16-color, xterm 256-color and true-color foreground/background support
- ADD: ANSI autowrap, cursor visibility and configurable terminal columns
- ADD: parser regression tests for split sequences, parameters and recovery
- ADD: ANSI Color Codes for brighter Colors
- CHANGE: make stringbuffer public
- FIX: devision by zero
- ADD: property VerticalScrollbarVisible (boolean) to disable scrollbars
