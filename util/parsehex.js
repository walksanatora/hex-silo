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

function gen_num(num) {
    num = Math.floor(num);
    let pattern = "";
    let base = num < 0 ? "dedd" : "aqaa";
    num = Math.abs(num);
    while (num > 0) {
      if (num % 2 === 0) {
        num = num / 2;
        pattern += "a";
      } else if (num > 5) {
        num -= 5
        pattern += "q"
      } else {
        num -= 1;
        pattern += "w";
      }
    }
    pattern = pattern.split("").reverse().join("");
    return base + pattern;
  }
  

function getPatternFromName(line) {
    trim = line.trim()
    if (trim in registry) { //normal line...
        return registry[trim]
    } else if (trim in macroReg) { //macro line
        return macroReg[trim]
    } else if (trim.startsWith("Consideration: ")) {
        return [
            registry["Consideration"],
            getPatternFromName(trim.replace(/^Consideration: /, ''))
        ]
    } else if (trim.startsWith("Numerical Reflection: ")){
        let num = trim.replace(/^Numerical Reflection: /,'')
        //if (parseFloat(num) == parseInt(num)) {
        //    return {direction: "EAST", pattern: gen_num(parseFloat(num))}
        //} else {
            return [
                registry["Introspection"],
                parseFloat(num),
                registry["Retrospection"],
                registry["Flock's Disintegration"]
            ]
        //}
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
            console.log(pattern,mask)
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
    
        return { startDir: direction, angles: pattern }
    }
}

function parseHexpatternFile(hexpatternFilePath) {
    // Read the hexpattern file and split it into lines
    const hexpatternData = fs.readFileSync(hexpatternFilePath, 'utf-8');
    const lines = hexpatternData.replace(regex,'')
    
    while ((match = macroRegex.exec(lines)) !== null) {
        const macroName = match[1];
        const startDir = match[2];
        const patternName = match[3];
        const patternContent = match[4];
        //console.log("adding macro: "+macroName)
        macroReg[macroName] = {
            angles: patternName,
            startDir: startDir
        }
    }
    
    const content = lines.split('\n')
    // Convert each line to objects using the registry
    return content.map(line => {
        // Check if the pattern name exists in the registry
        return getPatternFromName(line)
    }).flat(Infinity).filter(v=>v!=undefined)
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
fs.writeFileSync(output,JSON.stringify(jdata))

