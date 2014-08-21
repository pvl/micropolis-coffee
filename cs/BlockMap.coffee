define ['MiscUtils'], (MiscUtils) ->
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

            Object.defineProperties(this,
                { mapWidth: MiscUtils.makeConstantDescriptor(mapWidth),
                mapHeight: MiscUtils.makeConstantDescriptor(mapHeight),
                width: MiscUtils.makeConstantDescriptor(Math.floor((mapWidth  + 1) / blockSize)),
                height: MiscUtils.makeConstantDescriptor(Math.floor((mapHeight + 1)/ blockSize)),
                blockSize: MiscUtils.makeConstantDescriptor(blockSize),
                defaultValue: MiscUtils.makeConstantDescriptor(defaultValue)})

            this.data = []

            if (sourceMap)
                @copyFrom(sourceMap, sourceFunction)
            else
                this.clear()

        copyFrom: (sourceMap, sourceFn) ->
            mapFn = (elem) -> sourceFn(elem)
            for y in [0...sourceMap.data.length]
                this.data[y] = sourceMap.data[y].map(mapFn)
            return null

        makeArrayOf: (length, value) ->
            result = []
            for a in [0...length]
                result[a] = value
            return result

        clear: ->
            maxY = Math.floor(this.mapHeight / this.blockSize) + 1
            maxX = Math.floor(this.mapWidth / this.blockSize) + 1
            for y in [0...maxY]
                this.data[y] = @makeArrayOf(maxX, this.defaultValue)

        get: (x, y) -> this.data[y][x]

        set: (x, y, value) -> data[y][x] = value

        toBlock: (num) -> Math.floor(num / this.blockSize)

        worldGet: (x, y) -> this.get(this.toBlock(x), this.toBlock(y))

        worldSet: (x, y, value) -> this.set(this.toBlock(x), this.toBlock(y), value)

