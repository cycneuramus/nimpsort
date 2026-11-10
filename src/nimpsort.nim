import std/[algorithm, os, strutils]

func isImportStmt(line: string): bool =
  line.startsWith("import") and (line.len == 6 or line[6] notin IdentChars)

func splitBracketGroups(stmt: string): seq[string] =
  var depth, start = 0
  for idx, char in stmt:
    case char
    of '[':
      inc(depth)
    of ']':
      dec(depth)
    of ',':
      if depth == 0:
        result.add(stmt[start ..< idx])
        start = idx + 1
    else:
      discard
  result.add(stmt[start .. ^1])

func sortBracketGroups(stmt: string): string =
  var
    impItems = stmt.splitBracketGroups() # text between commas (incl whitespace)
    filledItems: seq[int] # indices of non-blank import items
    impNames: seq[string] # trimmed text of import items

  for idx, item in impItems:
    var name = item.strip()
    if name.len == 0:
      continue

    let
      openIdx = name.find('[')
      closeIdx = name.rfind(']')

    if openIdx >= 0 and closeIdx > openIdx:
      # on foo/[bar, baz], sort what's between foo/[]
      name =
        name[0 .. openIdx] & sortBracketGroups(name[openIdx + 1 ..< closeIdx]) &
        name[closeIdx .. ^1]
    filledItems.add(idx)
    impNames.add(name)

  impNames.sort()

  for sortedPos, itemIdx in filledItems:
    let
      item = impItems[itemIdx]
      leftTrimmed = item.strip(trailing = false)
      rightTrimmed = item.strip(leading = false)
      padBefore = item[0 ..< item.len - leftTrimmed.len]
      padAfter = item[rightTrimmed.len .. ^1]
    impItems[itemIdx] = padBefore & impNames[sortedPos] & padAfter

  impItems.join(",")

func sortImports*(line: string): string =
  let
    body = line["import".len .. ^1]
    commentIdx = body.find('#')

  if commentIdx < 0:
    return "import" & sortBracketGroups(body)
  "import" & sortBracketGroups(body[0 ..< commentIdx]) & body[commentIdx .. ^1]

func process*(content: string): string =
  var output: seq[string]

  for line in content.splitLines():
    if line.isImportStmt and line.strip() != "import":
      output.add(line.sortImports())
    else:
      output.add(line)

  return output.join("\n")

when isMainModule:
  if paramCount() < 1:
    echo "Usage: ", getAppFilename(), " <filename.nim>"
    quit(1)

  var err: bool
  for file in commandLineParams():
    if not file.fileExists():
      echo "Error: file not found: ", file
      err = true
      continue
    let
      input = file.readFile()
      output = input.process()
    if output != input:
      writeFile(file, output)
  if err:
    quit(1)
