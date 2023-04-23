# hex-silo
a project where I abuse CC and hexcasting circles (+ ducky peripherals to tie them together)<br>
to achieve what can only be describes as "some" storage<br>
<br>
so pull iota registry run `node util/buildreg.js`<br>
to compile a hexpattern into a json run `node util/parsehex.js <hexpattern> [out.json]`<br>
so to compile circle.hexpattern you would<br>
`node util/parsehex.jx circle.hexpattern circle.json`<br>
you can then drop `hex.lua` into a cc machine along with the circle.json<br>
and then in cc run `hex circle.json`<br>
this will write circle.json to the first focal port it can connect to