import sam

type
  Foo = ref object
    text: string
  Test = object
    foo: Foo

let json = """{"foo":{"text":"123"}}"""

var t: Test
# new t.foo
loads(t, json)
assert t.foo.text == "123"
assert $$t == json