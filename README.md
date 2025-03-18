# Nimpsort

This is a simple formatting tool that alphabetically sorts import statements in Nim source files. It currently supports regular comma-separated imports, bracketed imports, and prefixed imports.

## Example

Given the file `myprog.nim`:

```nim
import std/[os, logging, tables, strutils]
import ./[common, action, config, target]
import pkg/[regex, cligen]
import sequtils, options
```

`nimpsort myprog.nim` will turn it into:

```nim
import std/[logging, os, strutils, tables]
import ./[action, common, config, target]
import pkg/[cligen, regex]
import options, sequtils
```
