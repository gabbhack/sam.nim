# Package

version       = "0.1.0"
author        = "gabbhack"
description   = "JSON-Binding for deser"
license       = "MIT"

skipDirs      = @["tests"]

# Dependencies
requires "nim >= 1.4.2, jsmn >= 0.2, deser >= 0.1.1"

# Tasks

task test, "Run tests":
  exec "nim check deser_json"
  exec """testament p "tests/*.nim""""

task docs, "Generate docs":
  rmDir "docs"
  exec "nimble doc2 --outdir:docs --project --index:on deser_json"
  exec "testament html"
  mvFile("testresults.html", "docs/testresults.html")
