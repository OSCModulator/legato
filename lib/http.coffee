'use strict'

request = utils = ___ = null

# @param legatoUtils {Utils} The local utils service (ie. require('./utils.coffee') )
# @param requestService {Request} The request service or an API that fulfills
#     https://www.npmjs.com/package/request
@inject = (legatoUtils, requestService) ->
  utils = legatoUtils
  request = requestService
  ___ = utils.____ '[http]'

@In = ->

@Out = (host, port, https=false) ->
  ___ "out #{host}:#{port}"
  opts = {}
  if https
    opts.baseUrl = 'https://'
  else
    opts.baseUrl = 'http://'

  opts.baseUrl += "#{host}:#{port}"
  return (path, body='', method='GET') ->
    opts.uri = path
    opts.method = method
    opts.body = body
    request opts, (error, response, body) ->
      if error
        ___ "ERROR! #{response.statusCode}"
        ___ "ERROR! ", response
      else
        ___ "response #{response.statusCode} - #{body}"

