import std/[algorithm, os, sequtils, strutils]

type ImportLine = object
  prefix*: string
  modules*: seq[string]
  comment*: string
  hasBrackets*: bool
  hasComment*: bool

const notFound = -1

func parseImport*(line: string): ImportLine =
  var parts: ImportLine

  # Strip away "import " from the front
  let importPrefixLen = "import".len
  var content = line[importPrefixLen .. high(line)].strip()

  # Extract significant indices in one pass
  var commentIdx, bracketOpenIdx, bracketCloseIdx = notFound
  for i in 0 ..< content.len:
    let ch = content[i]
    if ch == '#':
      commentIdx = i
      break # No need to parse beyond comment start
    elif ch == '[':
      if bracketOpenIdx == notFound:
        bracketOpenIdx = i
    elif ch == ']':
      # Only set bracketClose if we found an opening bracket and haven't set bracketClose
      if bracketOpenIdx != notFound and bracketCloseIdx == notFound:
        bracketCloseIdx = i

  parts.hasComment = commentIdx != notFound
  parts.hasBrackets = bracketOpenIdx != notFound

  # Extract comment and strip from line
  if parts.hasComment:
    parts.comment = content[commentIdx .. ^1]
    content = content[0 .. commentIdx - 1].strip()

  # Extract content inside brackets and store prefix
  if parts.hasBrackets:
    parts.prefix = content[0 .. bracketOpenIdx - 1].strip()
    if bracketCloseIdx != notFound:
      content = content[bracketOpenIdx + 1 .. bracketCloseIdx - 1].strip()
    else:
      # No closing bracket found, treat remainder as module content
      content = content[bracketOpenIdx + 1 .. ^1].strip()

  # Extract modules
  parts.modules = content.split(",").mapIt(it.strip())

  return parts

func sortImports*(line: string): string =
  var importStmt = parseImport(line)
  if importStmt.modules.len == 0:
    return line

  importStmt.modules.sort()

  result = "import "
  if importStmt.hasBrackets:
    if importStmt.prefix.len > 0:
      result.add(importStmt.prefix)
    result.add("[")
    result.add(importStmt.modules.join(", "))
    result.add("]")
  else:
    result.add(importStmt.modules.join(", "))

  if importStmt.hasComment:
    result.add(" ")
    result.add(importStmt.comment)

func process*(content: string): string =
  var output: seq[string]

  for line in content.splitLines:
    if line.startsWith("import") and line.strip() != "import":
      output.add(line.sortImports)
    else:
      output.add(line)

  return output.join("\n")

when isMainModule:
  if paramCount() < 1:
    echo "Usage: ", getAppFilename(), " <filename.nim>"
    quit(1)

  let inputFile = paramStr(1)
  if not fileExists(inputFile):
    echo "Error: file not found: ", inputFile
    quit(1)

  let input = readFile(inputFile)
  let output = process(input)
  writeFile(inputFile, output)
