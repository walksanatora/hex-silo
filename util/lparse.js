const str = '[[1,2,3],2,3,[[1,2,3],4,5,6,(1,2,3)],{"x":1,"y":2,"z":3},[1,2,3]]';

function parse(str) {
    var d = 0
    var output = []
    var buf = ""
    var skip = false
    for (let i = 0; i < str.length; i++) {
        const char = str[i];
        if (char == "[") {
            d += 1
            if (d == 1) {
                skip = true
            }
        } else if (char == "]") {
            d -= 1
        }
        if (char == "(" || char == "{") {
            d += 1
        } else if (char == ")" || char == "}") {
            d -= 1
        }
        if (d == 1) {
            if (char == ",") {
                output.push(buf)
                buf = ""
            } else {
                if (!skip) {
                    buf += char
                }
            }
        } else {
            if (!(skip || (char == "]" && i + 1 == str.length))) {
                buf += char
            }
        }
        skip = false
    }
    output.push(buf)
    return output
}
var p = parse(str)
console.log(p)
console.log(parse(p[3]))

