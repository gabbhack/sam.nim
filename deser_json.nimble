import strformat

# Package

version       = "0.2.1"
author        = "gabbhack"
description   = "JSON-Binding for deser"
license       = "MIT"

skipDirs      = @["tests"]

# Dependencies
requires "nim >= 1.4.2, jsmn >= 0.2, deser >= 0.1.3"

# Tasks

task pretty, "Pretty source code":
  echo "Pretty deser_json"
  exec "nimpretty deser_json --indent:2"
  for i in listFiles("deser_json"):
    echo fmt"Pretty {i}"
    exec fmt"nimpretty {i} --indent:2"

task test, "Run tests":
  exec "nim check deser_json"
  exec """testament p "tests/*.nim""""

task docs, "Generate docs":
  rmDir "docs"
  exec "nimble doc2 --outdir:docs --project --git.url:https://github.com/gabbhack/deser_json --git.commit:master --index:on deser_json"
  exec "testament html"
  mvFile("testresults.html", "docs/testresults.html")
