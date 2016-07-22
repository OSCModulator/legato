'use strict'

class MidiInputMock
  inputs: ['port1', 'port2']
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
  outputs: ['output1', 'output2']
  messageCallbacks: []
  getPortCount: ->
    return @outputs.length
  getPortName: (index) ->
    return @outputs[index]
  openPort: ->
    return true
  openVirtualPort: ->
    return true
  sendMessage: ->
    return true
  closePort: ->
    return true

exports.rtMidiMock = {
  inputs:[],
  outputs:[],
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
    spyOn(outputMock, 'openPort')
    spyOn(outputMock, 'openVirtualPort')
    spyOn(outputMock, 'sendMessage')
    spyOn(outputMock, 'closePort')

    exports.rtMidiMock.outputs.push(outputMock)
    return outputMock
}
