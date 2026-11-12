import std/[algorithm, os, strutils]

const importKeyword = "import"

func leadingSpace(str: string): string =
  str[0 ..< str.len - str.strip(trailing = false).len]

func trailingSpace(str: string): string =
  str[str.strip(leading = false).len .. ^1]

func indentWidth(line: string): int =
  line.leadingSpace.len

func safeToSort(imports: string): bool =
  imports.count('[') == imports.count(']') and not imports.contains({'"', ';', '{'}) and
    "except" notin imports.splitWhitespace

func splitImportGroups(line: string): seq[string] =
  var depth, itemStart = 0
  # Split on commas outside brackets
  for idx, ch in line:
    case ch
    of '[':
      inc(depth)
    of ']':
      dec(depth)
    of ',':
      if depth == 0:
        result.add(line[itemStart ..< idx])
        itemStart = idx + 1
    else:
      discard

  result.add(line[itemStart .. ^1])

func sortImportGroups(groups: string): string =
  var
    rawGroups = groups.splitImportGroups()
    sortedGroups: seq[string]

  for rawGroup in rawGroups:
    if rawGroup.isEmptyOrWhitespace:
      continue

    var item = rawGroup.strip()
    let
      bracketOpen = item.find('[')
      bracketClose = item.rfind(']')

    # Sort bracketed import groups recursively
    if bracketOpen >= 0 and bracketClose > bracketOpen:
      let bracketed = item[bracketOpen + 1 ..< bracketClose]
      item =
        item[0 .. bracketOpen] & sortImportGroups(bracketed) & item[bracketClose .. ^1]
    sortedGroups.add(item)

  sortedGroups.sort()

  # Restore original whitespace around each comma-separated group
  var nextGroup = 0
  for rawGroup in rawGroups.mitems:
    if rawGroup.isEmptyOrWhitespace:
      continue
    rawGroup = rawGroup.leadingSpace & sortedGroups[nextGroup] & rawGroup.trailingSpace
    inc(nextGroup)

  rawGroups.join(",")

func sortImportLines(lines: string): string =
  let
    commentStart = lines.find('#')
    (code, comment) =
      if commentStart >= 0:
        (lines[0 ..< commentStart], lines[commentStart .. ^1])
      else:
        (lines, "")

  let hasCommentInMultiline = comment.len > 0 and '\n' in lines
  if hasCommentInMultiline or not code.safeToSort:
    return lines

  code.sortImportGroups() & comment

func isImportStart(line: string): bool =
  let code = line.strip(trailing = false)
  code.startsWith(importKeyword) and
    (code.len == importKeyword.len or code[importKeyword.len] notin IdentChars)

func continuesImport(line: string, importIndent: int): bool =
  not line.isEmptyOrWhitespace and line.indentWidth > importIndent

func sortImports(source: string): string =
  let lines = source.split('\n')
  var
    output: seq[string]
    inMultiLineString = false
    nextLine = 0

  while nextLine < lines.len:
    let
      line = lines[nextLine]
      isImport = not inMultiLineString and line.isImportStart

    inc(nextLine)

    if line.count("\"\"\"") mod 2 == 1:
      inMultiLineString = not inMultiLineString
    if not isImport:
      output.add(line)
      continue

    let
      indent = line.indentWidth
      keywordEnd = indent + importKeyword.len
    var importLines = line[keywordEnd .. ^1]

    # Collect indented continuation lines belonging to this import
    while nextLine < lines.len and lines[nextLine].continuesImport(indent):
      importLines.add("\n" & lines[nextLine])
      inc(nextLine)
    output.add(line[0 ..< keywordEnd] & sortImportLines(importLines))

  output.join("\n")

when isMainModule:
  if paramCount() < 1:
    echo "Usage: ", getAppFilename().splitFile().name, " <file1.nim> <file2.nim> ..."
    quit(1)

  var err = false

  for path in commandLineParams():
    if not path.fileExists():
      echo "Error: file not found: ", path
      err = true
      continue
    let
      original = path.readFile()
      updated = original.sortImports()
    if updated != original:
      path.writeFile(updated)

  if err:
    quit(1)
