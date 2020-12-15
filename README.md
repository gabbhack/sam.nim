# Deser JSON

**deser_json is a JSON serialization and deserialization library built on top of deser.**

- [JSON API documentation](https://gabbhack.github.io/deser_json/)
- [Deser documentation](https://deser.nim.town/)

## Installation
```
nimble install https://github.com/gabbhack/deser_json
```

or

```nim
requires "nim >= 1.4.2, https://github.com/gabbhack/deser_json >= 0.2.0"
```

## Usage

### Untyped

```nim
import deser_json

const js = """
  {
    "id": 123,
    "text": "hello"
  }
"""

echo js.parse()["id"]
echo js.parse()["text"]
```

### To object

```nim
import macros
import deser_json

type
  Foo = object
    id: int
    text: string

const js = """
  {
    "id": 123,
    "text": "hello"
  }
"""

var a = js.parse().to(Foo)

# or

var b: Foo
b.loads(js)
```

### From object

```nim
import macros
import deser_json

type
  Foo = object
    id: int
    text: string

let f = Foo(id: 123, text: "Hello")

echo f.dumps()
```

