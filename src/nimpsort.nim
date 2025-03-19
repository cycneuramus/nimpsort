import std/[algorithm, os, strutils]
import pkg/regex

proc sortImports(line: string): string =
  ## If the line is an `import` statement, sort its modules alphabetically.
  ## Otherwise return line unchanged.

  # 1) Match lines starting with "import ..." (skips commented lines)
  var m = RegexMatch2()
  let importLineRe = re2"^\s*import\s+(.*)$"
  if not match(line, importLineRe, m):
    return line

  # Everything after "import" is in group(0)
  var importPart = line[m.group(0)]

  # 2) Extract inline comments
  let commentIndex = importPart.find('#')
  var comment: string
  if commentIndex != -1:
    comment = importPart[commentIndex..^1]
    importPart = importPart[0..<commentIndex].strip()

  # 3) Handle bracketed imports, e.g. "std/[os, strutils]"
  var m2 = RegexMatch2()
  let bracketRe = re2"^(.*)\[([^\]]+)\](.*)$"
  if match(importPart, bracketRe, m2):
    # group(0) => prefix (before '[')
    # group(1) => inside brackets
    # group(2) => suffix (after ']')

    let prefix = importPart[m2.group(0)]
    let inside = importPart[m2.group(1)]
    # let suffix = restText[m2.group(2)] # no use for this currently

    var modules = inside.split(",")
    for i in 0 .. modules.high:
      modules[i] = modules[i].strip()
    modules.sort()

    result = "import " & prefix & "[" & modules.join(", ") & "]"
  else:
    # 4) No brackets => comma‐separated modules
    var modules = importPart.split(",")
    for i in 0 .. modules.high:
      modules[i] = modules[i].strip()
    modules.sort()

    result = "import " & modules.join(", ")

  # 5) Reattach inline comments if applicable
  if comment.len > 0:
    result &= " " & comment

when isMainModule:
  if paramCount() < 1:
    echo "Usage: ", getAppFilename(), " <filename.nim>"
    quit(1)

  let inputFile = paramStr(1)
  if not fileExists(inputFile):
    echo "Error: file not found: ", inputFile
    quit(1)

  var output: seq[string]
  for line in lines(inputFile):
    let sorted = sortImports(line)
    output.add(sorted)

  writeFile(inputFile, output.join("\n"))
