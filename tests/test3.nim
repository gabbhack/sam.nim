import ../sam
import macros, json

var
  sub = {"method": "POST"}

var hisName = "John"
let herAge = 31
var k = $$[
    {
      "name": hisName,
      "age": sub
    },
    {
      "name": "Susan",
      "age": sub
    }
  ]
#echo $${"default": true, "requests": {"method": "POST"}}
#echo $${"default": true, "requests": sub}
#echo $${"method": "POST"}
#echo $$("name": "Peter", "age": ("method": "POST"))
#echo $$("name": "Peter", "age": 30)
echo k
