'use strict'

module.exports = (grunt) ->
  coffeelint = require './coffeelint.json'

  # configurable paths
  yeomanConfig =
    app: 'lib'
    dist: 'dist'
    test: 'spec'

  grunt.initConfig
    yeoman: yeomanConfig

    jasmine_nodejs:
      options:
        specNameSuffix: 'spec.coffee'
        traceFatal: 2
        reporters:
          console:
            verbosity: 1
      unit:
        specs: ['spec/node/**']

    karma:
      unit:
        configFile: 'karma.conf.js'

    coffeelint:
      options: coffeelint
      gruntfile:
        files:
          src: ['Gruntfile.coffee']
      lib:
        files:
          src: ['<%= yeoman.app %>/{,*/}*.coffee']
      test:
        files:
          src: ['<%= yeoman.test %>/{,*/}*.coffee']

    watch:
      lib:
        files: ['<%= yeoman.app %>/{,*/}*.coffee']
        tasks: [
          'coffeelint:lib'
        ]
      'unit-watch':
        files: [
          '<%= yeoman.app %>/{,*/}*.coffee'
          '<%= yeoman.test %>/{,*/}*.coffee'
        ]
        tasks: [
          'coffeelint:test'
          'coffeelint:lib'
          'test'
        ]

  require('load-grunt-tasks')(grunt)

  grunt.registerTask('unit-watch', ['test', 'watch:unit-watch'])

  grunt.registerTask('test', ['jasmine_nodejs:unit'])

  grunt.registerTask('test-browser', ['karma:unit'])

  grunt.registerTask('default', ['coffeelint', 'jasmine_node'])

