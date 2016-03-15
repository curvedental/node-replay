log4js = require('log4js')
log4js.configure('log4j.json')
logger = log4js.getLogger()

class ReplayClient
    constructor: (@urlRewrite, @rest) ->
        @authCookies = {}

    _authorized: (clientId) ->
        @authCookies[clientId]?

    _makeRequest: (method, url, data, successCallback, errorCallback) ->
        if @urlRewrite.isSafeUrl url
            # Restler has a "del" method instead of "delete" because delete is a reserved word
            if method == 'delete'
                method = 'del'
            request = @rest[method] url, data
            request.on( 'complete', successCallback )
            request.on( 'error', errorCallback )
        else
            errorCallback( "Ignoring request because it is not whitelisted: [" + url + "]" )

    _logIn: (request, clientId, callback) ->
        loginURL = @urlRewrite.loginURL(request)
        loginData = @urlRewrite.loginData()

        onSuccess = (data, response) =>
            if response == null
                logger.info " --> UNKNOWN - failed to get cookie for:", clientId, "from", loginURL
                return
            if response.headers['set-cookie']?
                @authCookies[clientId] = response.headers['set-cookie'].map((c) -> c.replace(/;.*$/, '')).join('; ')
                logger.info " --> got cookie for:", clientId, @authCookies[clientId], "from", loginURL
                callback @authCookies[clientId]
        onError = (error) =>
            logger.error "Login failed", error
        @_makeRequest 'post', loginURL, loginData, onSuccess, onError

    _requestAuthCookie: (request, clientId, callback) ->
        if @_authorized(clientId)
            callback @authCookies[clientId]
        else
            @_logIn request, clientId, callback

    send: (request) -> 
        logger.info "<--- Received: ", request.server_info.HTTP_HOST, request.session_id, request.start_time, request['method'], request['path'], request['post']

        proxyURL = @urlRewrite.getURL request
        clientId = @urlRewrite.getClientId proxyURL

        @_requestAuthCookie request, clientId, (cookie) =>
            method = request.method.toLowerCase()

            opts = @urlRewrite.getOptions cookie, @parse(request.post,'')

            onSuccess = (data, response) =>
                if( response == null )
                    statusCode = 'UNKNOWN'
                else
                    statusCode = response.statusCode
                logger.info "---> Replayed: ", request.session_id, request.start_time, statusCode, method, proxyURL, "( length: #{JSON.stringify(data).length} )"
            onError = (error) =>
                logger.error error
            @_makeRequest method, proxyURL, opts, onSuccess, onError

    parse: (data_obj, property_prefix) ->
        result = {}
        for index,value of data_obj
            result_index = @createPropertyIndex(property_prefix, index)
            if typeof value == "string"
                result[result_index] = value
            else
                for nested_index, nested_value of @parse(value, result_index)
                    result[nested_index] = nested_value

        result

    createPropertyIndex: (prefix, index) ->
        if prefix == ''
            return index
        return prefix + "["+index+"]"

module.exports = ReplayClient

