'use strict'
module.exports = (grunt) ->
  grunt.initConfig

  # CONFIG
    coffee:
      lib:
        expand: yes
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'build/'
        ext: '.js'
    watch:
      lib:
        files: ['src/**/*']
        tasks: ['coffee:lib']

  # TASKS
  grunt.registerTask 'default', ['coffee:lib', 'watch']

  # PLUGINS
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
