_           = require 'lodash'
url         = require 'url'
debug       = require('debug')('nanocyte-component-octoblu-channel-request-formatter')
ReturnValue = require 'nanocyte-component-return-value'

class OctobluChannelRequestFormatter extends ReturnValue
  BasicAuthStrategy: (config) =>
    auth:
      username: config.oauth.access_token
      password: config.oauth.access_token_secret

  NoAuthStrategy: => {}

  AccessTokenBearerStrategy: (config) =>
    auth:
      bearer: config.oauth.access_token

  AccessTokenQueryStrategy: (config) =>
    tokenKey = config.oauth.tokenQueryParam
    tokenKey ?= 'access_token'

    qs:
      "#{tokenKey}": config.oauth.access_token

  AccessTokenBearerAndApiKeyStrategy: (config) =>
    auth:
      bearer: config.oauth.access_token
    qs:
      api_key: config.oauth.api_key

  ApiKeyStrategy: (config) =>
    tokenKey = config.authHeaderKey

    headers:
      "#{tokenKey}": config.apikey

  AuthTokenStrategy: (config) =>
    tokenKey = config.oauth.tokenQueryParam
    tokenKey ?= 'token'

    headers:
      "Authorization": "#{tokenKey} #{config.oauth.access_token}"

  HeaderApiKeyAuthStrategy: (config) =>
    tokenKey = config.oauth.headerParam
    tokenKey ?= 'Access-Token'

    headers:
      "#{tokenKey}": config.oauth.access_token

  SignedOAuthStrategy: (config) =>
    oauth:
      consumer_key:    config.oauth.key
      consumer_secret: config.oauth.secret
      token:           config.oauth.access_token
      token_secret:    config.oauth.access_token_secret

  getStrategy: (tokenMethod) =>
    strategies =
      'access_token_bearer':             @AccessTokenBearerStrategy
      'access_token_query':              @AccessTokenQueryStrategy
      'access_token_bearer_and_api_key': @AccessTokenBearerAndApiKeyStrategy
      'basic':                           @BasicAuthStrategy
      'apikey-basic':                    @BasicAuthStrategy
      'apikey-dummypass-basic':          @BasicAuthStrategy
      'meshblu':                         @BasicAuthStrategy
      'oauth_signed':                    @SignedOAuthStrategy
      'echosign':                        @HeaderApiKeyAuthStrategy
      'header':                          @HeaderApiKeyAuthStrategy
      'auth_token':                      @AuthTokenStrategy
      'apikey':                          @ApiKeyStrategy

    strategies[tokenMethod] ? @NoAuthStrategy

  buildRequestParameters: (config) =>
    config = _.cloneDeep config
    _.defaults config,
      defaultParams: {}
      dynamicParams: {}

    hiddenBodyParams  = _.filter config.hiddenParams, style: 'body'
    hiddenQueryParams = _.filter config.hiddenParams, style: 'query'

    defaultHeaderParams = config.defaultHeaderParams
    defaultUrlParams = config.defaultParams

    urlParams = _.extend {}, defaultUrlParams, config.urlParams
    headerParams = _.cloneDeep config.headerParams
    bodyParams = {}
    uri = @_replaceParams config.url, urlParams

    if config.method != 'GET'
      _.each config.bodyParams, (value, key) =>
        _.set bodyParams, key, value

      _.each hiddenBodyParams, (param) ->
        _.set bodyParams, param.name, param.value

      if config.bodyParam? and bodyParams[config.bodyParam]?
        bodyParams = bodyParams[config.bodyParam]

    requestParams = @_generateRequestParams uri, config, bodyParams
    requestParams.qs ?= {}

    _.each hiddenQueryParams, (param) ->
      _.set requestParams.qs, param.name, param.value

    requestParams.headers = _.extend {}, requestParams.headers, headerParams, defaultHeaderParams

    strategyMethod = @getStrategy config.oauth?.tokenMethod
    strategyParams = strategyMethod config, _.cloneDeep(requestParams)
    params =  _.defaultsDeep {}, strategyParams, requestParams
    debug 'return params', params
    return params

  _generateRequestParams: (uri, config, bodyParams, body) =>
    # clean up querystring and place it in the queryParams
    parsedUri = url.parse(uri, true)
    parsedUri.search = ''
    parsedUri.query = ''

    uri = url.format(parsedUri)
    queryParams = _.extend {}, parsedUri.query

    _.each config.queryParams, (value, key) =>
      _.set queryParams, key, value

    requestParams =
      headers:
        'Accept': 'application/json'
        'User-Agent': 'Octoblu/1.0.0'
        'x-li-format': 'json'
      uri: uri
      method: config.method
      followAllRedirects: config.followAllRedirects ? true
      qs: queryParams

    requestParams.strictSSL = false if config.skipVerifySSL

    if config.uploadData
      buf = new Buffer config.uploadData, 'base64'
      requestParams.body = buf
      requestParams.encoding = null
      requestParams.headers['Content-Type'] = 'text/plain'
      delete requestParams.headers['Accept']
    else
      if config.bodyFormat == 'json'
        json = @_omitEmptyObjects bodyParams
        requestParams.json = json unless _.isEmpty(json)
        requestParams.json = true if _.isEmpty(json)
      else
        requestParams.form = bodyParams

    requestParams

  _replaceParams: (path, params) =>
    _.each params, (value, key) =>
      re = new RegExp(key, 'g')
      path = path.replace(re, value)

    return path

  onEnvelope: ({config, message}) =>
    message = _.cloneDeep config unless message?.url?
    @buildRequestParameters message

  _omitEmptyObjects: (object) =>
    _.omit object, (value) =>
      _.isObject(value) && _.isEmpty(value)

module.exports = OctobluChannelRequestFormatter
