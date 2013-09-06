module.exports = (grunt) ->
  grunt.initConfig
  
    pkg: grunt.file.readJSON('package.json')
    
    coffeelint:
      options:
        no_backticks:
          level: "ignore"
      app: ['./*.coffee', 'scripts/*.coffee']
    
    jasmine:
      src: '*/*.coffee'
      options:
        specs: 'spec/*spec.coffee'
        helpers: 'spec/*helper.js'

    watch:
      scripts:
        files: '*.coffee'
        tasks: ['coffeelint']
        options:
          interrupt: true
               
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-contrib-jasmine')
  grunt.loadNpmTasks('grunt-contrib-watch')
  
  grunt.registerTask 'default', 'Log some stuff.', () ->
    grunt.log.write('Logging some stuff...').ok()