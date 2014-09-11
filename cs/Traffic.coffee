define ['Direction', 'Random', 'SpriteConstants', 'SpriteUtils', 'Tile', 'TileUtils'], \
  (Direction, Random, SpriteConstants, SpriteUtils, Tile, TileUtils) ->

    perimX = [-1, 0, 1, 2, 2, 2, 1, 0,-1,-2,-2,-2]
    perimY = [-2,-2,-2,-1, 0, 1, 2, 2, 2, 1, 0,-1]

    MAX_TRAFFIC_DISTANCE = 30

    class Traffic

        @ROUTE_FOUND: 1
        @NO_ROUTE_FOUND: 0
        @NO_ROAD_FOUND: -1

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
            return false


        tryDrive: (startPos, destFn) ->
            dirLast = Direction.INVALID
            drivePos = new @_map.Position(startPos)

            # Maximum distance to try
            dist = 0
            while dist < MAX_TRAFFIC_DISTANCE
                dir = @tryGo(drivePos, dirLast)
                if dir != Direction.INVALID
                    drivePos.move(dir)
                    dirLast = Direction.rotate180(dir)
                    @_stack.push(new @_map.Position(drivePos)) if dist & 1
                    return true if @driveDone(drivePos, destFn)
                else
                    if @_stack.length > 0
                        @_stack.pop()
                        dist += 3
                    else
                        return false
                dist++
            return false


        tryGo: (pos, dirLast) ->
            directions = []

            # Find connections from current position.
            dir = Direction.NORTH
            count = 0

            for i in [0...4]
                if dir != dirLast and TileUtils.isDriveable(@_map.getTileFromMapOrDefault(pos, dir, Tile.DIRT))
                    # found a road in an allowed direction
                    directions[i] = dir
                    count++
                else
                    directions[i] = Direction.INVALID
                dir = Direction.rotate90(dir)

            if count == 0
                return Direction.INVALID

            if count == 1
                for i in [0...4]
                    if directions[i] != Direction.INVALID
                        return directions[i]

            i = Random.getRandom16() & 3
            while directions[i] == Direction.INVALID
                i = (i + 1) & 3

            return directions[i]


        driveDone: (pos, destFn) ->
            if pos.y > 0
                if destFn(@_map.getTileValue(pos.x, pos.y - 1))
                    return true

            if pos.x < (@_map.width - 1)
                if destFn(@_map.getTileValue(pos.x + 1, pos.y))
                    return true

            if pos.y < (@_map.height - 1)
                if destFn(@_map.getTileValue(pos.x, pos.y + 1))
                    return true

            if pos.x > 0
                if destFn(@_map.getTileValue(pos.x - 1, pos.y))
                    return true

            return false
