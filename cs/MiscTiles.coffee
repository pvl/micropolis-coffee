define ['Random', 'Tile', 'TileUtils', 'ZoneUtils'], (Random, Tile, TileUtils, ZoneUtils) ->

    xDelta = [-1,  0,  1,  0 ]
    yDelta = [ 0, -1,  0,  1 ]

    fireFound = (map, x, y, simData) ->
        simData.census.firePop += 1

        if (Random.getRandom16() & 3) != 0
            return

        # Try to set neighbouring tiles on fire as well
        for i in [0...4]
            if Random.getChance(7)
                xTem = x + xDelta[i]
                yTem = y + yDelta[i]

                if map.testBounds(xTem, yTem)
                    tile = map.getTile(x, y)
                    if not tile.isCombustible()
                        continue

                    if tile.isZone()
                        # Neighbour is a ione and burnable
                        ZoneUtils.fireZone(map, x, y, simData.blockMaps)

                        # Industrial zones etc really go boom
                        if tile.getValue() > Tile.IZB
                            simData.spriteManager.makeExplosionAt(x, y)

                    map.setTo(tileUtils.randomFire())
        # Compute likelyhood of fire running out of fuel
        rate = 10 # Likelyhood of extinguishing (bigger means less chance)
        i = simData.blockMaps.fireStationEffectMap.worldGet(x, y)

        if i > 100
          rate = 1
        else if i > 20
          rate = 2
        else if i > 0
          rate = 3

        # Decide whether to put out the fire.
        if Random.getRandom(rate) == 0
            map.setTo(x, y, TileUtils.randomRubble())

    radiationFound = (map, x, y, simData) ->
        if Random.getChance(4095)
            map.setTo(x, y, new Tile(Tile.DIRT))

    floodFound = (map, x, y, simData) ->
        simData.disasterManager.doFlood(x, y, simData.blockMaps)

    explosionFound = (map, x, y, simData) ->
        tileValue = map.getTileValue(x, y)
        map.setTo(x, y, TileUtils.randomRubble())
        return

    MiscTiles =
        registerHandlers: (mapScanner, repairManager) ->
            mapScanner.addAction(TileUtils.isFire, fireFound, true)
            mapScanner.addAction(Tile.RADTILE, radiationFound, true)
            mapScanner.addAction(TileUtils.isFlood, floodFound, true)
            mapScanner.addAction(TileUtils.isManualExplosion, explosionFound, true)



