XRegExp = require('xregexp').XRegExp

module.exports =
  class Profile
    name: ''

    scopes: []

    regex_string: null

    constructor: ->
      extensions_raw = []
      extensions = []
      @scopes.forEach (scope) =>
        if (grammar = atom.grammars.grammarForScopeName(scope))?
          extensions_raw = extensions_raw.concat(grammar.fileTypes)

      for extension in extensions_raw
        extensions.push extension.replace(/[.?*+^$[\]\\(){}|-]/g, '\\$&')

      extensions = '(' + extensions.sort().reverse().join('|') + ')'
      @regex_string = @regex_string.replace('(?extensions)', extensions)
      @regex = new XRegExp(@regex_string,'xni')

    in: (line) ->
      if @regex?
        XRegExp.exec(line, @regex)

    clear: ->
      return
