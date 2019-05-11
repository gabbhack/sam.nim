import ../sam/utils

var fish = "This is a \\ud83d\\udc1f, yes a fish"
assert escapeString(fish) == "This is a 🐟, yes a fish"


assert escapeString("Test\"") == r"Test"""
