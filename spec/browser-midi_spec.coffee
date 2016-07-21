'use strict'

describe 'browser-midi', ->
  beforeEach ->
    # console.debug = ->
    console.info = ->
    return

  describe 'using the real midi implementation', ->
    input = null

    beforeEach ->
      input = new MidiInput()

    it 'should be able to create an input object.', ->
      expect(input).toBeDefined()

    it 'should be able to get the number of available ports.', ->
      expect( -> input.getPortCount() ).not.toThrow()

    it 'should be able to get a promise for when midi becomes available.', ->
      expect( input.ready() ).toEqual(jasmine.any(Promise))

    it 'should resolve the ready promise when midi becomes available.', (done) ->
      input.ready().then (hasMidi) ->
        expect(hasMidi).toBe(true)
        done()

  describe 'using a mock midi interface', ->
    input = originalMidi = midiPromise = null

    beforeEach ->
      originalMidi = navigator.requestMIDIAccess

    afterEach ->
      navigator.requestMIDIAccess = originalMidi

    describe 'before requestMIDIAccess returns', ->
      beforeEach ->
        midiPromise = new Promise( (resolve) -> resolve() )
        navigator.requestMIDIAccess = -> midiPromise
        input = new MidiInput()

      it 'should should show no ports if midi is not available yet.', ->
        expect( input.getPortCount() ).toEqual(0)

    describe 'when requestMIDIAccess fails', ->
      beforeEach ->
        midiPromise = Promise.reject()
        navigator.requestMIDIAccess = -> midiPromise
        input = new MidiInput()

      fit 'should should show no ports if it fails to access midi.', (done) ->
        input.ready().then ->
          expect( false ).toEqual(true)
          done()
        , ->
          expect( input.getPortCount() ).toEqual(0)
          done()

    describe 'when requestMIDIAccess succeeds', ->
      midiAccess = null

      beforeEach ->
        midiAccesss =
          inputs:
            size: 7
        midiPromise = Promise.resolve(midiAccess)
        navigator.requestMIDIAccess = -> midiPromise
        input = new MidiInput()

      it 'should should show no ports if there are none.', ->
        expect(input.getPortCount() ).toEqual(7)


    xit 'should be able to tell if midi is available.'
    xit 'should return false from the ready promise if it cannot access midi.'

