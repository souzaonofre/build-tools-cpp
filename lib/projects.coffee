fs = require 'fs'
_p = require 'path'

module.exports =
  class Projects
    filename: ""
    data: {}

    constructor: ->
      @getFileName()
      @touchFile()
      @getData()

    destroy: ->
      @setData()

    getFileName: ->
      @filename = _p.join(_p.dirname(atom.config.getUserConfigPath()),"build-tools-cpp.projects")

    getData: ->
      CSON = require 'season'
      @data = CSON.readFileSync @filename

    setData: ->
      CSON = require 'season'
      CSON.writeFile @filename, @data, (error) =>
        if error
          atom.notifications?.addError "Settings could not be written to #{@filename}"

    touchFile: ->
      fs.exists @filename, (exists) =>
        unless exists
          fs.writeFile @filename, '{}', (error) ->
            if error
              atom.notifications?.addError "Could not open #{@filename}"

    addProject: (path) ->
      @data[path] = {}
      @data[path]["commands"] = []
      @setData()

    addCommand: (path, item) ->
      if @data[path]?
        if @commandExists path,item is -1
          @data[path]["commands"].push(item)
          @setData()

    commandExists: (path, item) ->
      if @data[path]?
        for c,i in @data[path]["commands"]
          if c.name is item.name
            return i
        return -1
      return -1

    getCommands: (path) ->
      @data[path]["commands"]

    getProjects: ->
      (p for p in @data)

    getProject: (path) ->
      @data[path]

    setProject: (path, pdata) ->
      @data[path] = pdata

    removeCommand: (path, command) ->
      if @data[path]?
        if (i = @commandExists path,{name: command}) isnt -1
          cmds = @data[path]["commands"]
          cmds.splice(i,1)
          @setData()

    moveCommand: (path, command, offset) ->
      if @data[path]?
        if (i = @commandExists path,{name: command}) isnt -1
          cmds = @data[path]["commands"]
          cmds.splice(i+offset,0,cmds.splice(i,1)[0])
          @setData()

    getProjectPath: (path) ->
      p = path.split(_p.sep)
      i = p.length - 1
      while (i isnt 0) and (@data[p.slice(0,i).join(_p.sep)] is undefined)
        i=i-1
      @data[p.slice(0,i).join(_p.sep)]

    getKeyCommand: (path, id) ->
      if (p = @getProjectPath path)?
        p["commands"][id]
