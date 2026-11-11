import std/unittest
import ../src/nimpsort {.all.}

proc checkSorted(input, expected: string) =
  check sortImports(input) == expected
  check sortImports(expected) == expected # ensure idempotence

proc checkUnchanged(src: string) =
  checkSorted src, src

suite "sorting":
  test "plain list":
    checkSorted "import strutils, os", "import os, strutils"

  test "bracket group":
    checkSorted "import std/[os, algorithm]", "import std/[algorithm, os]"

  test "several groups":
    checkSorted "import std/[b, a], foo/[d, c]", "import foo/[c, d], std/[a, b]"

  test "nested groups":
    checkSorted "import std/[b, a/[d, c]]", "import std/[a/[c, d], b]"

  test "indented import":
    checkSorted "when defined(x):\n  import b, a\n", "when defined(x):\n  import a, b\n"

suite "multi-line imports":
  test "one item per line":
    checkSorted "import\n  b,\n  a\nx = 1", "import\n  a,\n  b\nx = 1"

  test "bracket group continued on the next line":
    checkSorted "import std/[os,\n  algorithm]", "import std/[algorithm,\n  os]"

  test "nph-style bracket group":
    checkSorted "import\n  std/[\n    b, c, a,\n    e, d\n  ]",
      "import\n  std/[\n    a, b, c,\n    d, e\n  ]"

  test "nph-style bracket group with trailing comma":
    checkSorted "import\n  std/[\n    b, c, a,\n    e, d,\n  ]",
      "import\n  std/[\n    a, b, c,\n    d, e,\n  ]"

suite "preserved formatting":
  test "trailing newline":
    checkSorted "import b, a\n", "import a, b\n"

  test "spacing inside brackets":
    checkSorted "import std/[ b,a ]", "import std/[ a,b ]"

  test "trailing comma":
    checkSorted "import b, a,", "import a, b,"

  test "comment after the list":
    checkSorted "import b, a # keep me", "import a, b # keep me"

  test "spacing before a comment":
    checkSorted "import b,a  # x", "import a,b  # x"

  test "unsafe-looking words in a comment":
    checkSorted "import z, a # except something", "import a, z # except something"

suite "untouched code":
  test "other statements":
    checkUnchanged "echo \"hi\"\nfrom os import x\n"

  test "identifiers starting with 'import'":
    checkUnchanged "importantVar = 3"
    checkUnchanged "import_x = 1"

  test "import keyword without a list":
    checkUnchanged "import\n"

  test "import inside a triple-quoted string":
    checkSorted "const s = \"\"\"\nimport b, a\n\"\"\"\nimport d, c",
      "const s = \"\"\"\nimport b, a\n\"\"\"\nimport c, d"

  test "bracket group left open by an unindented line":
    checkUnchanged "import z, std/[c,\nb]"

  test "quoted path":
    checkUnchanged "import \"z,y\", a"

  test "statement separator":
    checkUnchanged "import b, a; echo 1"

  test "pragma":
    checkUnchanged "import b, a {.all.}"

  test "except clause":
    checkUnchanged "import strutils except split, join"

  test "comment inside a multi-line import":
    checkUnchanged "import\n  c,\n  b, # about b\n  a"
