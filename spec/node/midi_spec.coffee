'use strict'

sandbox = require('./utils').sandbox
_ = require 'lodash'
midiHelp = require 'midi-help'
rtMidiMock = {}

describe 'legato.midi', ->
  router = {}
  midi = {}
  utils = {}

  beforeEach ->
    rtMidiMockGlobals =
      exports:{}
      console: console
      spyOn: spyOn
      jasmine: jasmine

    sandbox('spec/node/rtMidiMock.coffee', rtMidiMockGlobals)
    rtMidiMock = rtMidiMockGlobals.exports.rtMidiMock

    utils = sandbox( 'lib/utils.coffee',
      console: console
    ).utils
    utils.inject _

    router = sandbox( 'lib/router.coffee',
      console: console
    ).router
    router.inject utils

    midi = sandbox 'lib/midi.coffee',
      console: console
    midi.inject router, utils, rtMidiMock, midiHelp

    spyOn console, 'log' # prevent logging

  it 'should be able to return the list of available midi input ports.', ->
    inputs = midi.ins()
    expect(inputs).toBeDefined()
    expect(inputs.length).toBe 2, 'It should return an array of inputs.'
    expect(inputs[0]).toBe 'port1', 'It should have returned the correct port name.'

  it 'should be able to return the list of available midi output ports.', ->
    outputs = midi.outs()
    expect(outputs).toBeDefined()
    expect(outputs.length).toBe 2, 'It should return an array of output ports.'
    expect(outputs[0]).toBe 'output1', 'It should have returned the correct port name.'

  it 'should be able to create a new midi input object.', ->
    inputFunction = midi.In 'port1'
    expect(inputFunction).toBeDefined()
    expect(typeof inputFunction).toBe 'function', 'The router returned should be a function.'

    router = {}
    inputFunction router

    expect(rtMidiMock.inputs.length).toBe 1, 'It should have created a new midi input object.'
    expect(rtMidiMock.inputs[0].openPort).toHaveBeenCalled()
    expect(rtMidiMock.inputs[0].openVirtualPort).not.toHaveBeenCalled()
    expect(rtMidiMock.inputs[0].on).toHaveBeenCalled()

  it 'should be able to create multiple inputs.', ->
    input1 = midi.In('port1')
    router1 = {}
    input1(router1)

    input2 = midi.In('port2', true)
    router2 = {}
    input2(router2)

    expect(rtMidiMock.inputs.length).toBe(2, 'Two separate inputs should have been created.')
    expect(rtMidiMock.inputs[1].openPort).not.toHaveBeenCalled()
    expect(rtMidiMock.inputs[1].openVirtualPort).toHaveBeenCalled()

  it 'should close its input port when legato is closed.', ->
    router.in '/myPort', midi.In('port1')

    expect(rtMidiMock.inputs[0].closePort).not.toHaveBeenCalled()

    router.init()

    expect(rtMidiMock.inputs[0].closePort).toHaveBeenCalled()

  it 'should be able to create new midi outputs.', ->
    id1 = midi.Out 0

    expect(rtMidiMock.outputs.length).toBe 1, 'It should have created a midi output object.'
    expect(rtMidiMock.outputs[0].openPort).toHaveBeenCalled()
    expect(Object.keys(utils.closet).length).toBe 1, 'It should have added a close port callback to legato.'

    id2 = midi.Out 0, true

    expect(rtMidiMock.outputs.length).toBe 2, 'It should have created a second output object.'
    expect(rtMidiMock.outputs[1].openPort).not.toHaveBeenCalled()
    expect(rtMidiMock.outputs[1].openVirtualPort).toHaveBeenCalled()
    expect(id1).not.toEqual id2, 'The two ouput ids should be unique.'

  it 'should be able to create multiple outputs.', ->
    output1 = midi.Out(0)
    output2 = midi.Out(1, true)

    expect(rtMidiMock.outputs.length).toBe(2, 'Two separate inputs should have been created.')
    expect(rtMidiMock.outputs[1].openPort).not.toHaveBeenCalled()
    expect(rtMidiMock.outputs[1].openVirtualPort).toHaveBeenCalled()
    expect(output1).toEqual(jasmine.any(Function))
    expect(output2).toEqual(jasmine.any(Function))

  describe 'parsing different types of midi in messages', ->

    it 'should correctly parse midi messages.', ->
      mock = {
        mockCallback: (path, value) -> console.log path, value
      }
      spyOn mock, 'mockCallback'

      midiRegister = midi.In('port1')
      midiRegister( mock.mockCallback )

      rtMidiMock.inputs[0].messageCallbacks[0](0, [153, 44, 103])

      expect(mock.mockCallback).toHaveBeenCalledWith '/9/note/44', 103/127

      rtMidiMock.inputs[0].messageCallbacks[0](0, [144, 62, 120])

      expect(mock.mockCallback.calls.count()).toBe 2
      expect(mock.mockCallback.calls.argsFor(1)).toEqual ['/0/note/62', 120/127]

    xit 'should correctly parse noteOn messages.'
    xit 'should correctly parse noteOff messages.'
    xit 'should correctly parse pitchBend messages.'
    xit 'should correctly parse cc messages.'
    xit 'should correctly parse clock messages.'
    xit 'should correctly parse start messages.'
    xit 'should correctly parse songPosition messages.'
    xit 'should correctly parse channelPressure messages.'


  describe 'sending different types of midi messages', ->

    it 'should be able to send noteOn messages.', ->
      note = 60
      value = .5
      channel = 3
      output = midi.Out 0, true
      output('noteOn', note, value, channel)

      firstCall = rtMidiMock.outputs[0].sendMessage.calls.first()
      expect(firstCall.args[0][0]).toEqual(147)
      expect(firstCall.args[0][1]).toEqual(note)
      expect(firstCall.args[0][2]).toEqual(63)

    it 'should be able to send noteOff messages.', ->
      note = 65
      value = .4
      channel = 8
      output = midi.Out 0, true
      output('noteOff', note, value, channel)

      firstCall = rtMidiMock.outputs[0].sendMessage.calls.first()
      expect(firstCall.args[0][0]).toEqual(136)
      expect(firstCall.args[0][1]).toEqual(note)
      expect(firstCall.args[0][2]).toEqual(50)

    it 'should be able to send pitchBend messages.', -> 
      value = .4
      channel = 7
      output = midi.Out 0, true
      output('pitchBend', value, channel)

      firstCall = rtMidiMock.outputs[0].sendMessage.calls.first()
      expect(firstCall.args[0][0]).toEqual(231)
      expect(firstCall.args[0][1]).toEqual(50)
      expect(firstCall.args[0][2]).toEqual(0)

    it 'should be able to send channelPressure messages.', ->
      value = 1
      channel = 3
      output = midi.Out 0, true
      output('channelPressure', value, channel)

      firstCall = rtMidiMock.outputs[0].sendMessage.calls.first()
      expect(firstCall.args[0][0]).toEqual(211)
      expect(firstCall.args[0][1]).toEqual(127)

    it 'should be able to send cc messages.', ->
      note = 12
      value = 1
      channel = 11
      output = midi.Out 0, true
      output('cc', note, value, channel)

      firstCall = rtMidiMock.outputs[0].sendMessage.calls.first()
      expect(firstCall.args[0][0]).toEqual(187)
      expect(firstCall.args[0][1]).toEqual(note)
      expect(firstCall.args[0][2]).toEqual(127)

    it 'should be able to send clock messages.', ->
      output = midi.Out 0, true
      output('clock')

      firstCall = rtMidiMock.outputs[0].sendMessage.calls.first()
      expect(firstCall.args[0][0]).toEqual(248)

    it 'should be able to send start messages.', ->
      output = midi.Out 0, true
      output('start')

      firstCall = rtMidiMock.outputs[0].sendMessage.calls.first()
      expect(firstCall.args[0][0]).toEqual(250)

    it 'should be able to send songPosition messages.', ->
      position = 87
      output = midi.Out 0, true
      output('songPosition', position)

      firstCall = rtMidiMock.outputs[0].sendMessage.calls.first()
      # TODO What do real songPosition events look like?
      expect(firstCall.args[0][0]).toEqual(242)
      expect(firstCall.args[0][1]).toEqual(position)
      expect(firstCall.args[0][2]).toEqual(0)

    it 'should be able to send to multiple ports.', ->
      note = 12
      value = 1
      channel = 11
      output1 = midi.Out 0
      output2 = midi.Out 1

      output1('noteOn', note, value, channel)
      output2('noteOn', note, value, channel)

      port1Send = rtMidiMock.outputs[0].sendMessage
      port2Send = rtMidiMock.outputs[1].sendMessage

      expect(port1Send).toHaveBeenCalled()
      expect(port2Send).toHaveBeenCalled()

    it 'should be able to send to the same port using multiple outputs.', ->
      note = 12
      value = 1
      channel = 11
      output1 = midi.Out 0
      output2 = midi.Out 0

      output1('noteOn', note, value, channel)
      output2('noteOn', note, value, channel)

      port1Send = rtMidiMock.outputHosts[0].send
      port2Send = rtMidiMock.outputHosts[1].send

      expect(port1Send).toHaveBeenCalled()
      expect(port1Send.calls.count()).toBe(2)
      expect(port2Send).not.toHaveBeenCalled()

    it 'should be able to send to the correct output.', ->
      note = 12
      value = 1
      channel = 11
      output1 = midi.Out 0
      output2 = midi.Out 1

      output1('noteOn', note, value, channel)

      port1Send = rtMidiMock.outputHosts[0].send
      port2Send = rtMidiMock.outputHosts[1].send

      expect(port1Send).toHaveBeenCalled()
      expect(port1Send.calls.count()).toBe(1)
      expect(port2Send).not.toHaveBeenCalled()

