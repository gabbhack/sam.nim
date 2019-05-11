import ../sam, strutils

type
  Person = object
    id: int
    firstName: string
    lastName: string
    address: string
    phoneNumber*: string
    userId*: int
    vcard*: string

var p: Person
p.id = 1
p.firstName = "Tony"
p.lastName = "Stark"
p.address = "Hollywood"
p.phoneNumber = "do I care about this?"
p.userId = 1337

proc snakeCaseConverter(s: string): string =
    if s == "kind":
        return "type"
    if s == "fromUser":
        return "from"

    result = newStringOfCap(s.len + 5)
    for c in s:
        if c in {'A'..'Z'}:
            result.add("_")
            result.add(c.toLowerAscii)
        else:
            result.add(c)

assert dumps(p, snakeCaseConverter) == """{"id":1,"first_name":"Tony","last_name":"Stark","address":"Hollywood","phone_number":"do I care about this?","user_id":1337,"vcard":null}"""