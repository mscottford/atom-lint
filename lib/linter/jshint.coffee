{Range} = require 'atom'
CommandRunner = require '../command-runner'
parseString = require('xml2js').parseString

module.exports =
class JsHint
  constructor: (@filePath) ->

  run: (callback) ->
    runner = new CommandRunner(@constructCommand())
    runner.run (error, result) =>
      return callback(error) if error?
      # JSHint returns an exit code of 2 when everything worked, but the check failed.
      if result.exitCode == 0 || result.exitCode == 2
        parseString result.stdout, (xmlError, result) =>
          return callback(xmlError) if xmlError?
          callback(null, @parseJsHintResultToViolations(result))
      else
        callback(new Error("Process exited with code #{result.exitCode}"))

  parseJsHintResultToViolations: (jsHintResults) ->
    violations = []
    return violations if not jsHintResults.checkstyle.file?
    for violation in jsHintResults.checkstyle.file[0].error
      # JSHint only returns one point instead of a range, so we're going to set
      # both sides of the range to the same thing.
      point = [violation.$.line, violation.$.column]
      violations.push
        severity: violation.$.severity
        message: violation.$.message
        bufferRange: new Range(point, point)
    violations

  constructCommand: ->
    command = []
    userJsHintPath = atom.config.get('atom-lint.jshint.path')
    if userJsHintPath?
      command.push(userJsHintPath)
    else
      command.push('jshint')
    command.push('--reporter=checkstyle')
    command.push(@filePath)
    command
