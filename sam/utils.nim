from parsejson import parseEscapedUTF16
from unicode import Rune, toUTF8

proc escapeString*(s: string): string =
    var buf = s.cstring
    var pos = 0
    while true:
      case buf[pos]
      of '\0':
        break
      of '"':
        add(result, '"')
        inc(pos)
      of '\\':
        case buf[pos+1]
        of '\\', '"', '\'', '/':
          add(result, buf[pos])
          inc(pos, 1)
        of 'b':
          add(result, '\b')
          inc(pos, 2)
        of 'f':
          add(result, '\f')
          inc(pos, 2)
        of 'n':
          add(result, '\L')
          inc(pos, 2)
        of 'r':
          add(result, '\C')
          inc(pos, 2)
        of 't':
          add(result, '\t')
          inc(pos, 2)
        of 'v':
          add(result, '\v')
          inc(pos, 2)
        of 'u':
          inc(pos, 2)
          var r = parseEscapedUTF16(buf, pos)
          if r < 0:
            break
          # Deal with surrogates
          if (r and 0xfc00) == 0xd800:
            if buf[pos] != '\\' or buf[pos+1] != 'u':
              break
            inc(pos, 2)
            var s = parseEscapedUTF16(buf, pos)
            if (s and 0xfc00) == 0xdc00 and s > 0:
              r = 0x10000 + (((r - 0xd800) shl 10) or (s - 0xdc00))
            else:
              break
          add(result, toUTF8(Rune(r)))
        else:
          # don't bother with the error
          add(result, buf[pos])
          inc(pos)
      else:
        add(result, buf[pos])
        inc(pos)