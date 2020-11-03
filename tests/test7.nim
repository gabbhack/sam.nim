import options
import ../sam

type
  Foo = object
    bar: string
  Test = object
    foo: Option[Foo]

var t: Test
var b = Test(foo: some(Foo(bar: "123")))
loads(t, """{"foo": {"bar": "123"}}""")
assert t == b
assert $$t == """{"foo":{"bar":"123"}}"""
t.foo = none(Foo)
assert $$t == """{"foo":null}"""
