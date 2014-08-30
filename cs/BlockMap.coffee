define [], () ->
    class BlockMap
        constructor: (mapWidth, mapHeight, blockSize, defaultValue) ->
            id = (x) -> x
            e = new Error('Invalid parameters')
            if arguments.length < 3
                if not (mapWidth instanceof BlockMap) or
                   (arguments.length == 2 and typeof(mapHeight) != 'function')
                    throw e
                sourceMap = mapWidth
                # PVL FIXME is mapHeight a function?
                sourceFunction = if mapHeight == undefined then id else mapHeight
            if sourceMap != undefined
                mapWidth = sourceMap.width
                mapHeight = sourceMap.height
                blockSize = sourceMap.blockSize
                defaultValue = sourceMap.defaultValue

            @data = []

            if (sourceMap)
                @copyFrom(sourceMap, sourceFunction)
            else
                @clear()

        copyFrom: (sourceMap, sourceFn) ->
            mapFn = (elem) -> sourceFn(elem)
            for y in [0...sourceMap.data.length]
                @data[y] = sourceMap.data[y].map(mapFn)
            return

        makeArrayOf: (length, value) ->
            result = []
            for a in [0...length]
                result[a] = value
            return result

        clear: ->
            maxY = Math.floor(@mapHeight / @blockSize) + 1
            maxX = Math.floor(@mapWidth / @blockSize) + 1
            for y in [0...maxY]
                @data[y] = @makeArrayOf(maxX, @defaultValue)

        get: (x, y) -> @data[y][x]

        set: (x, y, value) -> @data[y][x] = value

        toBlock: (num) -> Math.floor(num / @blockSize)

        worldGet: (x, y) -> @get(@toBlock(x), @toBlock(y))

        worldSet: (x, y, value) -> @set(@toBlock(x), @toBlock(y), value)

