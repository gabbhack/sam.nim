import macros
import ../deser_json

type
  Student = object
    name: string
    age: int
    points: seq[int]
    friends: seq[Student]
    x: array[2, int]

let js = """{"name": "John ", "age": 30, "points": [], "friends": [{"name": "Bob 😂😐😱❤️😩🤞🏿🤞🏿🙏"}, {"name": "Peter", "age": 8}]}"""

var j = parse(js)
let n = j["friends"][1]
echo n.hasKey("age")
echo n["age"].toInt

var f: Student
f.name = "Smith"
f.age = 40
f.points = @[]
var s: Student
s.name = "John Doe"
s.age = 20
s.points = @[1, 2, 3, 4, 5]

var f1, f2: Student
echo dumps(s)

var k: Student
k.loads(js)

f1 = j["friends"][0].to(Student)
echo "f1 ", j
echo "f1: ", dumps(f1)

var friends = j["friends"]

f2 = friends[0].to(Student)

assert f1 == f2

echo "f2: ", dumps(f2)
echo getTotalMem(), ", ", getOccupiedMem(), ", ", getFreeMem()
