define ['Random', 'Tile', 'TileUtils', 'Traffic', 'ZoneUtils'], (Random, Tile, TileUtils, Traffic, ZoneUtils) ->
    # Commercial tiles have 'populations' from 1 to 5,
    # and value from 0 to 3. The tiles are laid out in
    # increasing order of land value, cycling through
    # each population value

    getZonePopulation = (map, x, y, tileValue) ->
        if tileValue instanceof Tile
            tileValue = tile.getValue()

        if tileValue == Tile.COMCLEAR
            return 0

        return Math.floor((tileValue - Tile.CZB) / 9) % 5 + 1

    placeCommercial = (map, x, y, population, lpValue, zonePower) ->
        centreTile = ((lpValue * 5) + population) * 9 + Tile.CZB
        ZoneUtils.putZone(map, x, y, centreTile, zonePower)

    doMigrationIn = (map, x, y, blockMaps, population, lpValue, zonePower) ->
        landValue = blockMaps.landValueMap.worldGet(x, y)
        landValue = landValue >> 5

        if population > landValue
            return

        # Desirable zone: migrate
        if population < 5
            placeCommercial(map, x, y, population, lpValue, zonePower)
            ZoneUtils.incRateOfGrowth(blockMaps, x, y, 8)

    doMigrationOut = (map, x, y, blockMaps, population, lpValue, zonePower) ->
        if population > 1
            placeCommercial(map, x, y, population - 2, lpValue, zonePower)
            ZoneUtils.incRateOfGrowth(blockMaps, x, y, -8)
            return

        if population == 1
            ZoneUtils.putZone(map, x, y, Tile.COMCLR, zonePower)
            ZoneUtils.incRateOfGrowth(blockMaps, x, y, -8)

    evalCommercial = (blockMaps, x, y, traffic) ->
        if traffic == Traffic.NO_ROAD_FOUND
            return -3000

        comRate = blockMaps.comRateMap.worldGet(x, y)
        return comRate

    commercialFound = (map, x, y, simData) ->
        simData.census.comZonePop += 1
        tileValue = map.getTileValue(x, y)
        tilePop = getZonePopulation(map, x, y, tileValue)
        simData.census.comPop += tilePop
        zonePower = map.getTile(x, y).isPowered()

        trafficOK = Traffic.ROUTE_FOUND
        if tilePop > Random.getRandom(5)
            # Try driving from commercial to industrial
            trafficOK = simData.trafficManager.makeTraffic(x, y, simData.blockMaps, TileUtils.isIndustrial)

            # Trigger outward migration if not connected to road network
            if trafficOK ==  Traffic.NO_ROAD_FOUND
                lpValue = ZoneUtils.getLandPollutionValue(simData.blockMaps, x, y)
                doMigrationOut(map, x, y, simData.blockMaps, tilePop, lpValue, zonePower)
                return

        # Occasionally assess and perhaps modify the tile
        if Random.getChance(7)
            locationScore = evalCommercial(simData.blockMaps, x, y, trafficOK)
            zoneScore = simData.valves.comValve + locationScore

            zoneScore = -500 if not zonePower

            if trafficOK and zoneScore > -350 and (zoneScore - 26380) > Random.getRandom16Signed()
                lpValue = ZoneUtils.getLandPollutionValue(simData.blockMaps, x, y)
                doMigrationIn(map, x, y, simData.blockMaps, tilePop, lpValue, zonePower)
                return

            if zoneScore < 350 and (zoneScore + 26380) < Random.getRandom16Signed()
                lpValue = ZoneUtils.getLandPollutionValue(simData.blockMaps, x, y)
                doMigrationOut(map, x, y, simData.blockMaps, tilePop, lpValue, zonePower)

    Commercial =
        registerHandlers: (mapScanner, repairManager) ->
            mapScanner.addAction(TileUtils.isCommercialZone, commercialFound)
        getZonePopulation: getZonePopulation

