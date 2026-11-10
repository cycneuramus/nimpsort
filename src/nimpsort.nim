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
  var groups: seq[string]

  for bracketGroup in stmt.splitBracketGroups():
    var group = bracketGroup.strip()
    if group.len == 0:
      continue

    let
      openIdx = group.find('[')
      closeIdx = group.rfind(']')

    if openIdx >= 0 and closeIdx > openIdx:
      group =
        group[0 .. openIdx] & sortBracketGroups(group[openIdx + 1 ..< closeIdx]) &
        group[closeIdx .. ^1]
    groups.add(group)

  groups.sort()
  groups.join(", ")

func sortImports*(line: string): string =
  let
    body = line["import".len .. ^1]
    commentIdx = body.find('#')

  if commentIdx < 0:
    return "import " & sortBracketGroups(body)
  "import " & sortBracketGroups(body[0 ..< commentIdx]) & " " & body[commentIdx .. ^1]

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
