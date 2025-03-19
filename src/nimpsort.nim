import std/[algorithm, os, sequtils, strutils]

type ImportParts = tuple[
  prefix: string,
  modules: string,
  comment: string,
  isPrefixed: bool,
  isBracketed: bool
]

func parseImportLine(line: string): ImportParts =
  var parts: ImportParts

  # 1) Handle comment
  let cmtIdx = line.find('#')
  if cmtIdx != -1:
    parts.comment = line[cmtIdx .. ^1]
  let lineNoComment =
    if cmtIdx != -1: line[0 .. cmtIdx-1]
    else: line

  # 2) Strip away "import " from the front
  let importWord = "import"
  let startPos = importWord.len
  var mainPart = lineNoComment[startPos..^1].strip()

  # 3) Handle prefix usage (e.g. "foo/")
  let slashIdx = mainPart.rfind('/') # rfind since there may be subpaths
  parts.isPrefixed = slashIdx != -1

  if parts.isPrefixed:
    parts.prefix = mainPart[0 .. slashIdx-1].strip()
    mainPart = mainPart[slashIdx+1 .. ^1].strip()

  # 4) Handle bracket usage (e.g. foo/[bar, baz])
  let bracketOpenIdx = mainPart.find('[')
  parts.isBracketed = bracketOpenIdx != -1

  if parts.isBracketed:
    let bracketCloseIdx = mainPart.find(']', bracketOpenIdx)
    if bracketCloseIdx != -1:
      parts.modules = mainPart[bracketOpenIdx+1 .. bracketCloseIdx-1].strip()
    else:
      # In case of missing ']', treat everything from '[' onward as modules
      parts.modules = mainPart[bracketOpenIdx+1 .. ^1].strip()
  else:
    parts.modules = mainPart

  return parts

func sortImports(line: string): string =
  let parts = parseImportLine(line)
  var modules = parts.modules
    .split(",")
    .mapIt(it.strip())
  modules.sort()

  result = "import "
  if parts.isPrefixed:
    result &= parts.prefix & "/"

  if parts.isBracketed:
    result &= "[" & modules.join(", ") & "]"
  else:
    result &= modules.join(", ")

  if not parts.comment.isEmptyOrWhitespace:
    result &= " " & parts.comment

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
