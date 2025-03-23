import std/unittest
import ../src/nimpsort

suite "Testing parseImport":
  test "simple, single module, no brackets, no comment":
    let line = "import strutils"
    let result = parseImport(line)

    check(not result.hasBrackets)
    check(not result.hasComment)
    check(result.prefix == "")
    check(result.modules == @["strutils"])

  test "multiple modules, no brackets, no comment":
    let line = "import tables, strutils, os"
    let result = parseImport(line)

    check(not result.hasBrackets)
    check(not result.hasComment)
    check(result.prefix == "")
    check(result.modules == @["tables", "strutils", "os"])

  test "with brackets, no comment":
    let line = "import std/[os, logging, tables, strutils]"
    let result = parseImport(line)

    check(result.hasBrackets)
    check(not result.hasComment)
    check(result.prefix == "std/")
    check(result.modules == @["os", "logging", "tables", "strutils"])

  test "with brackets, with comment":
    let line = "import std/[os, logging, tables, strutils] # let's do this"
    let result = parseImport(line)

    check(result.hasBrackets)
    check(result.hasComment)
    check(result.prefix == "std/")
    check(result.comment == "# let's do this")
    check(result.modules == @["os", "logging", "tables", "strutils"])

  test "with bracket prefix that is a relative path":
    let line = "import ./nmgr/[common, action]"
    let result = parseImport(line)

    check(result.hasBrackets)
    check(not result.hasComment)
    check(result.prefix == "./nmgr/")
    check(result.modules == @["common", "action"])

  test "comma-separated modules plus trailing comment, no brackets":
    let line = "import std/terminal, pkg/cligen, ./testing # final"
    let result = parseImport(line)

    check(not result.hasBrackets)
    check(result.hasComment)
    check(result.prefix == "")
    check(result.comment == "# final")
    check(result.modules == @["std/terminal", "pkg/cligen", "./testing"])

suite "Testing sortImports":
  test "simple single module remains the same":
    let line = "import strutils"
    check sortImports(line) == "import strutils"

  test "multiple modules, no brackets, gets sorted":
    let line = "import tables, os, strutils"
    check sortImports(line) == "import os, strutils, tables"

  test "multiple bracketed modules get sorted":
    let line = "import std/[tables, strutils, logging, os]"
    check sortImports(line) == "import std/[logging, os, strutils, tables]"

  test "bracket with comment still gets sorted properly":
    let line = "import std/[tables, strutils, logging, os] # a comment"
    check sortImports(line) == "import std/[logging, os, strutils, tables] # a comment"

  test "no brackets but multi modules including a relative path, with comment":
    let line = "import std/terminal, pkg/cligen, ./testing # final"
    check sortImports(line) == "import ./testing, pkg/cligen, std/terminal # final"

  test "multiple modules with a relative prefix, scrambled":
    let line = "import zeta, ./foo, alpha, ../bar, Beta, beta"
    check sortImports(line) == "import ../bar, ./foo, Beta, alpha, beta, zeta"

  test "multi-line import statements are left untouched":
    let input =
      """
import
  tables,
  strutils,
  os
      """

    check process(input) == input
