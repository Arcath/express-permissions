module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-mocha-test')
  grunt.loadNpmTasks('grunt-shell')

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
      }
    },

    shell: {
        testapp: {
            command: 'node ./tests/app/app.js'
        }
    }


  grunt.registerTask 'test', ['coffee:source', 'mochaTest']
  grunt.registerTask 'testapp', ['coffee', 'shell:testapp']
