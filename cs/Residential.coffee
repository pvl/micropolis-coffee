define ['Random', 'Tile', 'TileUtils', 'Traffic', 'ZoneUtils'], (Random, Tile, TileUtils, Traffic, ZoneUtils) ->

    # Residential tiles have 'populations' of 16, 24, 32 or 40
    # and value from 0 to 3. The tiles are laid out in
    # increasing order of land value, cycling through
    # each population value
    placeResidential = (map, x, y, population, lpValue, zonePower) ->
        centreTile = ((lpValue * 4) + population) * 9 + Tile.RZB
        ZoneUtils.putZone(map, x, y, centreTile, zonePower)


    # Look for housing in the adjacent 8 tiles
    getFreeZonePopulation = (map, x, y, tileValue) ->
        count = 0
        for xx in [(x-1)..(x+1)]
            for yy in [(y-1)..(y+1)]
                if xx == x and yy == y
                    continue
                tileValue = map.getTileValue(xx, yy)
                if tileValue >= Tile.LHTHR and tileValue <= Tile.HHTHR
                    count += 1
        return count

    getZonePopulation = (map, x, y, tileValue) ->
        if tileValue instanceof Tile
            tileValue = tile.getValue()

        if tileValue == Tile.FREEZ
            return getFreeZonePopulation(map, x, y, tileValue)

        populationIndex = Math.floor((tileValue - Tile.RZB) / 9) % 4 + 1
        return populationIndex * 8 + 16

    # Assess a tile for suitability for a house. Prefer tiles near roads
    evalLot = (map, x, y) ->
        xDelta = [0, 1, 0, -1]
        yDelta = [-1, 0, 1, 0]

        tileValue = map.getTileValue(x, y)
        if tileValue < Tile.RESBASE or tileValue > Tile.RESBASE + 8
            return -1

        score = 1
        for i in [0...4]
            tileValue = map.getTileValue(x + xDelta[i], y + yDelta[i])
            if tileValue != Tile.DIRT and tileValue <= Tile.LASTROAD
                score += 1
        return score

    buildHouse = (map, x, y, lpValue) ->
        best = 0
        bestScore = 0

        # Deliberately ordered so that the centre tile is at index 0
        xDelta = [0, -1, 0, 1, -1, 1, -1, 0, 1]
        yDelta = [0, -1, -1, -1, 0, 0, 1, 1, 1]

        for i in [0...9]
            xx = x + xDelta[i]
            yy = y + yDelta[i]

            score = evalLot(map, xx, yy)
            if score > bestScore
                bestScore = score
                best = i
            else if score == bestScore and Random.getChance(7)
                #Ensures we don't always select the same position when we
                #have a choice
                best = i

        if (best > 0)
            map.setTo(x + xDelta[best], y + yDelta[best],
                new Tile(Tile.HOUSE + Random.getRandom(2) + lpValue * 3, Tile.BLBNCNBIT))

    doMigrationIn = (map, x, y, blockMaps, population, lpValue, zonePower) ->
        pollution = blockMaps.pollutionDensityMap.worldGet(x, y)

        # Cough! Too polluted noone wants to move here!
        if pollution > 128
            return

        tileValue = map.getTileValue(x, y)

        if tileValue == Tile.FREEZ
            if population < 8
                # Zone capacity not yet reached: build another house
                buildHouse(map, x, y, lpValue)
                ZoneUtils.incRateOfGrowth(blockMaps, x, y, 1)
                return

            if blockMaps.populationDensityMap.worldGet(x, y) > 64
                # There is local demand for higher density housing
                placeResidential(map, x, y, 0, lpValue, zonePower)
                ZoneUtils.incRateOfGrowth(blockMaps, x, y, 8)
                return
        if population < 40
            # Zone population not yet maxed out
            placeResidential(map, x, y, Math.floor(population / 8) - 1, lpValue, zonePower)
            ZoneUtils.incRateOfGrowth(blockMaps, x, y, 8)

    freeZone = [0, 3, 6, 1, 4, 7, 2, 5, 8]

    doMigrationOut = (map, x, y, blockMaps, population, lpValue, zonePower) ->
        if population == 0
            return

        if population > 16
            # Degrade to a lower density block
            placeResidential(map, x, y, Math.floor((population - 24) / 8), lpValue, zonePower)
            ZoneUtils.incRateOfGrowth(blockMaps, x, y, -8)
            return

        if population == 16
            # Already at lowest density: degrade to 8 individual houses
            map.setTo(x, y, new Tile(Tile.FREEZ, Tile.BLBNCNBIT | Tile.ZONEBIT))
            for yy in [(y-1)..(y+1)]
                for xx in [(x-1)..(x+1)]
                    if xx == x and yy == y
                        continue
                    map.setTo(x, y, new Tile(Tile.LHTHR + lpValue + Random.getRandom(2), Tile.BLBNCNBIT))

            ZoneUtils.incRateOfGrowth(blockMaps, x, y, -8)
            return

        # Already down to individual houses. Remove one
        i = 0
        ZoneUtils.incRateOfGrowth(blockMaps, x, y, -1)

        for xx in [(x-1)..(x+1)]
            for yy in [(y-1)..(y+1)]
                currentValue = map.getTileValue(xx, yy)
                if currentValue >= Tile.LHTHR and currentValue <= Tile.HHTHR
                    # We've found a house. Replace it with the normal free zone tile
                    map.setTo(xx, yy, new Tile(freeZone[i] + Tile.RESBASE, Tile.BLBNCNBIT))
                    return
                i += 1

    evalResidential = (blockMaps, x, y, traffic) ->
        return -3000 if traffic == Traffic.NO_ROAD_FOUND

        landValue = blockMaps.landValueMap.worldGet(x, y)
        landValue -= blockMaps.pollutionDensityMap.worldGet(x, y)

        if landValue < 0
          landValue = 0
        else
          landValue = Math.min(landValue * 32, 6000)

        return landValue - 3000

    residentialFound = (map, x, y, simData) ->
        simData.census.resZonePop += 1
        tileValue = map.getTileValue(x, y)
        tilePop = getZonePopulation(map, x, y, tileValue)
        simData.census.resPop += tilePop
        zonePower = map.getTile(x, y).isPowered()

        trafficOK = Traffic.ROUTE_FOUND
        if tilePop > Random.getRandom(35)
          # Try driving from residential to commercial
          trafficOK = simData.trafficManager.makeTraffic(x, y, simData.blockMaps, TileUtils.isCommercial)

          # Trigger outward migration if not connected to road network
          if trafficOK ==  Traffic.NO_ROAD_FOUND
              lpValue = ZoneUtils.getLandPollutionValue(simData.blockMaps, x, y)
              doMigrationOut(map, x, y, simData.blockMaps, tilePop, lpValue, zonePower)
              return

        # Occasionally assess and perhaps modify the tile (or always in the
        # case of an empty zone)
        if tileValue == Tile.FREEZ or Random.getChance(7)
            locationScore = evalResidential(simData.blockMaps, x, y, trafficOK)
            zoneScore = simData.valves.resValve + locationScore

            zoneScore = -500 if not zonePower

            if trafficOK and zoneScore > -350 and
               (zoneScore - 26380) > Random.getRandom16Signed()
                # If we have a reasonable population and this zone is empty, make a
                # hospital
                if tilePop == 0 and (Random.getRandom16() & 3) == 0
                    makeHospital(map, x, y, simData, zonePower)
                    return

                lpValue = ZoneUtils.getLandPollutionValue(simData.blockMaps, x, y)
                doMigrationIn(map, x, y, simData.blockMaps, tilePop, lpValue, zonePower)
                return

            if zoneScore < 350 and (zoneScore + 26380) < Random.getRandom16Signed()
                lpValue = ZoneUtils.getLandPollutionValue(simData.blockMaps, x, y)
                doMigrationOut(map, x, y, simData.blockMaps, tilePop, lpValue, zonePower)

    makeHospital = (map, x, y, simData, zonePower) ->
        if simData.census.needHospital > 0
            ZoneUtils.putZone(map, x, y, Tile.HOSPITAL, zonePower)
            simData.census.needHospital = 0
            return

    hospitalFound = (map, x, y, simData) ->
        simData.census.hospitalPop += 1

        if simData.census.needHospital == -1
            if Random.getRandom(20) == 0
                ZoneUtils.putZone(map, x, y, Tile.FREEZ)

    Residential =
        registerHandlers: (mapScanner, repairManager) ->
            mapScanner.addAction(TileUtils.isResidentialZone, residentialFound)
            mapScanner.addAction(TileUtils.HOSPITAL, hospitalFound)
            repairManager.addAction(Tile.HOSPITAL, 15, 3)
        getZonePopulation: getZonePopulation


