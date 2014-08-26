define ['AnimationManager', 'GameMap', 'MouseBox', 'Tile', 'TileSet'], \
  (AnimationManager, GameMap, MouseBox, Tile, TileSet) ->

    class GameCanvas

        @DEFAULT_WIDTH = 600
        @DEFAULT_HEIGHT = 400
        @DEFAULT_ID = "MicropolisCanvas"

        constructor: (id, parentNode, width, height) ->
            if not (this instanceof GameCanvas)
                return new GameCanvas(id, parentNode, width, height)

            e = new Error('Invalid parameter')

            if arguments.length < 1 then throw e

            # Argument shuffling
            if height == undefined
                if width == undefined
                    height = GameCanvas.DEFAULT_HEIGHT
                    width = GameCanvas.DEFAULT_WIDTH
                else
                    height = width
                    width = parentNode

            if parentNode == undefined or parentNode == width
                # No ID supplied
                parentNode = id
                id = GameCanvas.DEFAULT_ID

            if typeof(parentNode) == 'string'
                orig = parentNode
                parentNode = $('#' + parentNode)
                parentNode = if parentNode.length == 0 then null else parentNode[0]
                if parentNode == null
                    throw new Error("Node #{orig} not found")

            @_canvas = document.createElement('canvas')
            @_canvas.id = id
            @_canvas.width = width
            @_canvas.height = height

            # We will set this for real after a successful init
            @_justConstructed = false
            @_moved = false
            @_pendingTileSet = null

            # Remove any existing element with the same id
            current = document.getElementById(id)
            if current != null
                if current.parentNode == parentNode
                    parentNode.replaceChild(@_canvas, current)
                else
                    throw new Error('ID ' + id + ' already exists in document!')
            else
                parentNode.appendChild(@_canvas)

            @ready = false



        init: (map, tileSet, spriteSheet) ->
            e = new Error('Invalid parameter')

            if arguments.length < 3 then throw e
            if not tileSet.loaded then throw new Error('TileSet not ready!')

            @_spriteSheet = spriteSheet
            @_tileSet = tileSet
            w = @_tileSet.tileWidth
            @_map = map
            @_animationManager = new AnimationManager(map)

            if @_canvas.width < w or @_canvas.height < w
                throw new Error('Canvas too small!')

            @_calculateMaximaAndMinima()

            # Order is important here. ready must be set before the call to centreOn below
            @ready = true
            @centreOn(Math.floor(@_map.width / 2), Math.floor(@_map.height / 2))

            @_justConstructed = true
            @paint(null, null)


        _calculateMaximaAndMinima: ->
            w = @_tileSet.tileWidth
            @minX = 0 - Math.ceil(Math.floor(@_canvas.width/w) / 2)
            @maxX = (@_map.width - 1) - Math.ceil(Math.floor(@_canvas.width/w) / 2)
            @minY = 0 - Math.ceil(Math.floor(@_canvas.height/w) / 2)
            @maxY = (@_map.height - 1) - Math.ceil(Math.floor(@_canvas.height/w) / 2)
            @_wholeTilesInViewX = Math.floor(@_canvas.width / w)
            @_wholeTilesInViewY = Math.floor(@_canvas.height / w)
            @_totalTilesInViewX = Math.ceil(@_canvas.width / w)
            @_totalTilesInViewY = Math.ceil(@_canvas.height / w)


        moveNorth: ->
            if not @ready then throw new Error("Not ready!")

            if @_originY > @minY
                @_moved = true
                @_originY--


        moveEast: ->
            if not @ready then throw new Error("Not ready!")

            if @_originX < @maxX
                @_moved = true
                @_originX++


        moveSouth: ->
            if not @ready then throw new Error("Not ready!")

            if @_originY < @maxY
                @_moved = true
                @_originY++


        moveWest: ->
            if not @ready then throw new Error("Not ready!")

            if @_originX > @minX
                @_moved = true
                @_originX--

        moveTo: (x, y) ->
            if arguments.length < 1 then throw new Error('Invalid parameter')
            if not @ready then throw new Error("Not ready!")

            if x < @minX or x > @maxX or y < @minY or y > @maxY
                throw new Error('Coordinates out of bounds')

            @_originX = x
            @_originY = y
            @_moved = true


        centreOn: (x, y) ->
            if arguments.length < 1 then throw new Error('Invalid parameter')
            if not @ready then throw new Error("Not ready!")

            if y == undefined
                y = x.y
                x = x.x

            @_originX = Math.floor(x) - Math.ceil(@_wholeTilesInViewX / 2)
            @_originY = Math.floor(y) - Math.ceil(@_wholeTilesInViewY / 2)
            @_moved = true


        getTileOrigin: ->
            if not @ready then throw new Error('Not ready!')
            {x: @_originX, y: @_originY}


        getMaxTile: ->
            if not @ready then throw new Error('Not ready!')
            {x: @_originX + @_totalTilesInViewX - 1, y: @_originY + @_totalTilesInViewY - 1}


        canvasCoordinateToTileOffset: (x, y) ->
            if arguments.length < 2 then throw new Error('Invalid parameter')
            if not @ready then throw new Error("Not ready!")
            {x: Math.floor(x / @_tileSet.tileWidth), y: Math.floor(y / @_tileSet.tileWidth)}


        canvasCoordinateToTileCoordinate: (x, y) ->
            if arguments.length < 2 then throw new Error('Invalid parameter')
            if not @ready then throw new Error("Not ready!")

            if x >= @_canvas.width or y >= @_canvas.height
                return null

            {x: @_originX + Math.floor(x/@_tileSet.tileWidth),
            y: @_originY + Math.floor(y/@_tileSet.tileWidth)}


        canvasCoordinateToPosition: (x, y) ->
            if arguments.length < 2 then throw new Error('Invalid parameter')
            if not @ready then throw new Error("Not ready!")

            if x >= @_canvas.width or y >= @_canvas.height
                return null

            x = @_originX + Math.floor(x / @_tileSet.tileWidth)
            y = @_originY + Math.floor(y / @_tileSet.tileWidth)

            if x < 0 or x >= @_map.width or y < 0 or y >= @_map.height
                return null

            return new @_map.Position(x, y)


        positionToCanvasCoordinate: (p) ->
            if arguments.length < 1 then throw new Error('Invalid parameter')
            return @tileToCanvasCoordinate(p)


        tileToCanvasCoordinate: (x, y) ->
            e = new Error('Invalid parameter')
            if arguments.length < 1 then throw e
            if not @ready then throw new Error("Not ready!")

            if y == undefined
                y = x.y
                x = x.x

            if x == undefined or y == undefined or x < @minX or y < @minY or                x > (@maxX + @_totalTilesInViewX - 1) ||
               y > (@maxY + @_totalTilesInViewY - 1)
                throw e

            if x < @_originX or x >= @_originX + @_totalTilesInViewX or
               y < @_originY or y >= @_originY + @_totalTilesInViewY
                return null

            {x: (x - @_originX) * @_tileSet.tileWidth,
            y: (y - @_originY) * @_tileSet.tileWidth}


        changeTileSet: (tileSet) ->
            if arguments.length < 1 then throw new Error('Invalid parameter')
            if not @ready then throw new Error("Not ready!")
            if not tileSet.loaded then throw new Error('new tileset not loaded')
            if @_pendingTileSet and (@_pendingHeight or @_pendingWidth)
                throw new Error('dimensions have changed')

            w = tileSet.tileWidth
            canvasWidth = if @_pendingWidth == null then @_canvas.width else @_pendingWidth
            canvasHeight = if @_pendingHeight == null then @_canvas.height else @_pendingHeight

            if canvasWidth < w or canvasHeight < w
                throw new Error('canvas too small')

            @_pendingTileSet = tileSet


        takeScreenshot: (onlyVisible) ->
            if arguments.length < 1 then throw new Error('Invalid parameter')
            if not @ready then throw new Error("Not ready!")

            if onlyVisible then return @_canvas.toDataURL()

            tempCanvas = document.createElement('canvas')
            tempCanvas.width = @_map.width * @_tileSet.tileWidth
            tempCanvas.height = @_map.height * @_tileSet.tileWidth

            for x in [0...@_map.width]
                for y in [0...@_map.height]
                    @_paintTile(@_map.getTileValue(x, y), x * @_tileSet.tileWidth, y * @_tileSet.tileWidth, tempCanvas)
            return tempCanvas.toDataURL()


        shoogle: -> return # TODO


        _paintTile: (tileVal, x, y, canvas) ->
            canvas = canvas or @_canvas
            src = @_tileSet[tileVal]
            ctx = canvas.getContext('2d')
            ctx.drawImage(src, x, y)


        _paintVoid: (x, y, w, h, col) ->
            col = col or 'black'
            ctx = @_canvas.getContext('2d')
            ctx.fillStyle = col
            ctx.fillRect(x, y, w, h)


        _getDataForPainting: ->
            # Calculate bounds of tiles we're going to paint
            xStart = @_originX
            yStart = @_originY
            xEnd = @_totalTilesInViewX
            yEnd = @_totalTilesInViewY

            if xStart < 0
                # Chop off number of tiles in void
                xEnd = xEnd + xStart
                xStart = 0

            if yStart < 0
                # Chop off number of tiles in void
                yEnd = yEnd + yStart
                yStart = 0

            if xStart + xEnd > @_map.width
                xEnd = @_map.width - xStart

            if yStart + yEnd > @_map.height
                yEnd = @_map.height - yStart

            {offsetX: xStart - @_originX,
            offsetY: yStart - @_originY,
            tileData: @_map.getTiles(xStart, yStart, xEnd, yEnd)}


        _fullRepaint: (paintData) ->
            ctx = @_canvas.getContext('2d')
            # First, clear canvas
            ctx.clearRect(0, 0, @_canvas.width, @_canvas.height)

            # Paint any black voids
            if @_originX < 0
                @_paintVoid(0, 0, @_tileSet.tileWidth * (0 - @_originX), @_canvas.height)

            if @_originX + @_totalTilesInViewX > @_map.width
                start = @tileToCanvasCoordinate(@_map.width, @_originY).x
                end = @_canvas.width - start
                @_paintVoid(start, 0, end, @_canvas.height)

            if @_originY < 0
                @_paintVoid(0, 0, @_canvas.width, @_tileSet.tileWidth * (0 - @_originY))

            if @_originY + @_totalTilesInViewY > @_map.height
                start = @tileToCanvasCoordinate(@_originX, @_map.height).x
                end = @_canvas.height - start
                @_paintVoid(0, start, @_canvas.width, end)

            xOffset = paintData.offsetX
            yOffset = paintData.offsetY
            tilesToPaint = paintData.tileData

            for y in [0...tilesToPaint.length]
                xs = tilesToPaint[y]
                for x in [0...xs.length]
                    @_paintTile(xs[x].getValue(), (x + xOffset) * @_tileSet.tileWidth, (y + yOffset) * @_tileSet.tileWidth)
            return


        _paintAnimatedTiles: (isPaused) ->
            xMin = @_originX
            xMax = xMin + @_totalTilesInViewX + 1
            yMin = @_originY
            yMax = yMin + @_totalTilesInViewY + 1
            animatedTiles = @_animationManager.getTiles(xMin, yMin, xMax, yMax, isPaused)
            for i in [0...animatedTiles.length]
                tile = animatedTiles[i]
                @_paintTile(tile.tileValue,
                      (tile.x - xMin) * @_tileSet.tileWidth,
                      (tile.y - yMin) * @_tileSet.tileWidth)
            return


        _processSprites: (spriteList) ->
            ctx = @_canvas.getContext('2d')
            for i in [0...spriteList.length]
                sprite = spriteList[i]
                ctx.drawImage(@_spriteSheet,
                             (sprite.frame - 1) * 48,
                             (sprite.type - 1) * 48,
                             sprite.width,
                             sprite.width,
                             sprite.x + sprite.xOffset - @_originX * 16,
                             sprite.y + sprite.yOffset - @_originY * 16,
                             sprite.width,
                             sprite.width)
            return


        _processMouse: (mouse) ->
            if mouse.width == 0 or mouse.height == 0
                return

            # For outlines bigger than 2x2 (in either dimension) assume the mouse is offset by
            # one tile
            mouseX = mouse.x
            mouseY = mouse.y
            mouseWidth = mouse.width
            mouseHeight = mouse.height
            options = {colour: mouse.colour, outline: true}

            if mouseWidth > 2
                mouseX -= 1
            if mouseHeight > 2
                mouseY -= 1

            offMap = (@_originX + mouseX < 0 and @_originX + mouseX + mouseWidth <= 0) or
                     (@_originY + mouseY < 0 and @_originY + mouseY + mouseHeight <= 0) or
                     @_originX + mouseX >= @_map.width or @_originY + mouseY >= @_map.height

            if offMap then return

            pos = {x: mouseX * @_tileSet.tileWidth, y: mouseY * @_tileSet.tileWidth}
            width = mouseWidth * @_tileSet.tileWidth
            height = mouseHeight * @_tileSet.tileWidth
            MouseBox.draw(@_canvas, pos, width, height, options)


        paint: (mouse, sprites, isPaused) ->
            if arguments.length < 2 then throw new Error('Invalid parameter')
            if not @ready then throw new Error("Not ready!")

            # Change tileSet if necessary
            tileSetChanged = false
            if @_pendingTileSet != null
                @_tileSet = @_pendingTileSet
                @_pendingTileSet = null
                tileSetChanged = true

            # Make any pending dimension changes to the canvas
            dimensionsChanged = false

            if tileSetChanged or dimensionsChanged
                @_calculateMaximaAndMinima()

            # TODO Selective repainting
            needsFullPaint = true
            if @_justConstructed or @_moved or tileSetChanged
                @_justConstructed = false
                @_moved = false
                needsFullPaint = true

            mapData = @_getDataForPainting()

            if needsFullPaint
                @_fullRepaint(mapData)

            @_paintAnimatedTiles(isPaused)

            if mouse
                @_processMouse(mouse)

            if sprites
                @_processSprites(sprites)
