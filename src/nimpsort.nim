import std/[algorithm, os, strutils]

func indentWidth(line: string): int =
  line.len - line.strip(trailing = false).len

func safeToSort(importList: string): bool =
  importList.count('[') == importList.count(']') and importList.count('"') == 0 and
    importList.count(';') == 0 and importList.count('{') == 0 and
    "except" notin importList.splitWhitespace

func splitTopLevelCommas(list: string): seq[string] =
  var depth, itemStart = 0
  for idx, ch in list:
    case ch
    of '[':
      inc(depth)
    of ']':
      dec(depth)
    of ',':
      if depth == 0:
        result.add(list[itemStart ..< idx])
        itemStart = idx + 1
    else:
      discard
  result.add(list[itemStart .. ^1])

func sortCommaList(list: string): string =
  var
    rawItems = list.splitTopLevelCommas() # text between commas incl whitespace
    nonBlankIdxs: seq[int] # indices of non-blank import items
    trimmedItems: seq[string] # non-blank import items stripped of whitespace

  for idx, rawItem in rawItems:
    var item = rawItem.strip()
    if item.len == 0:
      continue

    let
      openIdx = item.find('[')
      closeIdx = item.rfind(']')

    if openIdx >= 0 and closeIdx > openIdx:
      # on foo/[bar, baz], sort the list between the brackets
      item =
        item[0 .. openIdx] & sortCommaList(item[openIdx + 1 ..< closeIdx]) &
        item[closeIdx .. ^1]
    nonBlankIdxs.add(idx)
    trimmedItems.add(item)

  trimmedItems.sort()

  for sortedIdx, rawIdx in nonBlankIdxs:
    let
      rawItem = rawItems[rawIdx]
      trimmedLeft = rawItem.strip(trailing = false)
      trimmedRight = rawItem.strip(leading = false)
      leadingSpace = rawItem[0 ..< rawItem.len - trimmedLeft.len]
      trailingSpace = rawItem[trimmedRight.len .. ^1]
    rawItems[rawIdx] = leadingSpace & trimmedItems[sortedIdx] & trailingSpace

  rawItems.join(",")

func sortImportList(importList: string): string =
  if not importList.safeToSort:
    return importList

  let commentStart = importList.find('#')
  if commentStart < 0:
    return sortCommaList(importList)
  if '\n' in importList:
    return importList # ignore comments in multi-line imports

  sortCommaList(importList[0 ..< commentStart]) & importList[commentStart .. ^1]

func sortAllImports(source: string): string =
  let lines = source.split('\n')
  var
    output: seq[string]
    inMultiLineStr = false
    currentLine = 0

  while currentLine < lines.len:
    let
      line = lines[currentLine]
      baseIndent = line.indentWidth
      unindented = line[baseIndent .. ^1]

      isImport =
        not inMultiLineStr and unindented.startsWith("import") and
        (unindented.len == "import".len or unindented["import".len] notin IdentChars)

    inc(currentLine)
    if line.count("\"\"\"") mod 2 == 1:
      inMultiLineStr = not inMultiLineStr
    if not isImport:
      output.add(line)
      continue

    # Continuation lines = indented deeper than "import"
    let keywordEnd = baseIndent + "import".len
    var importList = line[keywordEnd .. ^1]
    while currentLine < lines.len and not lines[currentLine].isEmptyOrWhitespace and
        lines[currentLine].indentWidth > baseIndent:
      importList.add("\n" & lines[currentLine])
      inc(currentLine)
    output.add(line[0 ..< keywordEnd] & sortImportList(importList))

  output.join("\n")

when isMainModule:
  if paramCount() < 1:
    echo "Usage: ", getAppFilename(), " <filename.nim> ..."
    quit(1)

  var err: bool
  for file in commandLineParams():
    if not file.fileExists():
      echo "Error: file not found: ", file
      err = true
      continue
    let
      original = file.readFile()
      updated = original.sortAllImports()
    if updated != original:
      file.writeFile(updated)
  if err:
    quit(1)
