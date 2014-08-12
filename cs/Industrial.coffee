define ['Random', 'Tile', 'TileUtils', 'Traffic', 'ZoneUtils'], (Random, Tile, TileUtils, Traffic, ZoneUtils) ->
    # Industrial tiles have 'populations' from 1 to 4,
    # and value from 0 to 3. The tiles are laid out in
    # increasing order of land value, cycling through
    # each population value
    getZonePopulation = (map, x, y, tileValue) ->
        if tileValue instanceof Tile
            tileValue = tile.getValue()

        if tileValue == Tile.INDCLR
            return 0

        return Math.floor((tileValue - Tile.IZB) / 9) % 4 + 1

    placeIndustrial = (map, x, y, population, lpValue, zonePower) ->
        centreTile = ((lpValue * 4) + population) * 9 + Tile.IZB
        ZoneUtils.putZone(map, x, y, centreTile, zonePower)

    doMigrationIn = (map, x, y, blockMaps, population, lpValue, zonePower) ->
        if population < 4
            placeIndustrial(map, x, y, population, lpValue, zonePower)
            ZoneUtils.incRateOfGrowth(blockMaps, x, y, 8)

    doMigrationOut = (map, x, y, blockMaps, population, lpValue, zonePower) ->
        if population > 1
            placeIndustrial(map, x, y, population - 2, lpValue, zonePower)
            ZoneUtils.incRateOfGrowth(blockMaps, x, y, -8)
            return

        if population == 1
            ZoneUtils.putZone(map, x, y, Tile.INDCLR, zonePower)
            ZoneUtils.incRateOfGrowth(blockMaps, x, y, -8)

    evalIndustrial = (blockMaps, x, y, traffic) ->
        if traffic == Traffic.NO_ROAD_FOUND
            return -1000
        return 0

    animated = [true, false, true, true, false, false, true, true]
    xDelta = [-1, 0, 1, 0, 0, 0, 0, 1]
    yDelta = [-1, 0, -1, -1, 0, 0, -1, -1]

    setSmoke = (map, x, y, tileValue, isPowered) ->
        if tileValue < Tile.IZB
            return

        # There are only 7 different types of populated industrial zones.
        # As tileValue - IZB will never be 8x9 or more away from IZB, we
        # can shift right by 3, and get the same effect as dividing by 9
        i = (tileValue - Tile.IZB) >> 3
        if animated[i] and isPowered
            map.addTileFlags(x + xDelta[i], y + yDelta[i], Tile.ASCBIT)
        else
            map.addTileFlags(x + xDelta[i], y + yDelta[i], Tile.BNCNBIT)
            map.removeTileFlags(x + xDelta[i], y + yDelta[i], Tile.ANIMBIT)

    industrialFound = (map, x, y, simData) ->
        simData.census.indZonePop += 1
        tileValue = map.getTileValue(x, y)
        tilePop = getZonePopulation(map, x, y, tileValue)
        simData.census.indPop += tilePop

        # Set animation bit if appropriate
        zonePower = map.getTile(x, y).isPowered()
        setSmoke(map, x, y, tileValue, zonePower)

        trafficOK = Traffic.ROUTE_FOUND
        if tilePop > Random.getRandom(5)
          # Try driving from industrial to residential
          trafficOK = simData.trafficManager.makeTraffic(x, y, simData.blockMaps, TileUtils.isResidential)

          # Trigger outward migration if not connected to road network
          if trafficOK ==  Traffic.NO_ROAD_FOUND
              doMigrationOut(map, x, y, simData.blockMaps, tilePop, Random.getRandom16() & 1, zonePower)
              return
        # Occasionally assess and perhaps modify the tile
        if Random.getChance(7)
            locationScore = evalIndustrial(simData.blockMaps, x, y, trafficOK)
            zoneScore = simData.valves.indValve + locationScore

            zoneScore = -500 if not zonePower

            if trafficOK and zoneScore > -350 and
               (zoneScore - 26380) > Random.getRandom16Signed()
                doMigrationIn(map, x, y, simData.blockMaps, tilePop, Random.getRandom16() & 1, zonePower)
                return

            if zoneScore < 350 and (zoneScore + 26380) < Random.getRandom16Signed()
                doMigrationOut(map, x, y, simData.blockMaps, tilePop, Random.getRandom16() & 1, zonePower)

    Industrial =
        registerHandlers: (mapScanner, repairManager) ->
            mapScanner.addAction(TileUtils.isIndustrialZone, industrialFound)
        getZonePopulation: getZonePopulation

