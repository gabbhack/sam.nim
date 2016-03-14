import ../sam

var sub = {
  "method": "POST",
  "path": "/hello"}

echo $${"default": true, "requests": {"method": "POST"}}
echo $${"default": true, "requests": sub}
echo $${"method": "POST"}
