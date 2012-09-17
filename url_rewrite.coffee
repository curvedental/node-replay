class URLRewrite
    constructor: (env) ->
        @env = env

    loginURL: (request) ->
        basePathRegex = @env.get 'basePathRegex'
        if basePathRegex
            prefix = request.path.match(basePathRegex)[1]
        else
            prefix = ''
        loginPath = "#{prefix}#{@env.get 'authPath'}" 
        @getURL request, loginPath

    loginData: ->
        opts = 
            headers:
                'User-Agent': @_userAgent()
            data: @env.get 'authData'

    getOptions: (cookie, postData) ->
        headers:
            'User-Agent': @_userAgent()
            'Cookie': cookie
        data: postData
        followRedirects: false

    processPath: (path) -> 
        pathConfig = @env.get 'path'
        if pathConfig 
            path.replace pathConfig.regex, pathConfig.replace 
        else
            path

    processHost: (host) ->
        hostConfig = @env.get 'host'
        if hostConfig 
            host.replace hostConfig.regex, hostConfig.replace 
        else
            host

    getClientId: (url) ->
        clientRegex = @env.get 'clientRegex'
        url.match(clientRegex)[1]

    getURL: (request, inpath = request.path) ->
        protocol = if request.server_info.HTTPS? then 'https://' else 'http://'
        host = @processHost request.server_info.HTTP_HOST 
        path = @processPath inpath

        "#{protocol}#{host}#{path}"

    isSafeUrl: (url) ->
        @_whiteList().some (pattern) ->
            url.match(pattern)

    _userAgent: () ->
        @userAgent = @userAgent || @env.get 'userAgent'

    _whiteList: () ->
        @whiteList = @whiteList || @env.get 'whiteList'

module.exports = URLRewrite
