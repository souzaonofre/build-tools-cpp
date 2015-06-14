path = require 'path'
ConsoleOutput = require '../lib/console'

describe 'Console View', ->
  [view, fixturesPath, data, input_stdout, input_stderr] = []

  data = {}
  input_stdout = [
    "test output",
    "../src/test.c:3",
    "test.c: 2: error: Something"
  ]
  input_stderr = [
    "stderr test",
    "../src/test.c:4:2: error: Something",
    "foo",
    "^",
    "stderr"
  ]

  beforeEach ->
    view = new ConsoleOutput()
    jasmine.attachToDOM(view.element)
    expect(view.hasClass('console')).toBeTruthy()
    expect(view.find('.output').hasClass('hidden')).toBeTruthy()
    fixturesPath = atom.project.getPaths()[0]
    data = {
      project: fixturesPath
      name: 'Test command',
      command: 'echo "Test"',
      wd: 'build',
      shell: false,
      wildcards: false,
      stdout: {
        file: false,
        highlighting: 'ha',
        lint: false
      }
      stderr: {
        file: true,
        highlighting: 'hc',
        lint: false
      }
    }

  afterEach ->
    view.destroy()

  describe 'When :setHeader', ->
    it 'sets the header', ->
      expect(view.find('.name').html()).toBe ''
      view.setHeader 'Test'
      expect(view.find('.name').html()).toBe 'Test'

  describe 'When :printLine', ->
    it 'prints a line', ->
      expect(view.find('.output').html()).toBe ''
      expect(view.find('.output').hasClass('hidden')).toBeTruthy()
      view.printLine 'Test'
      expect(view.find('.output').html()).toBe 'Test'
      expect(view.find('.output').hasClass('hidden')).toBeFalsy()

  describe 'Output', ->

    beforeEach ->
      atom.config.set('build-tools-cpp.SourceFileExtensions', ['.c'])

    describe 'When :createOutput', ->
      it 'creates output objects', ->
        data['path'] = fixturesPath
        expect(view.Output).toBeUndefined()
        expect(view.stdout).toBeUndefined()
        expect(view.stderr).toBeUndefined()
        view.createOutput data
        expect(view.Output).toBeDefined()
        expect(view.stdout).toBeDefined()
        expect(view.stderr).toBeDefined()

    describe 'On input', ->
      it 'correctly displays errors and warnings', ->
        view.createOutput data
        expect(view.Output).toBeDefined()
        expect(view.stdout).toBeDefined()
        expect(view.stderr).toBeDefined()
        for i in [0..2]
          view.stdout.in input_stdout[i]
        for i in [0..4]
          view.stderr.in input_stderr[i]
        view.destroyOutput()
        content = view.find('.output').children()
        expect(content.length).toBe 8
        expect(content[0].classList.contains('text-warning')).toBeTruthy()
        expect(content[1].classList.contains('text-warning')).toBeTruthy()
        expect(content[2].classList.contains('text-warning')).toBeTruthy()
        expect(content[3].classList.contains('text-error')).toBeTruthy()
        expect(content[4].classList.contains('text-error')).toBeTruthy()
        expect(content[5].classList.contains('text-error')).toBeTruthy()
        expect(content[6].classList.contains('text-error')).toBeTruthy()
        expect(content[7].classList.contains('text-error')).toBeFalsy()
        expect(content[1].children[0].innerHTML).toBe '../src/test.c:3'
        link = content[4].children[1]
        expect(link.classList.contains('filelink')).toBeTruthy()
        expect(link.attributes['name'].value).toBe path.join(fixturesPath,'src','test.c')
        expect(link.attributes['row'].value).toBe '4'
        expect(link.attributes['col'].value).toBe '2'
        expect(link.innerHTML).toBe '../src/test.c:4:2'