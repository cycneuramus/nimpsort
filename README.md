# Nimpsort

This is a simple formatting tool that alphabetically sorts top-level import statements in Nim source files. It currently supports regular comma-separated imports, bracketed imports, and prefixed imports. It will also preserve (and properly align) postfix comments, if any.

## Installation

`nimble install nimpsort`

## Example

Given the file `myprog.nim`:

```nim
import std/[os, logging, tables, strutils]
import ./[common, action, target, config] # aligned comment
import pkg/[regex, cligen]# misaligned comment
import sequtils, options  # another one
```

`nimpsort myprog.nim` will turn it into:

```nim
import std/[logging, os, strutils, tables]
import ./[action, common, config, target] # aligned comment
import pkg/[cligen, regex] # misaligned comment
import options, sequtils # another one
```

**NOTE**: `nimpsort` does not currently support, but will ignore, multi-line import statements:

```nim
import
  terminal,
  strutils,
  os
```
