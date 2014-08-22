define ['Direction', 'MiscUtils', 'Random', 'SpriteConstants', 'SpriteUtils', 'Tile', 'TileUtils'], \
  (Direction, MiscUtils, Random, SpriteConstants, SpriteUtils, Tile, TileUtils) ->

    perimX = [-1, 0, 1, 2, 2, 2, 1, 0,-1,-2,-2,-2]
    perimY = [-2,-2,-2,-1, 0, 1, 2, 2, 2, 1, 0,-1]

    class Traffic
        constructor: (map, spriteManager) ->
            @_map = map
            @_stack = []
            @_spriteManager = spriteManager

        makeTraffic: (x, y, blockMaps, destFn) ->
            @_stack = []
            pos = new @_map.Position(x, y)
            if @findPerimeterRoad(pos) and @tryDrive(pos, destFn)
                @addToTrafficDensityMap(blockMaps)
                return Traffic.ROUTE_FOUND
            else
                return Traffic.NO_ROAD_FOUND

        addToTrafficDensityMap: (blockMaps) ->
            trafficDensityMap = blockMaps.trafficDensityMap
            while @_stack.length > 0
                pos = @_stack.pop()
                # Could this happen?!?
                if not @_map.testBounds(pos.x, pos.y)
                    continue
                tileValue = @_map.getTileValue(pos.x, pos.y)
                if tileValue >= Tile.ROADBASE and tileValue < Tile.POWERBASE
                    # Update traffic density.
                    traffic = trafficDensityMap.worldGet(pos.x, pos.y)
                    traffic += 50
                    traffic = Math.min(traffic, 240)
                    trafficDensityMap.worldSet(pos.x, pos.y, traffic)

                    # Attract traffic copter to the traffic
                    if traffic >= 240 and Random.getRandom(5) == 0
                        sprite = @_spriteManager.getSprite(SpriteConstants.SPRITE_HELICOPTER)
                        if sprite != null
                            sprite.destX = SpriteUtils.worldToPix(pos.x)
                            sprite.destY = SpriteUtils.worldToPix(pos.y)

        findPerimeterRoad: (pos) ->
            for i in [0...12]
                xx = pos.x + perimX[i]
                yy = pos.y + perimY[i]

                if @_map.testBounds(xx, yy)
                    if TileUtils.isDriveable(@_map.getTileValue(xx, yy))
                        pos.x = xx
                        pos.y = yy
                        return true
