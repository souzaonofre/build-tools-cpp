fs = null
path = null
Emitter = null
Command = null
CommandInfoPane = null
CSON = null

{CompositeDisposable} = require 'atom'

notify: (message) ->
  atom.notifications?.addError message
  console.log('build-tools: ' + message)

module.exports =

  name: 'Custom Commands'

  activate: ->
    fs = require 'fs'
    path = require 'path'
    {Emitter} = require 'atom'
    Command = require '../command'
    CommandInfoPane = require '../view/command-info-pane'
    CSON = require 'season'

    @disposables = new CompositeDisposable
    @disposables = atom.views.addViewProvider @model, (project) =>
      new @view(project)
    @disposables = atom.workspace.addOpener (uritoopen) =>
      if uritoopen.endsWith '.build-tools.cson'
        atom.views.getView(new @model(path.resolve(uritoopen, '..')))

  deactivate: ->
    @disposables.dispose()
    fs = null
    path = null
    Emitter = null
    Command = null
    CommandInfoPane = null
    CSON = null

  available: (projectPath) ->
    true

  model:
    class GlobalBuildToolsProject

      constructor: (@path) ->
        @emitter = new Emitter
        @commands = []
        return if @path is ''
        filepath = path.join(@path, '.build-tools.cson')
        if fs.existsSync filepath
          try
            {commands} = CSON.readFileSync filepath
          catch error
            notify "Could not read commands from #{filepath}"
            commands = []
        else
          CSON.writeFileSync filepath, commands: []
          commands = []
        for command in commands
          command.project = @path if not command.project?
          @commands.push(new Command(command))

      destroy: ->
        @emitter.dispose()
        @emitter = null

      save: ->
        return if @path is ''
        try
          CSON.writeFileSync @path, this
        catch error
          notify "Could not write commands to #{@path}"

      addCommand: (item) ->
        if @getCommandIndex(item.name) is -1
          item['project'] = @path
          @commands.push(new Command(item))
          @emitter.emit 'change'
          return true
        else
          @notify "Command \"#{item.name}\" already exists"
          return false

      removeCommand: (name) ->
        if (i = @getCommandIndex name) isnt -1
          @commands.splice(i, 1)[0]
          @emitter.emit 'change'
          return true
        else
          @notify "Command \"#{name}\" not found"
          return false

      replaceCommand: (oldname, item) ->
        if (i = @getCommandIndex oldname) isnt -1
          item['project'] = @path
          @commands.splice(i, 1, new Command(item))
          @emitter.emit 'change'
          return true
        else
          @notify "Command \"#{oldname}\" not found"
          return false

      moveCommand: (name, offset) ->
        if (i = @getCommandIndex name) isnt -1
          @commands.splice(i + offset, 0, @commands.splice(i, 1)[0])
          @emitter.emit 'change'
          return true
        else
          @notify "Command \"#{name}\" not found"
          return false

      hasCommand: (name) ->
        return (@getCommandIndex name isnt -1)

      getCommandIndex: (name) ->
        for cmd, index in @commands
          if cmd.name is name
            return index
        return -1

      getCommandByIndex: (id) ->
        @commands[id]

      getCommand: (name) ->
        @commands[id] if (id = @getCommandIndex name) isnt -1

      getCommands: ->
        @commands

      onChange: (callback) ->
        @emitter.on 'change', callback

  view:
    class GlobalBuildToolsPane extends View

      @content: ->
        @div class: 'panel-body padded', =>
          @div class: 'inset-panel', =>
            @div class: 'panel-heading icon icon-code', =>
              @span class: 'section-header', 'Commands'
              @span id: 'add-command-button', class: 'inline-block btn btn-xs icon icon-plus', 'Add command'
            @div class: 'panel-body padded', =>
              @div class: 'command-list', outlet: 'command_list'

      initialize: (@project) ->
        @on 'click', '#add-command-button', (e) =>
          @commandPane = atom.views.getView(new Command)
          @commandPane.setCallbacks @accept, @hidePanes
          @showPane @commandPane
        @addCommands()
        @disposable = @project.onChange =>
          @project.save()
          @command_list.html('')
          @addCommands()

      setCallbacks: (@hidePanes, @showPane) ->

      destroy: ->
        @detach()
        @disposable.dispose()
        @project.destroy()

      accept: (c) =>
        @project.addCommand c

      addCommands: ->
        for command in @project.getCommands()
          pane = new CommandInfoPane(command)
          up = (command) =>
            @project.moveCommandUp(command)
          down = (command) =>
            @project.moveCommandDown(command)
          edit = (command) =>
            @project.replaceCommand(command)
          remove = (command) =>
            @project.removeCommand(command)
          pane.setCallbacks up, down, edit, remove
          @command_list.append pane
