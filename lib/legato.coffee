'use strict'

router = require( './router' ).router
utils = require( './utils' ).utils
legatoMidi = require './midi'
midi = require 'midi'
midiHelp = require 'midi-help'
omgosc = require 'omgosc'
legatoOSC = require './osc'
_ = require 'lodash'
legatoLifx = require './lifx-light'
LIFX = require('node-lifx').Client

utils.inject _
router.inject utils
legatoMidi.inject router, utils, midi, midiHelp
legatoOSC.inject utils, omgosc
legatoLifx.inject utils, new LIFX()

@midi = legatoMidi
@osc = legatoOSC
@lifx = legatoLifx
# TODO Provide access to firmata and amixer

@init = ->
  router.init()

@in = (prefix, input) ->
  return router.in prefix, input

@on = (path, callback) ->
  return router.on path, callback

@removeRoute = (id) ->
  router.removeRoute id

@removeInput = (id, prefix) ->
  router.removeInput id, prefix

@deinit = ->
  router.deinit()
