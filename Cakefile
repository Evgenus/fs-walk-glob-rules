fs = require("fs")
coffee = require("coffee-script")
{exec} = require 'child_process'

compile = (input, output) ->
    console.log("Compiling %s --> %s", input, output)
    source = fs.readFileSync(input, encoding: "utf8")
    compiled = coffee.compile(source, bare: true)
    fs.writeFileSync(output, compiled)

task "build", "compile all coffeescript files to javascript", ->
    compile("index.coffee", "index.js")

task "test", "run unittests", ->
    cmd = ["npm", "run", "test:short"].join(" ")
    console.log(cmd)
    exec cmd, (err, stdout, stderr) ->
        console.log stdout + stderr

task "sbuild", "build routine for sublime", ->
    invoke 'build'
    invoke 'test'
