//script that parses a .hexpattern file and turns it into json
//I feel like i am missing something
const fs = require('fs')
const registry = require('../data/registry.json')
const { exit } = require('process')

//regex for removing comments/ detecting macros
const regex = /\/\*[\s\S]*?\*\/|\/\/.*/g
const macroRegex = /#define (.+) \(([\w]+) ([qawed]+)\)/g
const whiteSpace = /^[\s]+/

const macroReg = {}

//trash code be warned
function parseList(str) {
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

function parseIotaData(iota) {
    try {
        var iotav = JSON.parse(iota)
        return iotav
    } catch (SyntaxError) {
        if (/^\[.*\]$/.test(iota)) { //list parser
            return parseList(iota).map(i => parseIotaData(i))
        } else if (iota.match(/([1234567890\.]+),([1234567890\.]+),([1234567890\.]+)/)) { //vector constant
            match = iota.match(/([1234567890\.]+),([1234567890\.]+),([1234567890\.]+)/)
            return { x: parseFloat(match[1]), y: parseFloat(match[2]), z: parseFloat(match[3]) }
        }
    }
}

function parseIotaMethod(iota, depth) {
    if (iota.match(/<<([^>]+)>>/)) {
        const iotad = iota.match(/<<([^>]+)>>/)[1]
        if (depth >= 2) {//consideration is *bad*
            return [
                registry["Introspection"],
                parseIotaData(iotad),
                registry["Retrospection"],
                registry["Flock's Gambit"],
            ]
        } else {
            const repeatedArr = Array(2 ** depth).fill(registry["Consideration"]);
            const resultArr = [
                ...repeatedArr,
                parseIotaData(iotad)
            ]
            return resultArr
        }
    } else if (iota.match(/<{([^>]+?)}>/)) {
        return [
            registry["Introspection"],
            parseIotaData(iota.match(/<{([^>]+?)}>/)[1]),
            registry["Retrospection"],
            registry["Flock's Gambit"],
        ]
    } else if (iota.match(/<\\([^>]+)>/)) {
        const repeatedArr = Array(2 ** depth).fill(registry["Consideration"]);
        const resultArr = [
            ...repeatedArr,
            parseIotaData(iota.match(/<\\([^>]+)>/)[1])
        ]
        return resultArr
    } else {
        return [parseIotaData(iota.match(/<([^>]+)>/)[1])]
    }
}

function getPatternFromName(line, depth) {
    trim = line.trim()
    if (trim in registry) { //normal line...
        dchange = trim == "Introspection" ? 1 : 0
        dchange += trim == "Retrospection" ? -1 : 0
        return [registry[trim], false, dchange]
    } else if (trim in macroReg) { //macro line
        return [macroReg[trim], false, 0]
    } else if (trim.startsWith("Consideration: ")) { // Consider the following
        return getPatternFromName(trim.replace(/^Consideration: /, ''), depth)
    } else if (trim.startsWith("Numerical Reflection: ")) { // Numbers are a pain so we just Iota embed them
        let num = trim.replace(/^Numerical Reflection: /, '')
        return [[
            registry["Introspection"],
            parseFloat(num),
            registry["Retrospection"],
            registry["Flock's Disintegration"]
        ], false, 0]
    } else if (trim.startsWith("Bookkeeper's Gambit: ")) { // bookkeepers is easy enough to generate
        const mask = trim.replace(/^Bookkeeper's Gambit: /, '')
        var direction, pattern
        if (mask[0] == "v") {
            direction = "SOUTH_EAST";
            pattern = "a";
        } else {
            direction = "EAST";
            pattern = "";
        }

        for (let i = 0; i < mask.length - 1; i++) {
            const previous = mask[i];
            const current = mask[i + 1];
            switch (previous + current) {
                case "--":
                    pattern += "w";
                    break;
                case "-v":
                    pattern += "ea";
                    break;
                case "v-":
                    pattern += "e";
                    break;
                case "vv":
                    pattern += "da";
                    break;
            }
        }

        return [{ startDir: direction, angles: pattern }, false]
    } else if (trim == "{" || trim == "}") { //Intro/Retro shorthands
        return [registry[trim == "{" ? "Introspection" : "Retrospection"], false, trim == "{" ? 1 : -1]
    } else if (trim.match(/<([^\s>]+)>/)) { //Iota handler
        return [parseIotaMethod(trim, depth), false, 0]
    }
}

function parseHexpatternFile(hexpatternFilePath) {
    // Read the hexpattern file and split it into lines
    const hexpatternData = fs.readFileSync(hexpatternFilePath, 'utf-8');
    const lines = hexpatternData.replace(regex, '')

    while ((match = macroRegex.exec(lines)) !== null) {
        const macroName = match[1];
        const startDir = match[2];
        const patternName = match[3];
        macroReg[macroName] = {
            angles: patternName,
            startDir: startDir
        }
    }

    const content = lines.split('\n')
    var output = []
    var depth = 0
    for (let i = 0; i < content.length; i++) {
        if (content[i].trim() === "") { continue }
        var ret = getPatternFromName(content[i], depth)
        if (ret == undefined) { console.warn("Failed to parse pattern: " + content[i]); continue }
        if (!ret[1]) {
            if (Array.isArray(ret[0])) {
                output = output.concat(ret[0])
            } else {
                output.push(ret[0])
            }
        } else {
            output.push(ret[0])
        }
        depth += ret[2] ?? 0

    }
    return output
}

if (process.argv.length < 3) {
    console.error("usage: node parsehex.js <hexpattern> [out.json]")
    exit()
}

const jdata = parseHexpatternFile(process.argv[2])

console.log(
    jdata
)

const output = process.argv[3] != undefined ? process.argv[3] : "out.json"
fs.writeFileSync(output, JSON.stringify(jdata))

