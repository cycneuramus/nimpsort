import std/[algorithm, os, sequtils, strutils]

type Import = object
  prefix*: string
  modules*: seq[string]
  comment*: string
  hasBrackets*: bool
  hasComment*: bool

const notFound = -1

func parseImport*(line: string): Import =
  var imp: Import

  # Strip away "import " from the front
  let importPrefixLen = "import".len
  var content = line[importPrefixLen .. line.high()].strip()

  # Extract significant indices in one pass
  var commentIdx, bracketOpenIdx, bracketCloseIdx = notFound
  for i in 0 ..< content.len:
    let char = content[i]
    case char
    of '#':
      commentIdx = i
      break # No need to parse beyond comment start
    of '[':
      if bracketOpenIdx == notFound:
        bracketOpenIdx = i
    of ']':
      # Only set bracketClose if we found an opening bracket and haven't set bracketClose
      if bracketOpenIdx != notFound and bracketCloseIdx == notFound:
        bracketCloseIdx = i
    else:
      discard

  imp.hasComment = commentIdx != notFound
  imp.hasBrackets = bracketOpenIdx != notFound

  # Extract comment and strip from line
  if imp.hasComment:
    imp.comment = content[commentIdx .. ^1]
    content = content[0 .. commentIdx - 1].strip()

  # Extract content inside brackets and store prefix
  if imp.hasBrackets:
    imp.prefix = content[0 .. bracketOpenIdx - 1].strip()
    if bracketCloseIdx != notFound:
      content = content[bracketOpenIdx + 1 .. bracketCloseIdx - 1].strip()
    else:
      # No closing bracket found, treat remainder as module content
      content = content[bracketOpenIdx + 1 .. ^1].strip()

  # Extract modules
  imp.modules = content.split(",").mapIt(it.strip())

  return imp

func sortImports*(line: string): string =
  var imp = line.parseImport()
  if imp.modules.len == 0:
    return line

  imp.modules.sort()

  result = "import "
  if imp.hasBrackets:
    if imp.prefix.len > 0:
      result.add(imp.prefix)
    result.add("[")
    result.add(imp.modules.join(", "))
    result.add("]")
  else:
    result.add(imp.modules.join(", "))

  if imp.hasComment:
    result.add(" ")
    result.add(imp.comment)

func process*(content: string): string =
  var output: seq[string]

  for line in content.splitLines():
    if line.startsWith("import") and line.strip() != "import":
      output.add(line.sortImports())
    else:
      output.add(line)

  return output.join("\n")

when isMainModule:
  if paramCount() < 1:
    echo "Usage: ", getAppFilename(), " <filename.nim>"
    quit(1)

  let inputFile = paramStr(1)
  if not inputFile.fileExists():
    echo "Error: file not found: ", inputFile
    quit(1)

  let input = inputFile.readFile()
  let output = input.process()
  writeFile(inputFile, output)
