import macros
import ../deser_json

type
    Bar = object
        id: int32
var b1, b2: Bar
b1.id = 123
b2.loads(b1.dumps())
