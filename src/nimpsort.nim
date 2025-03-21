import std/[algorithm, os, sequtils, strutils]

type ImportParts =
  tuple[
    prefix: string,
    modules: string,
    comment: string,
    isPrefixed: bool,
    isBracketed: bool,
    isCommented: bool,
  ]

func parseImportLine(line: string): ImportParts =
  var parts: ImportParts

  # 1) Strip away "import " from the front
  let importPrefixLen = "import".len
  if line.len <= importPrefixLen:
    return parts # Malformed or empty line after "import"
  var postImport = line[importPrefixLen .. high(line)].strip()

  # 2) Extract significant indices in one pass
  var commentIdx, lastSlashIdx, bracketOpenIdx, bracketCloseIdx: int = -1
  for i in 0 ..< postImport.len:
    let ch = postImport[i]
    if ch == '#':
      commentIdx = i
      break # once we see a comment start, no need to parse further
    elif ch == '/':
      # Update lastSlashIdx each time we see '/', so in the end it's effectively rfind()
      lastSlashIdx = i
    elif ch == '[':
      if bracketOpenIdx == -1:
        bracketOpenIdx = i
    elif ch == ']':
      # Only set bracketClose if we found an opening bracket earlier and haven't set bracketClose yet
      if bracketOpenIdx != -1 and bracketCloseIdx == -1:
        bracketCloseIdx = i

  parts.isCommented = commentIdx != -1
  parts.isPrefixed = lastSlashIdx != -1
  parts.isBracketed = bracketOpenIdx != -1

  # 3) Extract comment and strip from line
  if parts.isCommented:
    parts.comment = postImport[commentIdx .. ^1]
    postImport = postImport[0 .. commentIdx - 1].strip()

  # 4) Extract prefix (e.g. "foo/")
  if parts.isPrefixed:
    parts.prefix = postImport[0 .. lastSlashIdx - 1].strip()

  # 5) Extract modules
  if parts.isBracketed and parts.isPrefixed:
    parts.modules = postImport[lastSlashIdx + 2 .. ^2].strip()
  elif parts.isBracketed:
    parts.modules = postImport[bracketOpenIdx + 1 .. bracketCloseIdx - 1].strip()
  elif parts.isPrefixed:
    parts.modules = postImport[lastSlashIdx + 1 .. ^1].strip()
  else:
    parts.modules = postImport

  return parts

func sortImports(line: string): string =
  let parts = parseImportLine(line)

  var modules = parts.modules.split(",").mapIt(it.strip())
  modules.sort()

  result = "import "
  if parts.isPrefixed:
    result.add(parts.prefix)
    result.add("/")

  if parts.isBracketed:
    result.add("[")
    result.add(modules.join(", "))
    result.add("]")
  else:
    result.add(modules.join(", "))

  if parts.isCommented:
    result.add(" ")
    result.add(parts.comment)

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
