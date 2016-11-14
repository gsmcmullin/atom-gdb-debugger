# atom-gdb-debugger package
[![apm](https://img.shields.io/apm/v/atom-gdb-debugger.svg)](https://atom.io/packages/atom-gdb-debugger)
[![deps](https://david-dm.org/gsmcmullin/atom-gdb-debugger/status.svg)](https://david-dm.org/gsmcmullin/atom-gdb-debugger)
[![devDeps](https://david-dm.org/gsmcmullin/atom-gdb-debugger/dev-status.svg)](https://david-dm.org/gsmcmullin/atom-gdb-debugger?type=dev)
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
* Inspect threads, call stacks and variables
* Set up a view of target variables
* Set watchpoints on target variables
* Assign new values to target variables

## Default key bindings (with GDB/CLI equivalents)
* `F12` Activate package and start GDB
* `F5` Resume target execution (`continue`)
* `Shift-F5` Interrupt target execution (`Ctrl-C`/`interrupt`)
* `F9` Toggle breakpoint on current line in editor (`break`/`delete`)
* `F10` Single step, over function calls (`next`)
* `F11` Single step, into function calls (`step`)
* `Shift-F11` Resume until return  of current function (`finish`)

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
