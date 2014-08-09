define ['BaseTool', 'Messages', 'Text', 'Tile'], (BaseTool, Messages, Text, Tile) ->
    class QueryTool extends BaseTool

        #Keep in sync with QueryWindow
        debug: true

        constructor: (map) ->
            @init(0, map, false, false)

        classifyPopulationDensity: (x, y, blockMaps) ->
            density = blockMaps.populationDensityMap.worldGet(x, y)
            $('#queryDensityRaw').text(density) if @debug
            density = density >> 6
            density = density & 3
            $('#queryDensity').text(Text.densityStrings[density])

        classifyLandValue: (x, y, blockMaps) ->
            landValue = blockMaps.landValueMap.worldGet(x, y)
            $('#queryLandValueRaw').text(landValue) if @debug
            if landValue >= 150
                i = 3
            else if landValue >= 80
                i = 2
            else if landValue >= 30
                i = 1
            else
                i = 0

            text = Text.landValueStrings[i]
            $('#queryLandValue').text(text)

        classifyCrime: (x, y, blockMaps) ->
            crime = blockMaps.crimeRateMap.worldGet(x, y)
            $('#queryCrimeRaw').text(crime) if @debug
            crime = crime >> 6
            crime = crime & 3
            $('#queryCrime').text(Text.crimeStrings[crime])

        classifyPollution: (x, y, blockMaps) ->
            pollution = blockMaps.pollutionDensityMap.worldGet(x, y)
            $('#queryPollutionRaw').text(pollution) if @debug
            pollution = pollution >> 6
            pollution = pollution & 3
            $('#queryPollution').text(Text.pollutionStrings[pollution])

        classifyRateOfGrowth: (x, y, blockMaps) ->
            rate = blockMaps.rateOfGrowthMap.worldGet(x, y)
            $('#queryRateRaw').text(rate) if @debug
            rate = rate >> 6
            rate = rate & 3
            $('#queryRate').text(Text.rateStrings[rate])

        classifyDebug: (x, y, blockMaps) ->
            if not @debug
                return
            $('#queryFireStationRaw').text(blockMaps.fireStationMap.worldGet(x, y))
            $('#queryFireStationEffectRaw').text(blockMaps.fireStationEffectMap.worldGet(x, y))
            $('#queryPoliceStationRaw').text(blockMaps.policeStationMap.worldGet(x, y))
            $('#queryPoliceStationEffectRaw').text(blockMaps.policeStationEffectMap.worldGet(x, y))
            $('#queryTerrainDensityRaw').text(blockMaps.terrainDensityMap.worldGet(x, y))
            $('#queryTrafficDensityRaw').text(blockMaps.trafficDensityMap.worldGet(x, y))
            $('#queryComRateRaw').text(blockMaps.comRateMap.worldGet(x, y))

        classifyZone: (x, y) ->
            baseTiles = [
                Tile.DIRT, Tile.RIVER, Tile.TREEBASE, Tile.RUBBLE,
                Tile.FLOOD, Tile.RADTILE, Tile.FIRE, Tile.ROADBASE,
                Tile.POWERBASE, Tile.RAILBASE, Tile.RESBASE, Tile.COMBASE,
                Tile.INDBASE, Tile.PORTBASE, Tile.AIRPORTBASE, Tile.COALBASE,
                Tile.FIRESTBASE, Tile.POLICESTBASE, Tile.STADIUMBASE, Tile.NUCLEARBASE,
                Tile.HBRDG0, Tile.RADAR0, Tile.FOUNTAIN, Tile.INDBASE2,
                Tile.FOOTBALLGAME1, Tile.VBRDG0, 952
            ]
            tileValue = @_map.getTileValue(x, y)
            if tileValue >= Tile.COALSMOKE1 and tileValue < Tile.FOOTBALLGAME1
                tileValue = Tile.COALBASE
            pos = 0
            for index in [0...(baseTiles.length-1)]
                if tileValue < baseTiles[index + 1]
                    pos = index
                    break
            $('#queryZoneType').text(Text.zoneTypes[pos])

        doTool: (x, y, messageManager, blockMaps) ->
            text = 'Position (' + x + ', ' + y + ')'
            text += ' TileValue: ' + @_map.getTileValue(x, y)
            if @debug
                tile = @_map.getTile(x, y)
                $('#queryTile').text([x,y].join(', '))
                $('#queryTileValue').text(tile.getValue())
                $('#queryTileBurnable').text(tile.isCombustible())
                $('#queryTileBulldozable').text(tile.isBulldozable())
                $('#queryTileCond').text(tile.isConductive())
                $('#queryTileAnim').text(tile.isAnimated())
                $('#queryTilePowered').text(tile.isPowered())
            @classifyZone(x, y)
            @classifyPopulationDensity(x, y, blockMaps)
            @classifyLandValue(x, y, blockMaps)
            @classifyCrime(x, y, blockMaps)
            @classifyPollution(x, y, blockMaps)
            @classifyRateOfGrowth(x, y, blockMaps)
            @classifyDebug(x, y, blockMaps)

            messageManager.sendMessage(Messages.QUERY_WINDOW_NEEDED)

            @result = @TOOLRESULT_OK
