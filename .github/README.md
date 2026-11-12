# Nimpsort

This is a small formatter that alphabetically sorts import statements in Nim source files. It supports:

- Comma-separated modules: `import sequtils, options`
- Bracketed groups: `import std/[strutils, os]`
- Multiple groups: `import std/[b, a], foo[d, c]`
- Nested groups: `import std[b, a/[d, c]]`
- Mixed styles: `std/[strutils, os], pkg/regex`
- Multi-line imports:

```nim
import
  c,
  b,
  a
```

And more (see [examples](https://github.com/cycneuramus/nimpsort#examples)).

## Usage

```
nimpsort <file1.nim> <file2.nim> ...
```

## Installation

**Using Nimble**

```bash
nimble install nimpsort
```

**Compiling from source**

```bash
nim c -d:release -o:nimpsort src/nimpsort.nim
```

**Downloading binary**

Pre-built binaries for Linux (AMD64) are available on the [release page](https://github.com/cycneuramus/nimpsort/releases).

## Examples

Before:

```nim
import sequtils, options
import std/[os, logging] # comments are preserved
import pkg/[regex, argparse], std/[sets, os], files
import std/[b, a/[d, c]]

import std/[os,
  algorithm]

import
  terminal,
  strutils,
  os

import
  std/[tables, os],
  ./[zeta, alpha],
  pkg/regex,

import
  std/[
    b, c, a,
    e, d
  ]

import std/[ b,a ]
import  d ,  c
import b, a,

when defined(posix):
  import posix, os
```

After:

```nim
import options, sequtils
import std/[logging, os] # comments are preserved
import files, pkg/[argparse, regex], std/[os, sets]
import std/[a/[c, d], b]

import std/[algorithm,
  os]

import
  os,
  strutils,
  terminal

import
  ./[alpha, zeta],
  pkg/regex,
  std/[os, tables],

import
  std/[
    a, b, c,
    d, e
  ]

import std/[ a,b ]
import  c ,  d
import a, b,

when defined(posix):
  import os, posix
```

______________________________________________________________________

## Unsupported

The following cases will remain unchanged:

```nim
# `from` statements
from os import sleep

# Quoted paths
import "z,y", a

# Statement separators
import b, a; echo "hello"

# Pragmas and other curly braces
import foo, bar {.all.}

# `except` clauses
import strutils except split, join

# Imports that don't start their line
when defined(x): import b, a

# Imports inside multi-line strings
let imports = """
import b, a
"""

# Unindented multi-line bracket group
import z, std/[c,
b]

# Closing bracket at the same indentation as `import`
import std/[
  tables,
  os
]

# Any comment in a multi-line import
import
  c,
  b, # about b
  a
```
