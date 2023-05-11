//simple nodejs script to download the hex pattern registry and pop it in data/
const fs = require('fs');

if (!fs.existsSync("./data")) {
  fs.mkdirSync("./data");
}

fetch("https://raw.githubusercontent.com/object-Object/vscode-hex-casting/main/src/data/registry.json")
  .then(data => data.json())
  .then(reg => {
    console.log(reg)
    output = {}
    for (var k in reg) {
      output[k] = { angles: reg[k].pattern, startDir: reg[k].direction }
      console.log("Pattern: " + k)
    }
    fs.writeFile("./data/registry.json", JSON.stringify(output), (error) => {
      if (error) {
        console.error(error);
      } else {
        console.log('Data written to file');
      }
    })
  })
  .catch(error => console.error(error));