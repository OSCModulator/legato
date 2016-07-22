'use strict'

sandbox = require('./utils').sandbox

describe 'browser-midi', ->
  describe 'MidiInput using a mock midi interface', ->
    input = null

    createInput = (midiPromise) ->
      navigator =
        requestMIDIAccess: ->
          midiPromise

      midi = sandbox('lib/browser-midi.coffee',
        console: console,
        navigator: navigator
        window: {}
      )
      new midi.input()

    describe 'before requestMIDIAccess returns', ->
      beforeEach ->
        midiPromise = new Promise( (resolve) -> resolve() )
        input = createInput(midiPromise)

      it 'should should show no ports if midi is not available yet.', ->
        expect( input.getPortCount() ).toEqual(0)

    describe 'when requestMIDIAccess fails', ->
      beforeEach ->
        midiPromise = Promise.reject()
        input = createInput(midiPromise)

      it 'should return false from the ready promise if it cannot access midi.', (done) ->
        input.ready().then ->
          expect('Should not have loaded midi.').toEqual(false)
          done()
        .catch (response) ->
          expect(response).toEqual('Unable to get MIDI access.')
          done()

      it 'should should show no ports if it fails to access midi.', (done) ->
        input.ready().then ->
          expect('Should not have loaded midi.').toEqual(false)
          done()
        .catch (e) ->
          expect( input.getPortCount() ).toEqual(0)
          done()

    describe 'when requestMIDIAccess succeeds', ->
      midiAccess = null

      beforeEach ->
        midiAccess =
          inputs:
            size: 7
        midiPromise = Promise.resolve(midiAccess)
        input = createInput(midiPromise)

      it 'should should show no ports if there are none.', (done) ->
        midiReady = input.ready()

        input.ready().then ->
          expect(input.getPortCount() ).toEqual(7)
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

    describe 'with multiple midi ports', ->
      midiAccess = midiPromise = null

      beforeEach ->
        class MockMidiInputPort
          constructor: (@name) ->
          onmidimessage: null
          close: jasmine.createSpy('MockMidiInputPort.close')

        portMap = new Map [
          ['0', new MockMidiInputPort('Trigger')]
          ['1', new MockMidiInputPort('Finger')]
          ['33', new MockMidiInputPort('Ableton')]
        ]

        midiAccess =
          inputs: portMap
        midiPromise = Promise.resolve(midiAccess)
        input = createInput(midiPromise)

      it 'should be able to get the name of a port.', (done) ->
        input.ready().then ->
          expect( input.getPortName(1) ).toEqual( 'Finger' )
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should be able to open a port.', (done) ->
        input.ready().then ->
          input.openPort(1)
          expect(midiAccess.inputs.get('1').onmidimessage).not.toBeNull()
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should be able to open a virtual port.', (done) ->
        input.ready().then ->
          input.openVirtualPort(2)
          # The Ableton port is on a non-sequential id for testing purposes.
          expect(midiAccess.inputs.get('33').onmidimessage).not.toBeNull()
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      receiveMessage = (id, time, data) ->
        event =
          data: data
          receivedTime: time
        midiAccess.inputs.get(id).onmidimessage(event)

      it 'should be able to tell a listener when midi messages are received.', (done) ->
        messageSpy = jasmine.createSpy('messageSpy')

        input.ready().then ->
          input.openPort(1)
          input.on('message', messageSpy)
          receiveMessage('1', 123, [1,2,3])
          expect(messageSpy).toHaveBeenCalledWith(123, [1,2,3])
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should be able to notify multiple listeners of midi events.', (done) ->
        spies = []
        for i in [0..3]
          spies.push jasmine.createSpy("messageSpy#{i}")

        input.ready().then ->
          input.openPort(1)

          for spy in spies
            input.on('message', spy)

          receiveMessage('1', 123, [1,2,3])

          for spy in spies
            expect(spy).toHaveBeenCalledWith(123, [1,2,3])

          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should not tell listeners if a message comes in on a different port.', (done) ->
        messageSpy = jasmine.createSpy('messageSpy')
        otherSpy = jasmine.createSpy('otherSpy')

        otherInput = createInput(midiPromise)
        otherInput.ready().then ->
          otherInput.openPort(0)
          otherInput.on('message', otherSpy)

          input.ready().then ->
            input.openPort(1)
            input.on('message', messageSpy)

            # Receive a message for the other spy.
            receiveMessage('0', 123, [1,2,3])

            expect(messageSpy).not.toHaveBeenCalled()
            expect(otherSpy).toHaveBeenCalled()
            done()
          .catch (e) ->
            expect(e).toBe(false)
            done()

      it 'should be able to close a midi port.', (done) ->
        messageSpy = jasmine.createSpy('messageSpy')

        input.ready().then ->
          input.openPort(1)
          input.on('message', messageSpy)
          input.closePort()

          receiveMessage('1', 123, [1,2,3])
          expect(messageSpy).not.toHaveBeenCalled()
          expect(midiAccess.inputs.get('1').close ).toHaveBeenCalled()
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should still be ready after closing the port.', (done) ->
        messageSpy = jasmine.createSpy('messageSpy')

        input.ready().then ->
          input.openPort(1)
          input.on('message', messageSpy)
          input.closePort()

          input.ready().then (result) ->
            expect(result).toBe(true)
            done()
          .catch (e) ->
            expect(e).toBe(false)
            done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

  describe 'MidiOutput using a mock midi interface', ->
    output = null

    createOutput = (midiPromise) ->
      navigator =
        requestMIDIAccess: ->
          midiPromise

      midi = sandbox('lib/browser-midi.coffee',
        console: console,
        navigator: navigator
        window: {}
      )
      new midi.output()

    describe 'before requestMIDIAccess returns', ->
      beforeEach ->
        midiPromise = new Promise( (resolve) -> resolve() )
        output = createOutput(midiPromise)

      it 'should should show no ports if midi is not available yet.', ->
        expect( output.getPortCount() ).toEqual(0)

    describe 'when requestMIDIAccess fails', ->
      beforeEach ->
        midiPromise = Promise.reject()
        output = createOutput(midiPromise)

      it 'should return false from the ready promise if it cannot access midi.', (done) ->
        output.ready().then ->
          expect('Should not have loaded midi.').toEqual(false)
          done()
        .catch (response) ->
          expect(response).toEqual('Unable to get MIDI access.')
          done()

      it 'should should show no ports if it fails to access midi.', (done) ->
        output.ready().then ->
          expect('Should not have loaded midi.').toEqual(false)
          done()
        .catch (e) ->
          expect( output.getPortCount() ).toEqual(0)
          done()

    describe 'when requestMIDIAccess succeeds', ->
      midiAccess = null

      beforeEach ->
        midiAccess =
          outputs:
            size: 7
        midiPromise = Promise.resolve(midiAccess)
        output = createOutput(midiPromise)

      it 'should should show no ports if there are none.', (done) ->
        midiReady = output.ready()

        output.ready().then ->
          expect(output.getPortCount() ).toEqual(7)
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

    describe 'with multiple midi ports', ->
      midiAccess = midiPromise = null

      beforeEach ->
        class MockMidiOutputPort
          constructor: (@name) ->
          send: jasmine.createSpy('MockMidiOutputPort.send')
          close: jasmine.createSpy('MockMidiOutputPort.close')

        portMap = new Map [
          ['0', new MockMidiOutputPort('MPC')]
          ['1', new MockMidiOutputPort('Casio')]
          ['33', new MockMidiOutputPort('Korg')]
        ]

        midiAccess =
          outputs: portMap
        midiPromise = Promise.resolve(midiAccess)
        output = createOutput(midiPromise)

      it 'should be able to get the name of a port.', (done) ->
        output.ready().then ->
          expect( output.getPortName(1) ).toEqual( 'Casio' )
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should be able to open a port.', (done) ->
        output.ready().then ->
          output.openPort(1)
          expect(output._port).toBe(midiAccess.outputs.get('1'))
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should be able to open a virtual port.', (done) ->
        output.ready().then ->
          output.openVirtualPort(1)
          expect(output._port).toBe(midiAccess.outputs.get('1'))
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should be able to send a midi message.', (done) ->
        output.ready().then ->
          output.openPort(0)
          output.sendMessage 'message'
          expect( midiAccess.outputs.get('0').send ).toHaveBeenCalledWith('message')
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should be able to close a midi port.', (done) ->
        output.ready().then ->
          output.openPort(0)
          output.closePort()
          output.sendMessage 'message'
          expect( midiAccess.outputs.get('0').send ).not.toHaveBeenCalled()
          expect( midiAccess.outputs.get('0').close ).toHaveBeenCalled()
          done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

      it 'should still be ready after closing the port.', (done) ->
        output.ready().then ->
          output.openPort(2)
          output.closePort()
          output.ready().then (result) ->
            expect(result).toBe(true)
            done()
          .catch (e) ->
            expect(e).toBe(false)
            done()
        .catch (e) ->
          expect(e).toBe(false)
          done()

