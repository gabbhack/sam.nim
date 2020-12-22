import macros, options
import ../deser_json

type
  Foo = object
    bar: string
  Test = object
    foo: Option[Foo]

var t: Test
var b = Test(foo: some(Foo(bar: "123")))
loads(t, """{"foo": {"bar": "123"}}""")
assert t == b
assert t.dumps() == """{"foo":{"bar":"123"}}"""
t.foo = none(Foo)
assert t.dumps() == """{"foo":null}"""
var a = t.dumps().parse().to(Test)
assert a.foo.isNone()
