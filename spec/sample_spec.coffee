request = require('request')

jasmine.getEnv().defaultTimeoutInterval = 500

describe "Included matchers:", ->
  it "should respond with hello world", (done) ->
    request "http://localhost:3000/hello", (error, response, body) ->
      done()