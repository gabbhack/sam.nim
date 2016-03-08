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

import jsmn, strutils
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

{.push boundChecks: off, overflowChecks: off.}

template getValue*(t: JsmnToken, json: string): expr =
  ## Returns a string present of token ``t``
  json[t.start..<t.stop]

proc loads*(target: var auto, tokens: openarray[JsmnToken], numTokens: int, json: string, pos = 0)

proc loads*(target: var auto, json: string) =
  var tokens = jsmn.parseJson(json)
  target.loads(tokens, tokens.len, json)

proc loadValue[T: object|tuple](t: openarray[JsmnToken], idx: int, numTokens: int, json: string, v: var T) {.inline.} =
  loads(v, t, numTokens, json, idx)

proc loadValue(t: openarray[JsmnToken], idx: int, numTokens: int, json: string, v: var bool) {.inline.} =
  let value = t[idx].getValue(json)
  v = value[0] == 't'

proc loadValue(t: openarray[JsmnToken], idx: int, numTokens: int, json: string, v: var char) {.inline.} =
  let value = t[idx].getValue(json)
  if value.len > 0:
    v = value[0]

proc loadValue[T: int|int8|int16|int32|int64|uint|uint8|uint16|uint32|uint64|BiggestInt](t: openarray[JsmnToken], idx: int, numTokens: int, json: string, v: var T) {.inline.} =
  when v is int:
    v = parseInt(t[idx].getValue(json))
  else:
    v = (T)parseInt(t[idx].getValue(json))

proc loadValue[T: float|float32|float64|BiggestFloat](t: openarray[JsmnToken], idx: int, numTokens: int, json: string, v: var T) {.inline.} =
  when v is float:
    v = parseFloat(t[idx].getValue(json))
  else:
    v = (T)parseFloat(t[idx].getValue(json))

proc loadValue(t: openarray[JsmnToken], idx: int, numTokens: int, json: string, v: var string) {.inline.} =
  if t[idx].kind == JSMN_STRING:
    v = t[idx].getValue(json)

proc loadValue[T: enum](t: openarray[JsmnToken], idx: int, numTokens: int, json: string, v: var T) {.inline.} =
  let value = t[idx].getValue(json)
  for e in low(v)..high(v):
    if $e == value:
      v = e

proc loadValue[T: array|seq](t: openarray[JsmnToken], idx: int, numTokens: int, json: string, v: var T) {.inline.} =
  when v is array:
    let size = v.len
  else:
    let size = t[idx].size
    newSeq(v, t[idx].size)
  for x in 0..<size:
    case t[idx + 1].kind
    of JSMN_PRIMITIVE, JSMN_STRING:
      loadValue(t, idx + 1 + x, numTokens, json, v[x])
    else:
      let size = t[idx+1].size + 1
      loadValue(t, idx + 1 + x * size, numTokens, json, v[x])

template next(): expr {.immediate.} =
  if i < tokens.len:
    let next = tokens[i+1]
    if (next.kind == JSMN_ARRAY or next.kind == JSMN_OBJECT) and next.size > 0:
      let child = tokens[i+2]
      if child.kind == JSMN_ARRAY or child.kind == JSMN_OBJECT:
        inc(i, 1 + next.size * (child.size + 1))  # skip whole array or object
      else:
        inc(i, next.size + 2)
    else:
      inc(i, 2)

proc loads*(target: var auto, tokens: openarray[JsmnToken], numTokens: int, json: string, pos = 0) =
  ## Deserialize a JSON string to a `target`
  var
    i = pos + 1
    endPos: int
    key: string
    tok: JsmnToken

  assert tokens[pos].kind == JSMN_OBJECT

  endPos = tokens[pos].stop
  while i < numTokens:
    tok = tokens[i]
    # when t.start greater than endPos, the token is out of current object
    if tok.start >= endPos:
      break

    assert tok.kind == JSMN_STRING
    key = tok.getValue(json)
    for n, v in fieldPairs(target):
      if n == key:
        loadValue(tokens, i+1, numTokens, json, v)
    next()

proc parse*(json: string): JsonNode =
  ## Parse JSON string and returns a `JsonNode`
  var mapper: Mapper
  mapper.tokens = parseJson(json)
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

proc findValue(m: Mapper, key: string, pos = 0): int {.inline.} =
  result = -1
  var
    i = pos
    tok: JsmnToken
    count = m.tokens[pos].size

  assert m.tokens[pos].kind == JSMN_OBJECT

  while count > 0:
    inc(i)
    tok = m.tokens[i]

    if tok.parent == pos:
      if key == tok.getValue(m.json):
        result = i + 1
        break
      dec(count)

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
  loadValue(node.mapper.tokens, node.pos, node.mapper.numTokens, node.mapper.json, result)

proc toInt*(node: JsonNode): int {.inline.} =
  ## Retrieves the int value of a JSMN_PRIMITIVE node
  assert node.mapper.tokens[node.pos].kind == JSMN_PRIMITIVE
  loadValue(node.mapper.tokens, node.pos, node.mapper.numTokens, node.mapper.json, result)

proc toFloat*(node: JsonNode): float {.inline.} =
  ## Retrieves the float value of a JSMN_PRIMITIVE node
  assert node.mapper.tokens[node.pos].kind == JSMN_PRIMITIVE
  loadValue(node.mapper.tokens, node.pos, node.mapper.numTokens, node.mapper.json, result)

proc toBool*(node: JsonNode): bool {.inline.} =
  ## Retrieves the bool value of a JSMN_PRIMITIVE node
  assert node.mapper.tokens[node.pos].kind == JSMN_PRIMITIVE
  loadValue(node.mapper.tokens, node.pos, node.mapper.numTokens, node.mapper.json, result)

proc toObj*[T](n: JsonNode): T {.inline.} =
  ## Map a JSMN_OBJECT node into a Nim object
  loads(result, n.mapper.tokens, n.mapper.numTokens, n.mapper.json, n.pos)

iterator items*(n: JsonNode): JsonNode =
  ## Iterator for the items of an array node
  assert n.mapper.tokens[n.pos].kind == JSMN_ARRAY
  var
    i = 0
    node = new(JsonNode)
    tokens = n.mapper.tokens

  while i < n.mapper.tokens[n.pos].size:
    let child = n.mapper.tokens[n.pos + 1]
    if child.kind == JSMN_ARRAY or child.kind == JSMN_OBJECT:
      node.pos = n.pos + 1 + (1 + child.size) * i
    else:
      node.pos = n.pos + i
    node.mapper = n.mapper
    yield node
    next()

iterator pairs*(n: JsonNode): tuple[key: string, val: JsonNode] =
  ## Iterator for the child elements of an object node
  assert n.mapper.tokens[n.pos].kind == JSMN_OBJECT
  var
    i = n.pos + 1
    tok: JsmnToken
    key: string
    val = new(JsonNode)
  let
    endPos = n.mapper.tokens[n.pos].stop
    tokens = n.mapper.tokens

  while i < n.mapper.numTokens:
    tok = n.mapper.tokens[i]
    if tok.start >= endPos:
      raise newException(FieldError, key & " is not accessible")

    key = tok.getValue(n.mapper.json)
    val.pos = i + 1
    val.mapper = n.mapper
    yield (key, val)

    next()

proc dumps*[T](t: T, x: var string) =
  ## Serialize `t` into `x`
  when t is object or t is tuple:
    x.add "{"
    var i = 0
    for n, v in fieldPairs(t):
      inc(i)
    for n, v in fieldPairs(t):
      dec(i)
      x.add "\"" & n & "\""
      x.add ":"
      dumps(v, x)
      if i > 0:
        x.add ','
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
    when t is seq:
      if t == nil:
        x.add "null"
        return

    x.add "["
    var i = t.len
    for e in t:
      dec(i)
      dumps(e, x)
      if i > 0:
        x.add ","
    x.add "]"
  elif t is enum:
    x.add "\"" & $t & "\""
  else:
    x.add $t

proc dumps*[T](t: T): string =
  ## Serialize `t` to a JSON formatted string
  result = newStringOfCap(sizeof(t) shl 1)
  dumps(t, result)

{.pop.}
