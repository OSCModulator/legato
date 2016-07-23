'use strict'

inputs = ['port1', 'port2']
outputs = ['output1', 'output2']
outputHosts = [
  {send: jasmine.createSpy('output1.send')}
  {send: jasmine.createSpy('output2.send')}
]

class MidiInputMock
  inputs: inputs
  messageCallbacks: []
  getPortCount: ->
    return @inputs.length
  getPortName: (index) ->
    return @inputs[index]
  openPort: (index) ->
    return true
  openVirtualPort: (index) ->
    return true
  on: (message, callback) ->
    @messageCallbacks.push(callback)
  closePort: ->
    return true

class MidiOutputMock
  outputs: outputs
  getPortCount: ->
    return @outputs.length
  getPortName: (index) ->
    return @outputs[index]
  openPort: (@port) ->
    return true
  openVirtualPort: (@port) ->
    return true
  sendMessage: (message) ->
    outputHosts[@port].send(message)
    return true
  closePort: ->
    return true

exports.rtMidiMock = {
  inputs:[],
  outputs:[],
  outputHosts: outputHosts
  input: ->
    inputMock = new MidiInputMock()

    spyOn(inputMock, 'getPortCount').and.callThrough()
    spyOn(inputMock, 'getPortName').and.callThrough()
    spyOn(inputMock, 'openPort')
    spyOn(inputMock, 'openVirtualPort')
    spyOn(inputMock, 'on').and.callThrough()
    spyOn(inputMock, 'closePort')

    exports.rtMidiMock.inputs.push(inputMock)
    return inputMock

  output: ->
    outputMock = new MidiOutputMock()

    spyOn(outputMock, 'getPortCount').and.callThrough()
    spyOn(outputMock, 'getPortName').and.callThrough()
    spyOn(outputMock, 'openPort').and.callThrough()
    spyOn(outputMock, 'openVirtualPort').and.callThrough()
    spyOn(outputMock, 'sendMessage').and.callThrough()
    spyOn(outputMock, 'closePort')

    exports.rtMidiMock.outputs.push(outputMock)
    return outputMock
}
