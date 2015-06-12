path = require 'path'

module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-mocha-test')
  grunt.loadNpmTasks('grunt-shell')
  grunt.loadNpmTasks('grunt-coveralls')

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json'),

    coffee: {
      source: {
        expand: true,
        flatten: false,
        cwd: 'src/',
        src: ['**/*.coffee'],
        dest: 'lib/',
        ext: '.js'
      }
    },

    mochaTest: {
      test: {
        options: {
          reporter: 'spec',
          require: 'coffee-script/register'
        },
        src: ['tests/*.coffee']
      },
      coverage: {
        options: {
          reporter: 'mocha-lcov-reporter',
          require: 'coffee-script/register'
          captureFile: 'lib-cov/lcov.txt'
          quiet: true
        },
        src: ['lib-cov/*.js']
      }
    },

    shell: {
        testapp: {
          command: 'node ./tests/app/app.js'
        }

        publish: {
          command: 'npm publish'
        }

        jscover: {
          command: "#{path.join(__dirname, 'node_modules', '.bin', 'jscover')} lib lib-cov"
        }
    }

    coveralls: {
      lcov:{
        src: 'lib-cov/lcov.txt'
      }
    }


  grunt.registerTask 'test', ['coffee:source', 'mochaTest:test']
  grunt.registerTask 'testapp', ['coffee', 'shell:testapp']
  grunt.registerTask 'testci', ['coffee:source', 'shell:jscover', 'mochaTest']
  grunt.registerTask 'publish', ['coffee', 'shell:publish']
