define ['Direction', 'MiscUtils', 'PositionMaker', 'Tile'], (Direction, MiscUtils, PositionMaker, Tile) ->

    class GameMap
        constructor: (width, height, defaultValue) ->
            if not (this instanceof GameMap)
                return new GameMap(width, height, defaultValue)
            e = new Error('Invalid parameter')
            if arguments.length > 1 and typeof(width) == 'number' and
               (width < 1 or height < 1)
                throw e

            # Argument shuffling
            if arguments.length == 0
                width = 120
                height = 100
                defaultValue = new Tile().getValue()
            else if arguments.length == 1
                if typeof(width) == 'number'
                    # Default value
                    defaultValue = width
                else
                    # Tile
                    defaultValue = width.getValue()
                width = 120
                height = 100
            else if arguments.length == 2
                defaultValue = new Tile().getValue()
            else if arguments.length == 3
                if typeof(defaultValue) == 'object'
                    defaultValue = defaultValue.getValue()

            @Position = PositionMaker(width, height)
            Object.defineProperties(this,
                {width: MiscUtils.makeConstantDescriptor(width),
                height:MiscUtils.makeConstantDescriptor(height)})

            @defaultValue = defaultValue
            @_data = []
            # Generally set externally
            @cityCentreX = Math.floor(@width / 2)
            @cityCentreY = Math.floor(@height / 2)
            @pollutionMaxX = @cityCentreX
            @pollutionMaxY = @cityCentreY

        _calculateIndex: (x, y) -> x + y * @width

        testBounds: (x, y) ->
            x >= 0 and y >= 0 and x < @width and y < @height

        getTile: (x, y) ->
            e = new Error('Invalid parameter')
            if arguments.length < 1 then throw e
            # Argument-shuffling
            if typeof(x) == 'object'
                y = x.y
                x = x.x
            if not @testBounds(x, y) then throw e
            tileIndex = @_calculateIndex(x, y)
            if not (tileIndex of @_data)
                @_data[tileIndex] = new Tile(@defaultValue)
            return @_data[tileIndex]

        getTileValue: (x, y) -> @getTile(x,y).getValue()

        getTileFlags: (x, y) -> @getTile(x,y).getFlags()

        getTiles: (x, y, w, h) ->
            e = new Error('Invalid parameter')
            if arguments.length < 3 then throw e
            # Argument-shuffling
            if arguments.length == 3
                y = x.y
                x = x.x
                h = w
                w = y
            if not @testBounds(x, y) then throw e
            res = []
            for a in [y...(y + h)]
                res[a-y] = []
                for b in [x...(x + w)]
                    tileIndex = @_calculateIndex(b, a)
                    if not (tileIndex of @_data)
                        @_data[tileIndex] = new Tile(@defaultValue)
                    res[a-y].push(@_data[tileIndex])
            return res

        getTileValues: (x, y, w, h) ->
            tile.getValue() for tile in @getTiles(x,y,w,h)

        getTileFromMapOrDefault: (pos, dir, defaultTile) ->
            switch dir
                when Direction.NORTH
                    if pos.y > 0
                        return @getTileValue(pos.x, pos.y - 1)
                when Direction.EAST
                    if pos.x < @width - 1
                        return @getTileValue(pos.x + 1, pos.y)
                when Direction.SOUTH
                    if pos.y < @height - 1
                        return @getTileValue(pos.x, pos.y + 1)
                when Direction.WEST
                    if pos.x > 0
                        return @getTileValue(pos.x - 1, pos.y)
            return defaultTile

        setTile: (x, y, value, flags) ->
            e = new Error('Invalid parameter')
            if arguments.length < 3 then throw e
            # Argument-shuffling
            if arguments.length == 3
                flags = value
                value = y
                y = x.y
                x = x.x
            if not @testBounds(x, y) then throw e
            tileIndex = @_calculateIndex(x, y)
            if not (tileIndex of @_data)
                @_data[tileIndex] = new Tile(@defaultValue)
            @_data[tileIndex].set(value, flags)

        setTo: (x, y, tile) ->
            e = new Error('Invalid parameter')
            if arguments.length < 2 then throw e
            # Argument-shuffling
            if tile == undefined
                tile = y
                y = x.y
                x = x.x
            if not @testBounds(x, y) then throw e
            tileIndex = @_calculateIndex(x, y)
            @_data[tileIndex] = tile

        setTileValue: (x, y, value) ->
            e = new Error('Invalid parameter')
            if arguments.length < 2 then throw e
            # Argument-shuffling
            if arguments.length == 2
                value = y
                y = x.y
                x = x.x
            tile = @getTile(x,y)
            tile.setValue(value)

        setTileFlags: (x, y, flags) ->
            e = new Error('Invalid parameter')
            if arguments.length < 2 then throw e
            # Argument-shuffling
            if arguments.length == 2
                value = y
                y = x.y
                x = x.x
            tile = @getTile(x,y)
            tile.setFlags(flags)

        addTileFlags: (x, y, flags) ->
            e = new Error('Invalid parameter')
            if arguments.length < 2 then throw e
            # Argument-shuffling
            if arguments.length == 2
                value = y
                y = x.y
                x = x.x
            tile = @getTile(x,y)
            tile.addFlags(flags)

        removeTileFlags: (x, y, flags) ->
            e = new Error('Invalid parameter')
            if arguments.length < 2 then throw e
            # Argument-shuffling
            if arguments.length == 2
                value = y
                y = x.y
                x = x.x
            tile = @getTile(x,y)
            tile.removeFlags(flags)

        putZone: (centreX, centreY, centreTile, size) ->
            e = new Error('Invalid parameter')
            if not @testBounds(centreX, centreY) or not @testBounds(centreX - 1 + size, centreY - 1 + size)
                throw e
            tile = centreTile - 1 - size
            startX = centreX - 1
            startY = centreY - 1
            for y in [startY...(startY + size)]
                for x in [startX...(startX + size)]
                    if x == centreX and y == centreY
                        @setTo(x, y, new Tile(tile, Tile.BNCNBIT | Tile.ZONEBIT))
                    else
                        @setTo(x, y, new Tile(tile, Tile.BNCNBIT))
                    tile += 1


