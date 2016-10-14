# atom-gdb-debugger package
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/atom-gdb-debugger/Lobby)

GDB integration for Atom.

This is still very experimental and under construction.  If you try it, please
stop by the Gitter channel and let us know what you think.

## Features
* Configurable, per project
* Provides access to GDB/CLI
* Show current position in editor
* Basic run control functions accessible from UI
* Display breakpoints in editor
* Backtrace popup allows user to select frame

## Default key bindings (with GDB/CLI equivalents)
* `Ctrl-Alt-O` Starts GDB
* `F5` Resume target execution (`continue`)
* `Shift-F5` Interrupt target execution (`Ctrl-C`/`interrupt`)
* `F9` Toggle breakpoint on current line in editor (`break`/`delete`)
* `F10` Single step, over function calls (`next`)
* `F11` Single step, into function calls (`step`)
* `Shift-F11` Resume until return  of current function (`finish`)
* `Ctrl-K B` Show stack backtrace

## Installation

Atom Package: https://atom.io/packages/atom-gdb-debugger

```bash
apm install atom-gdb-debugger
```

Or Settings/Preferences ➔ Packages ➔ Search for `atom-gdb-debugger`

For development you can also clone the repository directly and install it via:
```bash
apm install
apm link .
```

