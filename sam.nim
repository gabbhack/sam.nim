# Copyright 2016 Huy Doan
#
# This file is a Nim fork of Jsmn: https://github.com/zserge/jsmn
# Copyright (c) 2010 Serge A. Zaitsev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


## Fast and just works JSON-Binding for Nim (requires `Jsmn <https://github.com/OpenSystemsLab/jsmn.nim>`_)
##
## This module is to celebrate 100 days old of Sam - my second princess
##
## Installation
## ============
##.. code-block::
##  nimble install sam
##

import jsmn, strutils, macros
from json import escapeJson

type
  Mapper = object
    tokens: seq[JsmnToken]
    json: string
    numTokens: int
    stack: seq[int]

  JsonNode* = ref object
    mapper: Mapper
    pos: int

  JsonRaw* {.borrow: `.`.} = distinct string

{.push boundChecks: off, overflowChecks: off.}

template getValue*(t: JsmnToken, json: string): expr =
  ## Returns a string present of token ``t``
  json[t.start..<t.stop]

proc `$`*(n: JsonNode): string =
  getValue(n.mapper.tokens[n.pos], n.mapper.json)

proc loads(target: var bool, m: Mapper, idx: int) {.inline.} =
  assert m.tokens[idx].kind == JSMN_PRIMITIVE
  let value = m.tokens[idx].getValue(m.json)
  target = value[0] == 't'

proc loads(target: var char, m: Mapper, idx: int) {.inline.} =
  assert m.tokens[idx].kind == JSMN_STRING
  let value = m.tokens[idx].getValue(m.json)
  if value.len > 0:
    target = value[0]

proc loads[T: SomeInteger|BiggestInt](target: var T, m: Mapper, idx: int) {.inline.} =
  assert m.tokens[idx].kind == JSMN_PRIMITIVE
  let value = m.tokens[idx].getValue(m.json)
  when T is int:
    target = parseInt(value)
  else:
    target = (T)parseInt(value)

proc loads[T: SomeReal|BiggestFloat](target: var T, m: Mapper, idx: int) {.inline.} =
  assert m.tokens[idx].kind == JSMN_PRIMITIVE
  when T is float:
    target = parseFloat(m.tokens[idx].getValue(m.json))
  else:
    target = (T)parseFloat(m.tokens[idx].getValue(m.json))

proc loads(target: var string, m: Mapper, idx: int) {.inline.} =
  if m.tokens[idx].kind == JSMN_STRING:
    target = m.tokens[idx].getValue(m.json)

proc loads[T: enum](target: var T, m: Mapper, idx: int) {.inline.} =
  assert m.tokens[idx].kind == JSMN_STRING
  let value = m.tokens[idx].getValue(m.json)
  for e in low(T)..high(T):
    if $e == value:
      target = e
      break

proc loads[T: array|seq](target: var T, m: Mapper, idx: int) {.inline.} =
  assert m.tokens[idx].kind == JSMN_ARRAY
  when T is seq:
    if target.isNil:
      newSeq(target, m.tokens[idx].size)

  var
    i = idx + 1
    x = 0
    tok: JsmnToken
    count = m.tokens[idx].size
    kind = m.tokens[i].kind

  while x < count:
    tok = m.tokens[i]
    when defined(verbose):
      echo i, " ", tok.parent, " ", idx, " ", tok, " ", getValue(tok, m.json)
    if tok.parent != idx:
      inc(i)
      continue
    case kind
    of JSMN_PRIMITIVE, JSMN_STRING:
      loads(target[x], m, i)
      inc(i)
    else:
      loads(target[x], m, i)
      inc(i, tok.size)
    inc(x)

iterator children(m: Mapper, parent = 0): tuple[token: JsmnToken, pos: int] {.noSideEffect.} =
  var
    i = parent
    tok: JsmnToken
    count = m.tokens[parent].size

  assert m.tokens[parent].kind == JSMN_OBJECT
  while count > 0:
    inc(i)
    tok = m.tokens[i]

    if tok.parent == parent:
      yield (tok, i)
      dec(count)

proc findValue(m: Mapper, key: string, pos = 0): int {.inline, noSideEffect.} =
  result = -1
  for node in m.children(pos):
    if key == node.token.getValue(m.json):
      result = node.pos + 1
      break

proc loads(target: var JsonNode, m: Mapper, idx: int) {.inline.} =
  new(target)
  target.mapper = m
  target.pos = idx


proc loads*[T: object|tuple](target: var T, m: Mapper, pos = 0) {.inline.} =
  ## Deserialize a JSON string to `target`
  when defined(verbose):
    debugEcho m.tokens[pos], " ", getValue(m.tokens[pos], m.json)
  assert m.tokens[pos].kind == JSMN_OBJECT
  var
    i = pos + 1
    tok: JsmnToken
    count = m.tokens[pos].size
    key: string
    match: bool

  while count > 0:
    match = false
    tok = m.tokens[i]
    if tok.parent == pos:
      assert tok.kind == JSMN_STRING
      key = tok.getValue(m.json)
      for n, v in fieldPairs(target):
        if n == key:
          match = true
          try:
            when compiles(loads(v, m, i+1)):
              loads(v, m, i + 1)
          except:
            when defined(verbose):
              echo tok, getValue(m.tokens[i+1], m.json)
            raise newException(ValueError, "error while parsing " & n & ", reason: " & getCurrentExceptionMsg())
          break
      if match:
        inc(i, tok.size+2)
      else:
        inc(i, 2)
      dec(count, 2)
    else:
      inc(i)

proc loads*[T: ref](target: T, m: Mapper, pos = 0) {.inline.} =
  loads(target[], m, pos)

proc loads*(target: var auto, n: JsonNode) {.inline.} =
  loads(target, n.mapper, n.pos)

proc loads*(target: var auto, json: string) =
  var mapper: Mapper
  mapper.tokens = jsmn.parseJson(json)
  mapper.numTokens = mapper.tokens.len
  mapper.json = json
  mapper.stack = @[]
  loads(target, mapper)

proc parse*(json: string): JsonNode =
  # Parse JSON string and returns a `JsonNode`
  var mapper: Mapper
  mapper.tokens = jsmn.parseJson(json)
  mapper.numTokens = mapper.tokens.len
  mapper.json = json
  mapper.stack = @[]

  new(result)
  result.mapper = mapper

proc parse*(json: string, tokens: seq[JsmnToken], numTokens: int): JsonNode =
  ## Load a parsed JSON tokens and returns a `JsonNode`
  var mapper: Mapper
  mapper.tokens = tokens
  mapper.numTokens = numTokens
  mapper.json = json
  mapper.stack = @[]

  new(result)
  result.mapper = mapper

proc `[]`*(n: JsonNode, key: string): JsonNode {.inline, noSideEffect.} =
  ## Get a field from a json object, raises `FieldError` if field does not exists
  assert n.mapper.tokens[n.pos].kind == JSMN_OBJECT
  n.mapper.stack.add(n.pos)
  result = n
  result.pos = n.mapper.findValue(key, n.pos)

proc `[]`*(n: JsonNode, idx: int): JsonNode {.inline, noSideEffect.} =
  ## Get a field from json array, raises `IndexError` if array is empty or index out of bounds
  assert n.mapper.tokens[n.pos].kind == JSMN_ARRAY
  n.mapper.stack.add(n.pos)
  result = n
  if n.mapper.tokens[n.pos].size <= 0:
    raise newException(IndexError, "index out of bounds")
  let child = n.mapper.tokens[n.pos + 1]
  if idx == 0:
    result.pos = n.pos + 1
  else:
    if child.kind == JSMN_ARRAY or child.kind == JSMN_OBJECT:
      result.pos = n.pos + 1 + (1 + child.size) * idx
    else:
      result.pos = n.pos + idx

proc `{}`*(n: JsonNode, i: int): JsonNode {.inline.} =
  ## Traveral back the selection stack
  var
    i = i
    pos: int
  while i > 0:
    pos = n.mapper.stack.pop()
    dec(i)
  result = n
  result.pos = pos

proc `{}`*(n: JsonNode): JsonNode {.inline.} =
  ## Return the root node
  result = n
  result.pos = 0

proc len*(n: JsonNode): int =
  ## Returns the number of elements in a json array
  assert n.mapper.tokens[n.pos].kind == JSMN_ARRAY
  n.mapper.tokens[n.pos].size

proc hasKey*(n: JsonNode, key: string): bool =
  ## Checks if field exists in object
  assert n.mapper.tokens[n.pos].kind == JSMN_OBJECT
  var pos = -1
  try:
    pos = n.mapper.findValue(key, n.pos)
  except FieldError:
    discard
  result = pos >= n.pos

proc toStr*(node: JsonNode): string {.inline.} =
  ## Retrieves the string value of a JSMN_STRING node
  assert node.mapper.tokens[node.pos].kind == JSMN_STRING
  loads(result, node.mapper, node.pos)

proc toInt*(node: JsonNode): int {.inline.} =
  ## Retrieves the int value of a JSMN_PRIMITIVE node
  assert node.mapper.tokens[node.pos].kind == JSMN_PRIMITIVE
  loads(result, node.mapper, node.pos)

proc toFloat*(node: JsonNode): float {.inline.} =
  ## Retrieves the float value of a JSMN_PRIMITIVE node
  assert node.mapper.tokens[node.pos].kind == JSMN_PRIMITIVE
  loads(result, node.mapper, node.pos)

proc toBool*(node: JsonNode): bool {.inline.} =
  ## Retrieves the bool value of a JSMN_PRIMITIVE node
  assert node.mapper.tokens[node.pos].kind == JSMN_PRIMITIVE
  loads(result, node.mapper, node.pos)

proc toObj*[T](n: JsonNode): T =
  ## Map a JSMN_OBJECT node into a Nim object
  when result is ref:
    new(result)
  loads(result, n.mapper, n.pos)

iterator items*(n: JsonNode): JsonNode =
  ## Iterator for the items of an array node
  assert n.mapper.tokens[n.pos].kind == JSMN_ARRAY
  var
    i = n.pos + 1
    node = new(JsonNode)
    count = n.mapper.tokens[n.pos].size

  node.mapper = n.mapper

  while count > 0:
    if n.mapper.tokens[i].parent == n.pos:
      dec(count)
      node.pos = i
      yield node
    inc(i)

iterator pairs*(n: JsonNode): tuple[key: string, val: JsonNode] =
  ## Iterator for the child elements of an object node
  assert n.mapper.tokens[n.pos].kind == JSMN_OBJECT
  var
    i = n.pos + 1
    tok: JsmnToken
    key: string
    val = new(JsonNode)
    count = n.mapper.tokens[n.pos].size

  val.mapper = n.mapper
  while count > 0:
    if n.mapper.tokens[i].parent == n.pos:
      key = tok.getValue(n.mapper.json)
      val.pos = i + 1
      inc(i, 2)
      dec(count, 2)
      yield (key, val)
    else:
      inc(i)

proc dumps*(t: auto, x: var string) =
  ## Serialize `t` into `x`
  when t is object or t is tuple:
    var first = true
    x.add "{"
    for n, v in fieldPairs(t):
      if first:
        first = false
      else:
        x.add ","
      x.add "\"" & n & "\""
      x.add ":"
      dumps(v, x)
    x.add "}"
  elif t is string:
    if t == nil:
        x.add "null"
        return
    x.add escapeJson(t)
  elif t is char:
    x.add "\"" & $t & "\""
  elif t is bool:
    if t:
      x.add "true"
    else:
      x.add "false"
  elif t is array or t is seq:
    var first = true
    when compiles(t == nil):
        if t == nil:
          x.add "null"
          return
    x.add "["
    for e in t:
      if first:
        first = false
      else:
        x.add ","
      dumps(e, x)
    x.add "]"

  elif t is enum:
    x.add "\"" & $t & "\""
  elif t is ref or t is pointer:
    dumps(t[], x)
  elif t is JsonRaw:
    x.add t.string
  else:
    x.add $t

proc dumps*(t: auto): string =
  ## Serialize `t` to a JSON formatted
  result = newStringOfCap(sizeof(t) shl 1)
  dumps(t, result)

proc `%`*(x: auto): JsonRaw {.inline.} =
  ## Convert `x` to a raw json string (JsonRaw is not wrapped when added to json string)
  (JsonRaw)dumps(x)

proc stringify(x: NimNode, top = false): NimNode {.compileTime.} =
  var left, right: NimNode
  echo x.kind
  case x.kind
  of nnkBracket:
    result = newNimNode(nnkBracket)
    for i in 0 .. <x.len:
      result.add(stringify(x[i]))
  of nnkTableConstr:
    result = newNimNode(nnkPar)
    for i in 0 .. <x.len:
      assert x[i].kind == nnkExprColonExpr
      if x[i][0].kind == nnkStrLit:
        left = newIdentNode(strVal(x[i][0]))
      else:
        left = x[i][0]
      right = stringify(x[i][1])
      result.add(newNimNode(nnkExprColonExpr).add(left).add(right))
  of nnkPar:
    result = newNimNode(nnkBracket)
    for i in 0 .. <x.len:
      result.add prefix(stringify(x[i]), "%")
  else:
    result = x
  if top:
    result = newCall(newIdentNode("dumps"), result)

macro `$$`*(x: expr): expr =
  ## Convert anything to a json stirng
  stringify(x, true)

{.pop.}

proc isObject*(n: JsonNode): bool =
  n.mapper.tokens[n.pos].kind == JSMN_OBJECT

proc isArray*(n: JsonNode): bool =
  n.mapper.tokens[n.pos].kind == JSMN_ARRAY

proc isString*(n: JsonNode): bool =
  n.mapper.tokens[n.pos].kind == JSMN_STRING

proc isPrimitive*(n: JsonNode): bool =
  n.mapper.tokens[n.pos].kind == JSMN_PRIMITIVE
