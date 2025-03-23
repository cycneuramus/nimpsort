import std/[algorithm, os, sequtils, strutils]

type ImportLine = object
  prefix: string
  modules: string
  comment: string
  hasPrefix: bool
  hasBrackets: bool
  hasComment: bool

const notFound = -1

func parseImport(line: string): ImportLine =
  var parts: ImportLine

  # Strip away "import " from the front
  let importPrefixLen = "import".len
  if line.len <= importPrefixLen:
    return parts # Malformed or empty line after "import"
  var postImport = line[importPrefixLen .. high(line)].strip()

  # Extract significant indices in one pass
  var commentIdx, lastSlashIdx, bracketOpenIdx, bracketCloseIdx = notFound
  for i in 0 ..< postImport.len:
    let ch = postImport[i]
    if ch == '#':
      commentIdx = i
      break # once we see a comment start, no need to parse further
    elif ch == '/':
      # Update lastSlashIdx each time we see '/', so in the end it's effectively rfind()
      lastSlashIdx = i
    elif ch == '[':
      if bracketOpenIdx == notFound:
        bracketOpenIdx = i
    elif ch == ']':
      # Only set bracketClose if we found an opening bracket and haven't set bracketClose
      if bracketOpenIdx != notFound and bracketCloseIdx == notFound:
        bracketCloseIdx = i

  parts.hasComment = commentIdx != notFound
  parts.hasPrefix = lastSlashIdx != notFound
  parts.hasBrackets = bracketOpenIdx != notFound

  # Extract comment and strip from line
  if parts.hasComment:
    parts.comment = postImport[commentIdx .. ^1]
    postImport = postImport[0 .. commentIdx - 1].strip()

  # Extract prefix (e.g. "foo/")
  if parts.hasPrefix:
    parts.prefix = postImport[0 .. lastSlashIdx - 1].strip()

  # Extract modules
  parts.modules =
    if parts.hasBrackets and parts.hasPrefix:
      postImport[lastSlashIdx + 2 .. ^2].strip()
    elif parts.hasBrackets:
      postImport[bracketOpenIdx + 1 .. bracketCloseIdx - 1].strip()
    elif parts.hasPrefix:
      postImport[lastSlashIdx + 1 .. ^1].strip()
    else:
      postImport

  return parts

func sortImports(line: string): string =
  let importStmt = parseImport(line)
  var modules = importStmt.modules.split(",").mapIt(it.strip())
  modules.sort()

  result = "import "
  if importStmt.hasPrefix:
    result.add(importStmt.prefix)
    result.add("/")

  if importStmt.hasBrackets:
    result.add("[")
    result.add(modules.join(", "))
    result.add("]")
  else:
    result.add(modules.join(", "))

  if importStmt.hasComment:
    result.add(" ")
    result.add(importStmt.comment)

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
    if line.startsWith("import"):
      output.add(line.sortImports)
    else:
      output.add(line)

  writeFile(inputFile, output.join("\n"))
