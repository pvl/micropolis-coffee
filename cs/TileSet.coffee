define ['Tile'], (Tile) ->
    class TileSet
        constructor: (src, loadCallback, errorCallback) ->
            if not (this instanceof TileSet)
                return new TileSet(src, loadCallback, errorCallback)

            e = new Error('Invalid parameter')

            if arguments.length < 3
                throw e

            @loaded = false
            @_successCallback = loadCallback
            @_errorCallback = errorCallback

            if src instanceof Image
                # we need to spin event loop here for sake of callers
                # to ensure constructor returns before callback called
                setTimeout( (() => @_verifyImage(src)) , 0)
            else
                img = new Image()
                img.onload = () -> self._verifyImage(img)
                img.onerror = () -> self._triggerCallback(false)
                img.src = src

        load: (src, loadCallback, errorCallback) ->
            e = new Error('Invalid parameter')

            if arguments.length < 3
                throw e

            # Don't allow overwriting an already loaded tileset
            if @loaded
                throw new Error("TileSet already loaded")

            @_successCallback = loadCallback
            @_errorCallback = errorCallback
            if src instanceof Image
                @_verifyImage(src)
            else
                img = new Image()
                img.onload = => @_verifyImage(img)
                img.onerror = => @_triggerCallback(false)
                img.src = src

        _triggerCallback: (successful) ->
            if not @_successCallback # image supplied, no callbacks
                return

            cb = @_successCallback
            if not successful
                cb = @_errorCallback

            delete @_successCallback
            delete @_errorCallback
            cb()

        _verifyImage: (img) ->
            w = img.width
            h = img.height
            tilesPerRow = Math.sqrt(Tile.TILE_COUNT)

            if w != h
                @_triggerCallback(false)
                return
            if (w % tilesPerRow) != 0
                @_triggerCallback(false)
                return

            @tileWidth = w / tilesPerRow
            tileWidth = @tileWidth

            if tileWidth < Tile.MIN_SIZE
                @_triggerCallback(false)
                return

            notifications = 0

            # Paint the image onto a canvas so we can split it up
            c = document.createElement('canvas')
            c.width = @tileWidth
            c.height = @tileWidth

            cx = c.getContext('2d')

            imageLoad = () =>
                notifications++

                if notifications == Tile.TILE_COUNT
                    @loaded = true
                    @_triggerCallback(true)

            for i in [0...Tile.TILE_COUNT]
                cx.clearRect(0, 0, @tileWidth, @tileWidth)

                sourceX = i % tilesPerRow * tileWidth
                sourceY = Math.floor(i / tilesPerRow) * tileWidth
                cx.drawImage(img, sourceX, sourceY, tileWidth, tileWidth, 0, 0, tileWidth, tileWidth)

                @[i] = new Image()
                @[i].onload = imageLoad
                @[i].src = c.toDataURL()
            return
