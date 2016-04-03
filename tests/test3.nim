import ../sam

var sub = {
  "method": "POST",
  "path": "/hello"
}

echo $${"default": true, "requests": {"method": "POST"}}
echo $${"default": true, "requests": sub}
echo $${"method": "POST"}

var
  a = 1
  b = "asd"

echo $$(a, b)
echo $$[1,2,3,4]
