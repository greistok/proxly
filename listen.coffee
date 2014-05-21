Config = require './config.coffee'

class LISTEN extends Config
  local:
    api: chrome.runtime.onMessage
    listeners:{}
    # responseCalled:false
  external:
    api: chrome.runtime.onMessageExternal
    listeners:{}
    # responseCalled:false
  instance = null
  constructor: ->
    super
    
    chrome.runtime.onConnectExternal.addListener (port) =>
      port.onMessage.addListener @_onMessageExternal

    @local.api.addListener @_onMessage
    @external.api?.addListener @_onMessageExternal

  @get: () ->
    instance ?= new LISTEN

  Local: (message, callback) =>
    @local.listeners[message] = callback

  Ext: (message, callback) =>
    show 'adding ext listener for ' + message
    @external.listeners[message] = callback

  _onMessageExternal: (request, sender, sendResponse) =>
    responseStatus = called:false
    _sendResponse = ->
      try
        show 'calling sendresponse'
        sendResponse.apply null,arguments
      catch e
        undefined # error because no response was requested from the MSG, don't care
      responseStatus.called = true
      
    (show "<== GOT EXTERNAL MESSAGE == #{ @EXT_TYPE } ==" + _key) for _key of request
    if sender.id isnt @EXT_ID and sender.constructor.name isnt 'Port'
      return false

    @external.listeners[key]? request[key], _sendResponse for key of request
    
    unless responseStatus.called # for synchronous sendResponse
      # show 'returning true'
      return true

  _onMessage: (request, sender, sendResponse) =>
    responseStatus = called:false
    _sendResponse = =>
      try
        show 'calling sendresponse'
        sendResponse.apply this,arguments
      catch e
        show e
      responseStatus.called = true

    (show "<== GOT MESSAGE == #{ @EXT_TYPE } ==" + _key) for _key of request
    @local.listeners[key]? request[key], _sendResponse for key of request

    unless responseStatus.called
      # show 'returning true'
      return true

module.exports = LISTEN