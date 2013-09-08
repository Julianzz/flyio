async         = require 'async'
fs            = require 'fs'
{print}       = require 'util'
{spawn, exec} = require 'child_process'

build = (watch, callback) ->
  if typeof watch is 'function'
    callback = watch
    watch = false
  options = ['-c', '-o', 'lib', 'src']
  options.unshift '-w' if watch

  coffee = spawn 'coffee', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) -> callback?() if status is 0

task 'docs', 'Generate annotated source code with Docco', ->
  fs.readdir 'src', (err, contents) ->
    files = ("src/#{file}" for file in contents when /\.coffee$/.test file)
    docco = spawn 'docco', files
    docco.stdout.on 'data', (data) -> print data.toString()
    docco.stderr.on 'data', (data) -> print data.toString()
    docco.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Compile CoffeeScript source files', ->
  build()

task 'watch', 'Recompile CoffeeScript source files when modified', ->
  build true

task 'pretest', "Install test dependencies", ->
  exec 'which ruby gem', (err) ->
    throw "ruby not found" if err

    exec 'ruby -rubygems -e \'require "rack"\'', (err) ->
      if err
        exec 'gem install rack', (err, stdout, stderr) ->
          throw err if err

task 'test', 'Run the Pow test suite', ->
  build ->
    process.env["RUBYOPT"]  = "-rubygems"
    process.env["NODE_ENV"] = "test"

    {reporters} = require 'nodeunit'
    process.chdir __dirname
    reporters.default.run ['test']
    
task 'start', 'Start pow server', ->
  build true
  options = [ '-w', 'lib', 'server.coffee' ]
  coffee = spawn 'nodemon', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) -> callback?() if status is 0



