import ../sam, strutils

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

echo "====================================="


let json = "{ \"a\": [1, 2, 3, 4], \"b\": \"asd \\\"\", \"c\": \"\\ud83c\\udf83\", \"d\": \"\\u00E6\"}"
echo json

let testJson = parse(json)



# make sure UTF-16 decoding works.
echo testJson["b"].toStr
echo testJson["c"].toStr
doAssert(testJson["c"].toStr == "🎃")
doAssert(testJson["d"].toStr == "æ")