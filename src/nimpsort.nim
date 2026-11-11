import std/[algorithm, os, strutils]

func shouldSort(stmt: string): bool =
  stmt.count('[') == stmt.count(']') and stmt.count('"') == 0 and stmt.count(';') == 0 and
    stmt.count('{') == 0 and "except" notin stmt.splitWhitespace

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

func sortImport(stmt: string): string =
  if not stmt.shouldSort:
    return stmt

  let commentIdx = stmt.find('#')
  if commentIdx < 0:
    return sortBracketGroups(stmt)
  if '\n' in stmt:
    return stmt # ignore comments in multi-line imports

  sortBracketGroups(stmt[0 ..< commentIdx]) & stmt[commentIdx .. ^1]

func process(content: string): string =
  var
    output: seq[string]
    inString = false
    idx = 0
  let lines = content.split('\n')

  while idx < lines.len:
    let
      line = lines[idx]
      code = line.strip(trailing = false)
      indent = line.len - code.len
      isImport =
        not inString and code.startsWith("import") and
        (code.len == "import".len or code["import".len] notin IdentChars)

    inc(idx)
    if line.count("\"\"\"") mod 2 == 1:
      inString = not inString
    if not isImport:
      output.add(line)
      continue

    # Continuation lines = indented deeper than "import"
    var stmt = line[indent + "import".len .. ^1]
    while idx < lines.len and lines[idx].strip().len > 0 and
        lines[idx].len - lines[idx].strip(trailing = false).len > indent:
      stmt.add("\n" & lines[idx])
      inc(idx)
    output.add(line[0 ..< indent + "import".len] & sortImport(stmt))

  output.join("\n")

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
