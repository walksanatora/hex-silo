# hex-silo
a project where I abuse CC and hexcasting circles (+ ducky peripherals to tie them together)<br>
to achieve what can only be describes as "some" storage<br>
<br>
so re-build pattern registry run `node util/buildreg.js`<br>
to compile a hexpattern into a json run `node util/parsehex.js <hexpattern> [out.json]`<br>
so to compile circle.hexpattern you would<br>
`node util/parsehex.js circle.hexpattern circle.json`<br>
you can then drop `hex.lua` into a cc machine along with the circle.json<br>
and then in cc run `hex load circle.json`<br>
this will write circle.json to the first focal port it can connect to<br>
<br>
note: currently parsehex messes with number patterns (by doing a intro/retro/flock disnt.)<br>
so if you are indexing into your source code... it may get a bit messy<br>
<br><br>
notes about hexpattern format<br>
* `<Iota>`: direct insertion, no escape<br>
* `<{Iota}>`: embed with intro/retro/flock<br>
* `<\Iota>`: embed with consideration(s)<br>
* `<<Iota>>`: embed with intro or considerations, whichever is shorter<br>

currently you can use json for iotas thatdont have a pre-handled parser<br>
current types that can be parsed<br>
* Numbers (decimal and not)
* Strings ("quoted strings")
* Booleans (`true`/`false` (case sensitive))
* Vector3 (`(x,y,z)` format)
* list of iotas [iota,iota2,iota3]