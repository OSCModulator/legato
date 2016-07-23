'use strict'

sandbox = require('./utils').sandbox
midiHelp = require('midi-help')
_ = require 'lodash'

describe 'integration', ->

  omgosc = {}
  legato = {}
  midi = {}
  osc = {}
  midiLegatoMock = {}
  utils = {}
  utilsClass = {}
  router = {}
  routerClass = {}
  midiAccess = midiAccessPromise = null

  beforeEach ->
    spyOn console, 'log' # prevent logs

    localRequire = (lib) ->
      if lib is 'lodash'
        return _
      else if lib is 'midi' or lib is './browser-midi'
        return browserMidi
      else if lib is 'omgosc'
        return omgosc
      else if lib is './legato'
        return midiLegatoMock
      else if lib is './utils'
        return utilsClass
      else if lib is './router'
        return routerClass
      else if lib is './midi'
        return midi
      else if lib is './osc'
        return osc
      else if lib is 'midi-help'
        return midiHelp
      else
        return {}

    class MockMidiInputPort
      constructor: (@name) ->
      onmidimessage: null
      close: jasmine.createSpy('MockMidiInputPort.close')

    class MockMidiOutputPort
      constructor: (@name) ->
      send: jasmine.createSpy('MockMidiOutputPort.send')
      close: jasmine.createSpy('MockMidiOutputPort.close')

    midiAccess =
      inputs: new Map [
        ['0', new MockMidiInputPort('Casio')]
        ['1', new MockMidiInputPort('Korg')]
      ]
      outputs: new Map [
        ['0', new MockMidiOutputPort('Casio')]
        ['1', new MockMidiOutputPort('Korg')]
      ]

    midiAccessPromise = Promise.resolve(midiAccess)

    browserMidi = sandbox 'lib/browser-midi.coffee',
      console: console
      window: {}
      navigator:
        requestMIDIAccess: -> midiAccessPromise

    utilsClass = sandbox( 'lib/utils.coffee',
      console: console
    )
    utils = utilsClass.utils

    routerClass = sandbox( 'lib/router.coffee',
      console: console
    )
    router = routerClass.router

    midiLegatoMock =
      ____: -> ->
        return true
      store: ->
        return true

    midi = sandbox 'lib/midi.coffee',
      console: console

    osc = sandbox 'lib/osc.coffee',
      console: console

    legato = sandbox 'lib/legato.coffee',
      console: console
      require: localRequire

  # @param id {String} The key of an imput in MidiAccess.inputs
  # @param time {int} The time in milliseconds of when the event occured
  # @param data {Array(U8int)} The midi data received
  receiveMessage = (id, time, data) ->
    event =
      data: data
      receivedTime: time
    midiAccess.inputs.get(id).onmidimessage(event)

  describe 'after creating one input', ->
    midiIn1Spy = null

    beforeEach ->
      midiIn1 = midi.In 0
      midiIn1Spy = jasmine.createSpy('midi.In', midiIn1).and.callThrough()

      legato.in midiIn1Spy

    it 'should be able to add midi listeners.', ->
      expect( midiIn1Spy ).toHaveBeenCalled()

    describe 'and adding a catch all route', ->
      testCallback = routeId = null

      beforeEach ->
        testCallback = jasmine.createSpy('testCallback')
        routeId = legato.on '/:/:/:/:', testCallback

      it 'should return an id for the route created.', ->
        expect( routeId ).toBeGreaterThan(-1)

      it 'should not call our callback yet.', ->
        expect( testCallback ).not.toHaveBeenCalled()

      it 'should call our callback.', (done) ->
        value = 120
        note = 59
        path = "/0/note/#{note}"
        message = [144, note, value]
        time = 123

        midiAccessPromise.then ->
          receiveMessage('0', time, message)
          expect( testCallback ).toHaveBeenCalledWith(value/127, "/1#{path}")
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

    describe 'and adding input and output routes', ->
      midiOut1Spy = outputMessage = null

      beforeEach ->
        midiOut1 = midi.Out 0, true
        midiOut1Spy = jasmine.createSpy('midi.Out', midiOut1).and.callThrough()

        note = 59
        channel = 0
        value = 0.5
        outputMessage = [144, note, parseInt(value*127)]
        routing = ->
          console.log 'test: routing message'
          midiOut1Spy('noteOn', note, value, channel)

        routeId = legato.on '/1/0/note/:', routing

      it 'should be able to route an input to an output.', (done) ->
        value = 120
        note = 44
        path = "/0/note/#{note}"
        message = [144, note, value]
        time = 123

        midiAccessPromise.then ->
          receiveMessage('0', time, message)
          midiAccessPromise.then ->
            expect(midiAccess.outputs.get('0').send).toHaveBeenCalledWith(outputMessage)
            done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

  describe 'with multiple inputs listening on the same port', ->
    myCallback = port1 = port2 = message = null

    beforeEach ->
      value = 120
      note = 59
      path = "/0/note/#{note}"
      message = [144, note, value]

      port1 = legato.in( midi.In(0) )
      port2 = legato.in( midi.In(0) )

      myCallback = jasmine.createSpy('myCallback')
      legato.on '/:/:/:/:', myCallback

    it 'should only execute the callback once.', (done) ->
      midiAccessPromise.then ->
        receiveMessage('0', 123, message)
        midiAccessPromise.then ->
          expect(myCallback).toHaveBeenCalled()
          expect(myCallback.calls.count()).toBe(1)
          done()
      .catch (e) ->
        expect(e).toBe(false)
        done()

    describe 'after closing the first port registered', ->
      beforeEach ->
        legato.removeInput port1

      it 'should continue to execute the callback.', (done) ->
        midiAccessPromise.then ->
          receiveMessage('0', 123, message)
          midiAccessPromise.then ->
            expect(myCallback).toHaveBeenCalled()
            expect(myCallback.calls.count()).toBe(1)
            done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

    describe 'after closing the second port registered', ->
      beforeEach ->
        legato.removeInput port2

      it 'should nolonger execute the callback.', (done) ->
        midiAccessPromise.then ->
          receiveMessage('0', 123, message)
          midiAccessPromise.then ->
            expect(myCallback).not.toHaveBeenCalled()
            done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

  describe 'with multiple named inputs listening on the same port', ->
    firstCallback = secondCallback = port1 = port2 = message = null

    beforeEach ->
      value = 120
      note = 59
      path = "/0/note/#{note}"
      message = [144, note, value]

      port1 = legato.in( 'first', midi.In(0) )
      port2 = legato.in( 'second', midi.In(0) )

      firstCallback = jasmine.createSpy('firstCallback')
      legato.on 'first/:/:/:', firstCallback

      secondCallback = jasmine.createSpy('secondCallback')
      legato.on 'second/:/:/:', secondCallback

    it 'should only execute the second callback.', (done) ->
      midiAccessPromise.then ->
        receiveMessage('0', 123, message)
        midiAccessPromise.then ->
          expect(firstCallback).not.toHaveBeenCalled()
          expect(secondCallback).toHaveBeenCalled()
          done()
      .catch (e) ->
        expect(e).toBe(false)
        done()

  xit 'should be able to route input OSC messages'

