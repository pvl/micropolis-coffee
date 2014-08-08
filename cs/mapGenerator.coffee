
define ['Direction', 'GameMap', 'Random', 'Tile'], (Direction, GameMap, Random, Tile) ->
    TERRAIN_CREATE_ISLAND;
    TERRAIN_TREE_LEVEL = -1;
    TERRAIN_LAKE_LEVEL = -1;
    TERRAIN_CURVE_LEVEL = 0;
    ISLAND_RADIUS = 18;

    generateMap = (w,h) ->
        w = w or 120
        h = h or 100

        TERRAIN_CREATE_ISLAND = Random.getRandom(2) - 1

        map = new GameMap w,h
        #Construct land
        if TERRAIN_CREATE_ISLAND < 0
            if Random.getRandom(100) < 10
                makeIsland map
                return map

        if TERRAIN_CREATE_ISLAND == 1
            makeNakedIsland map
        else
            clearMap map
        #Lay a river
        if TERRAIN_CURVE_LEVEL != 0
            terrainXStart = 40 + Random.getRandom(map.width - 80)
            terrainYStart = 33 + Random.getRandom(map.height - 67)
            terrainPos = new map.Position terrainXStart, terrainYStart
            doRivers map, terrainPos
        #Lay a few lakes
        if TERRAIN_LAKE_LEVEL != 0
            makeLakes map

        smoothRiver map
        #And add trees
        if TERRAIN_TREE_LEVEL != 0
            doTrees map

        return map

    clearMap = (map) ->
        for x in [0...map.width]
            for y in [0...map.height]
                tileValue = map.getTileValue x,y
                if tileValue > Tile.WOODS
                    map.setTo x,y,new Tile(Tile.DIRT)

    makeNakedIsland = (map) ->
        terrainIslandRadius = ISLAND_RADIUS
        for x in [0...map.width]
            for y in [0...map.height]
                if x < 5 or x >= map.width-5 or y < 5 or y >= map.height-5
                    map.setTo x,y,new Tile(Tile.RIVER)
                else
                    map.setTo x,y,new Tile(Tile.DIRT)

        for x in [0...(map.width-5)] by 2
            mapY = Random.getERandom terrainIslandRadius
            plopBRiver map, new map.Position(x,mapY)
            mapY = map.height - 10 - Random.getERandom(terrainIslandRadius)
            plopBRiver map, new map.Position(x, mapY)

            plopSRiver map, new map.Position(x, 0)
            plopSRiver map, new map.Position(x, map.height - 6)

        for y in [0...(map.height-5)] by 2
            mapX = Random.getERandom terrainIslandRadius
            plopBRiver map, new map.Position(mapX, y)
            mapX = map.width - 10 - Random.getERandom(terrainIslandRadius)
            plopBRiver map, new map.Position(mapX, y)
            plopSRiver map, new map.Position(0, y)
            plopSRiver map, new map.Position(map.width - 6, y)

    makeIsland = (map) ->
        makeNakedIsland map
        smoothRiver map
        doTrees map

    makeLakes = (map) ->
        if TERRAIN_LAKE_LEVEL < 0
            numLakes = Random.getRandom(10)
        else
            numLakes = TERRAIN_LAKE_LEVEL / 2
        while numLakes > 0
            x = Random.getRandom(map.width - 21) + 10
            y = Random.getRandom(map.height - 20) + 10
            makeSingleLake map, new map.Position(x, y)
            numLakes--

    makeSingleLake = (map, pos) ->
        numPlops = Random.getRandom(12) + 2
        while numPlops > 0
            plopPos = new map.Position pos, Random.getRandom(12)-6, Random.getRandom(12)-6
            if Random.getRandom(4)
                plopSRiver map, plopPos
            else
                plopBRiver map, plopPos
            numPlops--

    treeSplash = (map, x, y) ->
        if TERRAIN_TREE_LEVEL < 0
            numTrees = Random.getRandom(150) + 50
        else
            numTrees = Random.getRandom(100 + (TERRAIN_TREE_LEVEL * 2)) + 50

        treePos = new map.Position(x, y)
        while numTrees > 0
            dir = Direction.NORTH + Random.getRandom(7)
            treePos.move(dir)
            #XXX Should use the fact that positions return success/failure for moves
            if not map.testBounds(treePos.x, treePos.y)
                return
            if map.getTileValue(treePos) == Tile.DIRT
                map.setTo treePos, new Tile(Tile.WOODS, Tile.BLBNBIT)
            numTrees--

    doTrees = (map) ->
        if TERRAIN_TREE_LEVEL < 0
            amount = Random.getRandom(100) + 50
        else
            amount = TERRAIN_TREE_LEVEL + 3
        for x in [0...amount]
            xloc = Random.getRandom(map.width - 1)
            yloc = Random.getRandom(map.height - 1)
            treeSplash map, xloc, yloc
        smoothTrees map
        smoothTrees map

    smoothRiver = (map) ->
        dx = [-1,  0,  1,  0]
        dy = [0,  1,  0, -1]
        riverEdges = [
            13 | Tile.BULLBIT, 13 | Tile.BULLBIT, 17 | Tile.BULLBIT, 15 | Tile.BULLBIT,
            5 | Tile.BULLBIT, 2, 19 | Tile.BULLBIT, 17 | Tile.BULLBIT,
            9 | Tile.BULLBIT, 11 | Tile.BULLBIT, 2, 13 | Tile.BULLBIT,
            7 | Tile.BULLBIT, 9 | Tile.BULLBIT, 5 | Tile.BULLBIT, 2]

        for x in [0...map.width]
            for y in [0...map.height]
                if map.getTileValue(x, y) == Tile.REDGE
                    bitIndex = 0
                    for z in [0...4]
                        bitIndex = bitIndex << 1
                        xTemp = x + dx[z]
                        yTemp = y + dy[z]
                        if map.testBounds(xTemp, yTemp) and
                           map.getTileValue(xTemp, yTemp) != Tile.DIRT and
                           (map.getTileValue(xTemp, yTemp) < Tile.WOODS_LOW or
                           map.getTileValue(xTemp, yTemp) > Tile.WOODS_HIGH)
                            bitIndex++
                    temp = riverEdges[bitIndex & 15]
                    if temp != Tile.RIVER and Random.getRandom(1)
                        temp++
                    map.setTo x, y, new Tile(temp)

    isTree = (tileValue) ->
        tileValue >= Tile.WOODS_LOW and tileValue <= Tile.WOODS_HIGH

    smoothTrees = (map) ->
        for x in [0...map.width]
            for y in [0...map.height]
                if isTree(map.getTileValue(x, y))
                    smoothTreesAt map, x, y, false

    smoothTreesAt = (map, x, y, preserve) ->
        dx = [-1,  0,  1,  0 ]
        dy = [ 0,  1,  0, -1 ]
        treeTable = [
            0,  0,  0,  34,
            0,  0,  36, 35,
            0,  32, 0,  33,
            30, 31, 29, 37]

        if not isTree(map.getTileValue(x, y))
            return

        bitIndex = 0
        for i in [0...4]
            bitIndex = bitIndex << 1
            xTemp = x + dx[i]
            yTemp = y + dy[i]
            if map.testBounds(xTemp, yTemp) and isTree(map.getTileValue(xTemp, yTemp))
                bitIndex++

        temp = treeTable[bitIndex & 15]
        if temp
            if temp != Tile.WOODS and ((x+y) & 1)
                temp = temp - 8
            map.setTo x, y, new Tile(temp, Tile.BLBNBIT)
        else
            if not preserve
                map.setTo x, y, new Tile(temp)

    doRivers = (map, terrainPos) ->
        riverDir = Direction.NORTH + Random.getRandom(3) * 2
        doBRiver(map, terrainPos, riverDir, riverDir)
        riverDir = Direction.rotate180(riverDir)
        terrainDir = doBRiver(map, terrainPos, riverDir, riverDir)
        riverDir = Direction.NORTH + Random.getRandom(3) * 2
        doSRiver(map, terrainPos, riverDir, terrainDir)

    doBRiver = (map, riverPos, riverDir, terrainDir) ->
        if TERRAIN_CURVE_LEVEL < 0
            rate1 = 100
            rate2 = 200
        else
            rate1 = TERRAIN_CURVE_LEVEL + 10
            rate2 = TERRAIN_CURVE_LEVEL + 100
        pos = new map.Position riverPos
        while map.testBounds(pos.x + 4, pos.y + 4)
            plopBRiver map, pos
            if Random.getRandom(rate1) < 10
                terrainDir = riverDir
            else
                if Random.getRandom(rate2) > 90
                    terrainDir = Direction.rotate45 terrainDir
                if Random.getRandom(rate2) > 90
                    terrainDir = Direction.rotate45 terrainDir, 7
            pos.move terrainDir
        return terrainDir

    doSRiver = (map, riverPos, riverDir, terrainDir) ->
        if TERRAIN_CURVE_LEVEL < 0
            rate1 = 100;
            rate2 = 200;
        else
            rate1 = TERRAIN_CURVE_LEVEL + 10
            rate2 = TERRAIN_CURVE_LEVEL + 100

        pos = new map.Position riverPos
        while map.testBounds(pos.x + 3, pos.y + 3)
            plopSRiver map, pos
            if Random.getRandom(rate1) < 10
                terrainDir = riverDir
            else
                if Random.getRandom(rate2) > 90
                    terrainDir = Direction.rotate45 terrainDir
                if Random.getRandom(rate2) > 90
                    terrainDir = Direction.rotate45 terrainDir, 7
            pos.move terrainDir
        return terrainDir

    putOnMap = (map, newVal, x, y) ->
        if newVal == 0
            return
        if not map.testBounds(x, y)
            return
        tileValue = map.getTileValue x, y
        if tileValue != Tile.DIRT
            if tileValue == Tile.RIVER
                if newVal != Tile.CHANNEL
                    return
            if tileValue == Tile.CHANNEL
                return
        map.setTo x, y, new Tile(newVal)

    plopBRiver = (map, pos) ->
        BRMatrix = [
            [0, 0, 0, Tile.REDGE, Tile.REDGE, Tile.REDGE, 0, 0, 0],
            [0, 0, Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.REDGE, 0, 0],
            [0, Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.REDGE, 0],
            [Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.REDGE],
            [Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.CHANNEL, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.REDGE],
            [Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.REDGE],
            [0, Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.REDGE, 0],
            [0, 0, Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.REDGE, 0, 0],
            [0, 0, 0, Tile.REDGE, Tile.REDGE, Tile.REDGE, 0, 0, 0]]

        for x in [0...9]
            for y in [0...9]
                putOnMap map, BRMatrix[y][x], pos.x + x, pos.y + y

    plopSRiver = (map, pos) ->
        SRMatrix = [
            [0, 0, Tile.REDGE, Tile.REDGE, 0, 0],
            [0, Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.REDGE, 0],
            [Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.REDGE],
            [Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.RIVER, Tile.REDGE],
            [0, Tile.REDGE, Tile.RIVER, Tile.RIVER, Tile.REDGE, 0],
            [0, 0, Tile.REDGE, Tile.REDGE, 0, 0]]

        for x in [0...6]
            for y in [0...6]
                putOnMap map, SRMatrix[y][x], pos.x + x, pos.y + y

    smoothWater = (map) ->
        for x in [0...map.width]
            for y in [0...map.height]
                tile = map.getTileValue x, y
                if tile >= Tile.WATER_Tile.LOW and tile <= Tile.WATER_Tile.HIGH
                    pos = new map.Position x, y

                    for dir in [Direction.BEGIN...Direction.END] by Direction.increment90(dir)
                        tile = map.getTileFromMap pos, dir, Tile.WATER_LOW

                        # If nearest object is not water:
                        if tile < Tile.WATER_LOW or tile > Tile.WATER_HIGH
                            map.setTo x, y, new Tile(Tile.REDGE) #set river edge
                            break #Continue with next tile

        for x in [0...map.width]
            for y in [0...map.height]
                tile = map.getTileValue x, y

                if tile != Tile.CHANNEL or tile >= Tile.WATER_LOW or tile <= Tile.WATER_HIGH
                    makeRiver = true

                    pos = new map.Position x, y
                    for dir in [Direction.BEGIN...Direction.END] by Direction.increment90(dir)
                        tile = map.getTileFromMap pos, dir, Tile.WATER_LOW

                        if tile < Tile.WATER_LOW or tile > Tile.WATER_HIGH
                            makeRiver = false
                            break

                    map.setTo(x, y, new Tile(Tile.RIVER)) if makeRiver

        for x in [0...map.width]
            for y in [0...map.height]
                tile = map.getTileValue x, y

        if tile >= Tile.WOODS_LOW and tile <= Tile.WOODS_HIGH
            pos = new map.Position x, y
            for dir in [Direction.BEGIN...Direction.END] by Direction.increment90(dir)
                tile = map.getTileFromMap pos, dir, TILE_INVALID

                if tile == Tile.RIVER or tile == Tile.CHANNEL
                    map.setTo x, y, new Tile(Tile.REDGE) #make it water's edge
                    break

    return generateMap
