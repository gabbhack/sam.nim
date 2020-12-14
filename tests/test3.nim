import ../deser_json/utils

var fish = "This is a \\ud83d\\udc1f, yes a fish"
assert escapeString(fish) == "This is a 🐟, yes a fish"


assert escapeString("Test\"") == r"Test"""
assert escapeString("\\/") == r"\/"
assert escapeString("\babc") == "\babc"
assert escapeString("this is a newline\\nabc") == "this is a newline\nabc"
