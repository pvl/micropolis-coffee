define [], ->
    class SpriteLoader
        constructor: ->
            @_loadCallback = null
            @_errorCallback = null

        _loadCB: =>
            callback = @_loadCallback
            @_loadCallback = null
            @_errorCallback = null
            callback(@_spriteSheet)

        _errorCB: =>
            callback = @_errorCallback
            @_loadCallback = null
            @_errorCallback = null
            @_spriteSheet = null
            callback()

        load: (loadCallback, errorCallback) ->
            @_loadCallback = loadCallback
            @_errorCallback = errorCallback

            @_spriteSheet = new Image()
            @_spriteSheet.onerror = @_errorCB
            @_spriteSheet.onload = @_loadCB
            @_spriteSheet.src = 'images/sprites.png'
