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

function getPatternFromName(line) {
    trim = line.trim()
    if (trim in registry) { //normal line...
        return [registry[trim], false]
    } else if (trim in macroReg) { //macro line
        return [macroReg[trim], false]
    } else if (trim.startsWith("Consideration: ")) {
        return [[
            registry["Consideration"],
            getPatternFromName(trim.replace(/^Consideration: /, ''))
        ], false]
    } else if (trim.startsWith("Numerical Reflection: ")) {
        let num = trim.replace(/^Numerical Reflection: /, '')
        return [
            registry["Introspection"],
            parseFloat(num),
            registry["Retrospection"],
            registry["Flock's Disintegration"]
        ]
    } else if (trim.startsWith("Bookkeeper's Gambit: ")) {
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
            console.log(pattern, mask)
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
    } else if (trim == "{" || trim == "}") {
        return getPatternFromName(trim == "{" ? "Introspection" : "Retrospection")
    } else if (trim.startsWith("@")) {
        json_data = trim.substring(1)
        return [JSON.parse(json_data), true]
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
        const patternContent = match[4];
        macroReg[macroName] = {
            angles: patternName,
            startDir: startDir
        }
    }

    const content = lines.split('\n')
    var output = []
    for (let i = 0; i < content.length; i++) {
        var ret = getPatternFromName(content[i])
        if (ret == undefined) { continue }
        if (!ret[1]) {
            if (Array.isArray(ret[0])) {
                ret[0] = ret[0].flat(Infinity)
            }
            output.push(ret[0])
        } else {
            output.push(ret[0])
        }
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

