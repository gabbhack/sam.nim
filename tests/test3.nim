import ../sam
import macros

dumpTree:
  a = (name: "Peter", age: 30)


var
  sub = {"method": "POST"}
  data = $${"default": true, "requests": {"method": "POST"}}
echo data
