'use strict'

EventEmitter = require('events')
sandbox = require('./utils').sandbox
LifxClient = require('node-lifx').Client
_ = require('lodash')

class Light
  hex: '#000000'

  constructor: (@id, @label=null, @status='off', @address='0.0.0.0') ->

  colorRgbHex: jasmine.createSpy('colorRgbHex')

  getLabel: -> return @label


ddescribe 'legato.lifx-light', ->
  lifx = client = null

  beforeEach ->
    utils = sandbox( 'lib/utils.coffee', console: console ).utils
    utils.inject(_)

    client = new EventEmitter()
    client.init = jasmine.createSpy('init')
    client.lights = jasmine.createSpy('lights').andReturn([])
    client.light = jasmine.createSpy('light').andCallFake( (id) ->
      for light in client.lights()
        if light.id is id
          return light
      return null
    )

    lifx = sandbox('lib/lifx-light.coffee', console: console )
    lifx.inject( utils, client )
    return

  describe 'after initialization with a callback', ->
    initCallback = null

    beforeEach ->
      initCallback = jasmine.createSpy('initCallback')
      lifx.init( initCallback )

    it 'should initialize the Lifx client', ->
      expect(client.init).toHaveBeenCalled()

    it 'should not complete the initialization process.', ->
      expect( initCallback ).not.toHaveBeenCalled()

    describe 'and discovering a light', ->
      lights = null

      beforeEach ->
        lights = [
          new Light('1', 'foo')
        ]
        client.lights.andReturn(lights)
        client.emit('light-new', lights)

      it 'should complete the initialization process.', ->
        expect( initCallback ).toHaveBeenCalled()

      it 'should be able to retrieve the list of lights', ->
        expect( lifx.outs() ).toEqual(lights)

  describe 'after initialization without a callback', ->
    newLightCallback = null

    beforeEach ->
      newLightCallback = jasmine.createSpy('newLightCallback')
      lifx.on('light-new', newLightCallback)
      lifx.init()

    it 'should initialize the client', ->
      expect(client.init).toHaveBeenCalled()

    it 'should not notify the callback', ->
      expect(newLightCallback).not.toHaveBeenCalled()

    describe 'and discovering a light', ->
      lights = null

      beforeEach ->
        lights = [
          new Light('1', 'foo')
        ]
        client.lights.andReturn(lights)
        client.emit('light-new', lights)

      it 'should emit the event', ->
        expect(newLightCallback).toHaveBeenCalledWith(lights)

      it 'should be possible to query for the lights.', ->
        expect(lifx.outs()).toEqual(lights)

  describe 'asking for lights without first initialzing the client', ->
    xit 'should initialize the client for us.'

  describe 'after discovering some lights and configuring a sender for the first light', ->
    lights = sender = null

    beforeEach ->
      lifx.init()

      lights = [
        new Light('1', 'foo')
        new Light('2', 'bar')
        new Light('3', 'baz')
      ]
      client.lights.andReturn(lights)

      sender = lifx.Out('1')

    it 'should return a function to send color messages to.', ->
      expect(sender).toEqual( jasmine.any(Function) )

    describe 'and then setting the first lights color', ->
      beforeEach ->
        sender('#ff00ff', 500)

      it 'should send a color change message to the light.', ->
        expect(lights[0].colorRgbHex).toHaveBeenCalled()

