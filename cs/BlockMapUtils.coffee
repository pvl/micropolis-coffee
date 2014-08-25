define ['BlockMap', 'Commercial', 'Industrial', 'MiscUtils', 'Random', 'Residential', 'Tile'], \
  (BlockMap, Commercial, Industrial, MiscUtils, Random, Residential, Tile) ->


    decRateOfGrowthMap = (blockMaps) ->
        rateOfGrowthMap = blockMaps.rateOfGrowthMap
        for x in [0...rateOfGrowthMap.width]
            for y in [0...rateOfGrowthMap.height]
                rate = rateOfGrowthMap.get(x, y)
                if rate == 0
                    continue
                if rate > 0
                    rate--
                    rate = MiscUtils.clamp(rate, -200, 200)
                    rateOfGrowthMap.set(x, y, rate)
                    continue
                if rate < 0
                    rate++
                    rate = MiscUtils.clamp(rate, -200, 200)
                    rateOfGrowthMap.set(x, y, rate)
        return


    decTrafficMap = (blockMaps) ->
        trafficDensityMap = blockMaps.trafficDensityMap

        for x in [0...trafficDensityMap.mapWidth] by trafficDensityMap.blockSize
            for y in [0...trafficDensityMap.mapHeight] by trafficDensityMap.blockSize
                trafficDensity = trafficDensityMap.worldGet(x, y)
                if trafficDensity == 0
                    continue

                if trafficDensity <= 24
                    trafficDensityMap.worldSet(x, y, 0)
                    continue

                if trafficDensity > 200
                    trafficDensityMap.worldSet(x, y, trafficDensity - 34)
                else
                    trafficDensityMap.worldSet(x, y, trafficDensity - 24)
        return


    getPollutionValue = (tileValue) ->
        if tileValue < Tile.POWERBASE
            if tileValue >= Tile.HTRFBASE
                return 75

            if tileValue >= Tile.LTRFBASE
                return 50

            if tileValue <  Tile.ROADBASE
                if tileValue > Tile.FIREBASE
                    return 90
                if tileValue >= Tile.RADTILE
                    return 255
            return 0

        if tileValue <= Tile.LASTIND
            return 0

        if tileValue < Tile.PORTBASE
            return 50

        if tileValue <= Tile.LASTPOWERPLANT
            return 100

        return 0


    getCityCentreDistance = (map, x, y) ->
        if x > map.cityCentreX
            xDis = x - map.cityCentreX
        else
            xDis = map.cityCentreX - x

        if y > map.cityCentreY
            yDis = y - map.cityCentreY
        else
            yDis = map.cityCentreY - y

        return Math.min(xDis + yDis, 64)


    # The original version of this function in the Micropolis code
    # takes a ditherFlag. However, as far as I can tell, it was
    # never called with a truthy value for the ditherFlag.
    smoothDitherMap = (srcMap, destMap) ->
        for x in [0...srcMap.width]
            for y in [0...srcMap.height]
                value = 0

                if x > 0
                    value += srcMap.get(x - 1, y)

                if x < srcMap.width - 1
                    value += srcMap.get(x + 1, y)

                if y > 0
                    value += srcMap.get(x, y - 1)

                if y < (srcMap.height - 1)
                    value += srcMap.get(x, y + 1)

                value = (value + srcMap.get(x, y)) >> 2
                if value > 255
                    value = 255

                destMap.set(x, y, value)
        return


    smoothTemp1ToTemp2 = (blockMaps) ->
        smoothDitherMap(blockMaps.tempMap1, blockMaps.tempMap2)


    smoothTemp2ToTemp1 = (blockMaps) ->
        smoothDitherMap(blockMaps.tempMap2, blockMaps.tempMap1)


    # Again, the original version of this function in the Micropolis code
    # reads donDither, which is always zero. The dead code has been culled
    smoothTerrain = (blockMaps) ->
        # Sets each tile to the average of itself and the average of the
        # 4 surrounding tiles

        tempMap3 = blockMaps.tempMap3
        terrainDensityMap = blockMaps.terrainDensityMap

        for x in [0...terrainDensityMap.width]
            for y in [0...terrainDensityMap.height]
                value = 0

                if x > 0
                    value += tempMap3.get(x - 1, y)

                if x < (terrainDensityMap.width - 1)
                    value += tempMap3.get(x + 1, y)

                if y > 0
                    value += tempMap3.get(x, y - 1)

                if y < (terrainDensityMap.height - 1)
                    value += tempMap3.get(x, y + 1)

                value = Math.floor(Math.floor(value / 4) + tempMap3.get(x, y) / 2)
                terrainDensityMap.set(x, y, value)
        return


    pollutionTerrainLandValueScan = (map, census, blockMaps) ->
        tempMap1 = blockMaps.tempMap1
        tempMap3 = blockMaps.tempMap3
        landValueMap = blockMaps.landValueMap
        terrainDensityMap = blockMaps.terrainDensityMap
        pollutionDensityMap = blockMaps.pollutionDensityMap
        crimeRateMap = blockMaps.crimeRateMap

        # tempMap3 is a map of development density, smoothed into terrainMap.
        tempMap3.clear()

        totalLandValue = 0
        numLandValueTiles = 0
        for x in [0...landValueMap.width]
            for y in [0...landValueMap.height]
                pollutionLevel = 0
                developed = false
                worldX = x * 2
                worldY = y * 2

                for mapX in [worldX..(worldX + 1)]
                    for mapY in [worldY..(worldY + 1)]
                        tileValue = map.getTileValue(mapX, mapY)
                        if tileValue > Tile.DIRT
                            if tileValue < Tile.RUBBLE
                                # Undeveloped land: record in tempMap3
                                value = tempMap3.get(x >> 1, y >> 1)
                                tempMap3.set(x >> 1, y >> 1, value + 15)
                                continue

                            pollutionLevel += getPollutionValue(tileValue)
                            if tileValue >= Tile.ROADBASE
                                developed = true
                pollutionLevel = Math.min(pollutionLevel, 255)
                tempMap1.set(x, y, pollutionLevel)
                if developed
                    dis = 34 - Math.floor(getCityCentreDistance(map, worldX, worldY) / 2)
                    dis = dis << 2
                    dis += terrainDensityMap.get(x >> 1, y >> 1)
                    dis -= pollutionDensityMap.get(x, y)
                    if crimeRateMap.get(x, y) > 190
                        dis -= 20
                    dis = MiscUtils.clamp(dis, 1, 250)
                    landValueMap.set(x, y, dis)
                    totalLandValue += dis
                    numLandValueTiles++
                else
                    landValueMap.set(x, y, 0)

        if numLandValueTiles > 0
            census.landValueAverage = Math.floor(totalLandValue / numLandValueTiles)
        else
            census.landValueAverage = 0
        smoothTemp1ToTemp2(blockMaps)
        smoothTemp2ToTemp1(blockMaps)

        maxPollution = 0
        pollutedTileCount = 0
        totalPollution = 0

        for x in [0...pollutionDensityMap.mapWidth] by pollutionDensityMap.blockSize
            for y in [0...pollutionDensityMap.mapHeight] by pollutionDensityMap.blockSize
                pollution = tempMap1.worldGet(x, y)
                pollutionDensityMap.worldSet(x, y, pollution)

                if pollution != 0
                    pollutedTileCount++
                    totalPollution += pollution

                    # note location of max pollution for monster
                    if pollution > maxPollution or (pollution == maxPollution and Random.getChance(3))
                        maxPollution = pollution
                        map.pollutionMaxX = x
                        map.pollutionMaxY = y
        if pollutedTileCount
            census.pollutionAverage = Math.floor(totalPollution / pollutedTileCount)
        else
            census.pollutionAverage = 0
        smoothTerrain(blockMaps)


    smoothStationMap = (map) ->
        tempMap = new BlockMap(map)

        for x in [0...tempMap.width]
            for y in [0...tempMap.height]
                edge = 0
                if x > 0
                   edge += tempMap.get(x - 1, y)

                if x < tempMap.width - 1
                   edge += tempMap.get(x + 1, y)

                if y > 0
                   edge += tempMap.get(x, y - 1)

                if y < tempMap.height - 1
                   edge += tempMap.get(x, y + 1)

                edge = tempMap.get(x, y) + Math.floor(edge / 4)
                map.set(x, y, Math.floor(edge / 2))
        return


    crimeScan = (census, blockMaps) ->
        policeStationMap = blockMaps.policeStationMap
        policeStationEffectMap = blockMaps.policeStationEffectMap
        crimeRateMap = blockMaps.crimeRateMap
        landValueMap = blockMaps.landValueMap
        populationDensityMap = blockMaps.populationDensityMap

        smoothStationMap(policeStationMap)
        smoothStationMap(policeStationMap)
        smoothStationMap(policeStationMap)

        totalCrime = 0
        crimeZoneCount = 0

        for x in [0...crimeRateMap.mapWidth] by crimeRateMap.blockSize
            for y in [0...crimeRateMap.mapHeight] by crimeRateMap.blockSize
                value = landValueMap.worldGet(x, y)

                if value > 0
                    ++crimeZoneCount
                    value = 128 - value
                    value += populationDensityMap.worldGet(x, y)
                    value = Math.min(value, 300)
                    value -= policeStationMap.worldGet(x, y)
                    value = MiscUtils.clamp(value, 0, 250)
                    crimeRateMap.worldSet(x, y, value)
                    totalCrime += value
                else
                    crimeRateMap.worldSet(x, y, 0)

        if (crimeZoneCount > 0)
            census.crimeAverage = Math.floor(totalCrime / crimeZoneCount)
        else
            census.crimeAverage = 0

        blockMaps.policeStationEffectMap = new BlockMap(policeStationMap)


    computeComRateMap = (map, blockMaps) ->
        comRateMap = blockMaps.comRateMap

        for x in [0...comRateMap.width]
            for y in [0...comRateMap.height]
                value = Math.floor(getCityCentreDistance(map, x * 8, y * 8) / 2)
                value = value * 4
                value = 64 - value
                comRateMap.set(x, y, value)
        return


    getPopulationDensity = (map, x, y, tile) ->
        if tile < Tile.COMBASE
            return Residential.getZonePopulation(map, x, y, tile)

        if tile < Tile.INDBASE
           return Commercial.getZonePopulation(map, x, y, tile) * 8

        if tile < Tile.PORTBASE
             return Industrial.getZonePopulation(map, x, y, tile) * 8

        return 0


    populationDensityScan = (map, blockMaps) ->
        tempMap1 = blockMaps.tempMap1
        tempMap2 = blockMaps.tempMap2
        populationDensityMap = blockMaps.populationDensityMap
        tempMap1.clear()

        Xtot = 0
        Ytot = 0
        zoneTotal = 0

        for x in [0...map.width]
            for y in [0...map.height]
                tile = map.getTile(x, y)
                if tile.isZone()
                    tileValue = tile.getValue()

                    population = getPopulationDensity(map, x, y, tileValue) * 8
                    population = Math.min(population, 254)

                    tempMap1.worldSet(x, y, population)
                    Xtot += x
                    Ytot += y
                    zoneTotal++
        smoothTemp1ToTemp2(blockMaps)
        smoothTemp2ToTemp1(blockMaps)
        smoothTemp1ToTemp2(blockMaps)

        # Copy tempMap2 to populationDensityMap, multiplying by 2
        blockMaps.populationDensityMap = new BlockMap(tempMap2, (x) ->  2 * x)

        computeComRateMap(map, blockMaps)
        # Compute new city center
        if zoneTotal > 0
            map.cityCentreX = Math.floor(Xtot / zoneTotal)
            map.cityCentreY = Math.floor(Ytot / zoneTotal)
        else
            map.cityCentreX = Math.floor(map.width / 2)
            map.cityCentreY = Math.floor(map.height / 2)

    fireAnalysis = (blockMaps) ->
        fireStationMap = blockMaps.fireStationMap
        fireStationEffectMap = blockMaps.fireStationEffectMap

        smoothStationMap(fireStationMap)
        smoothStationMap(fireStationMap)
        smoothStationMap(fireStationMap)

        blockMaps.fireStationEffectMap = new BlockMap(fireStationMap)

    BlockMapUtils =
        crimeScan: crimeScan,
        decRateOfGrowthMap: decRateOfGrowthMap,
        decTrafficMap: decTrafficMap,
        fireAnalysis: fireAnalysis,
        pollutionTerrainLandValueScan: pollutionTerrainLandValueScan,
        populationDensityScan: populationDensityScan
