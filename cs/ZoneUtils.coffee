define ['MiscUtils', 'Tile'], (MiscUtils, Tile) ->

    checkBigZone = (tileValue) ->
        switch tileValue
            when Tile.POWERPLANT,Tile.PORT,Tile.NUCLEAR,Tile.STADIUM
                result = {zoneSize: 4, deltaX: 0, deltaY: 0}
            when Tile.POWERPLANT + 1, Tile.COALSMOKE3, Tile.COALSMOKE3 + 1, Tile.COALSMOKE3 + 2, Tile.PORT + 1, Tile.NUCLEAR + 1, Tile.STADIUM + 1
                result = {zoneSize: 4, deltaX: -1, deltaY: 0}
            when Tile.POWERPLANT + 4, Tile.PORT + 4, Tile.NUCLEAR + 4, Tile.STADIUM + 4
                result = {zoneSize: 4, deltaX: 0, deltaY: -1}
            when Tile.POWERPLANT + 5, Tile.PORT + 5, Tile.NUCLEAR + 5, Tile.STADIUM + 5
                result = {zoneSize: 4, deltaX: -1, deltaY: -1}
            when Tile.AIRPORT
                result = {zoneSize: 6, deltaX: 0, deltaY: 0}
            when Tile.AIRPORT + 1
                result = {zoneSize: 6, deltaX: -1, deltaY: 0}
            when Tile.AIRPORT + 2
                result = {zoneSize: 6, deltaX: -2, deltaY: 0}
            when Tile.AIRPORT + 3
                result = {zoneSize: 6, deltaX: -3, deltaY: 0}
            when Tile.AIRPORT + 6
                result = {zoneSize: 6, deltaX: 0, deltaY: -1}
            when Tile.AIRPORT + 7
                result = {zoneSize: 6, deltaX: -1, deltaY: -1}
            when Tile.AIRPORT + 8
                result = {zoneSize: 6, deltaX: -2, deltaY: -1}
            when Tile.AIRPORT + 9
                result = {zoneSize: 6, deltaX: -3, deltaY: -1}
            when Tile.AIRPORT + 12
                result = {zoneSize: 6, deltaX: 0, deltaY: -2}
            when Tile.AIRPORT + 13
                result = {zoneSize: 6, deltaX: -1, deltaY: -2}
            when Tile.AIRPORT + 14
                result = {zoneSize: 6, deltaX: -2, deltaY: -2}
            when Tile.AIRPORT + 15
                result = {zoneSize: 6, deltaX: -3, deltaY: -2}
            when Tile.AIRPORT + 18
                result = {zoneSize: 6, deltaX: 0, deltaY: -3}
            when Tile.AIRPORT + 19
                result = {zoneSize: 6, deltaX: -1, deltaY: -3}
            when Tile.AIRPORT + 20
                result = {zoneSize: 6, deltaX: -2, deltaY: -3}
            when Tile.AIRPORT + 21
                result = {zoneSize: 6, deltaX: -3, deltaY: -3}
            else
                result = {zoneSize: 0, deltaX: 0, deltaY: 0}
        return result

    checkZoneSize = (tileValue) ->
        if (tileValue >= Tile.RESBASE - 1 and tileValue <= Tile.PORTBASE - 1) or
           (tileValue >= Tile.LASTPOWERPLANT + 1 and tileValue <= Tile.POLICESTATION + 4) or
           (tileValue >= Tile.CHURCH1BASE and tileValue <= Tile.CHURCH7LAST)
            return 3
        if (tileValue >= Tile.PORTBASE and tileValue <= Tile.LASTPORT) or
           (tileValue >= Tile.COALBASE and tileValue <= Tile.LASTPOWERPLANT) or
           (tileValue >= Tile.STADIUMBASE and tileValue <= Tile.LASTZONE)
            return 4
        return 0

    fireZone = (map, x, y, blockMaps) ->
        tileValue = map.getTileValue(x, y)
        zoneSize = 2

        # A zone being on fire naturally hurts growth
        value = blockMaps.rateOfGrowthMap.worldGet(x, y)
        value = MiscUtils.clamp(value - 20, -200, 200)
        blockMaps.rateOfGrowthMap.worldSet(x, y, value)

        if tileValue == Tile.AIRPORT
            zoneSize = 5
        else if tileValue >= Tile.PORTBASE
            zoneSize = 3
        else if tileValue < Tile.PORTBASE
            zoneSize = 2

        # Make remaining tiles of the zone bulldozable
        for xDelta in [-1...zoneSize]
            for yDelta in [-1...zoneSize]
                xTem = x + xDelta
                yTem = y + yDelta

                if not map.testBounds(xTem, yTem)
                    continue
                if map.getTileValue(xTem, yTem >= Tile.ROADBASE)
                    map.addTileFlags(xTem, yTem, Tile.BULLBIT)
        return

    getLandPollutionValue = (blockMaps, x, y) ->
        landValue = blockMaps.landValueMap.worldGet(x, y)
        landValue -= blockMaps.pollutionDensityMap.worldGet(x, y)

        if landValue < 30
            return 0
        if landValue < 80
            return 1
        if landValue < 150
            return 2
        return 3

    incRateOfGrowth = (blockMaps, x, y, growthDelta) ->
        currentRate = blockMaps.rateOfGrowthMap.worldGet(x, y)
        # TODO why the scale of 4 here
        newValue = MiscUtils.clamp(currentRate + growthDelta * 4, -200, 200)
        blockMaps.rateOfGrowthMap.worldSet(x, y, newValue)

    # Calls map.putZone after first checking for flood, fire
    # and radiation
    putZone = (map, x, y, centreTile, isPowered) ->
        for dY in [0...3]
            for dX in [0...3]
                tileValue = map.getTileValue(x + dX, y + dY)
                if tileValue >= Tile.FLOOD and tileValue < Tile.ROADBASE
                    return
        map.putZone(x, y, centreTile, 3)
        map.addTileFlags(x, y, Tile.BULLBIT)
        if isPowered
            map.addTileFlags(x, y, Tile.POWERBIT)

    ZoneUtils =
        checkBigZone: checkBigZone
        checkZoneSize: checkZoneSize
        fireZone: fireZone
        getLandPollutionValue: getLandPollutionValue
        incRateOfGrowth: incRateOfGrowth
        putZone: putZone
