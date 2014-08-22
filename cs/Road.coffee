define ['Random', 'Tile', 'TileUtils'], (Random, Tile, TileUtils) ->

    openBridge = (map, origX, origY, xDelta, yDelta, oldTiles, newTiles) ->
        for i in [0...7]
            x = origX + xDelta[i]
            y = origY + yDelta[i]

            if map.testBounds(x, y)
                if map.getTileValue(x, y) == (oldTiles[i] & Tile.BIT_MASK)
                    map.setTileValue(newTiles[i])

    closeBridge = (map, origX, origY, xDelta, yDelta, oldTiles, newTiles) ->
        for i in [0...7]
            x = origX + xDelta[i]
            y = origY + yDelta[i]

            if map.testBounds(x, y)
                tileValue = map.getTileValue(x, y)
                if tileValue == Tile.CHANNEL or (tileValue & 15) == (oldTiles[i] & 15)
                    map.setTileValue(newTiles[i])

    verticalDeltaX = [0,  1,  0,  0,  0,  0,  1]
    verticalDeltaY = [-2, -2, -1,  0,  1,  2,  2]
    openVertical = [
            Tile.VBRDG0 | Tile.BULLBIT, Tile.VBRDG1 | Tile.BULLBIT,
            Tile.RIVER, Tile.BRWV | Tile.BULLBIT,
            Tile.RIVER, Tile.VBRDG2 | Tile.BULLBIT, Tile.VBRDG3 | Tile.BULLBIT]
    closeVertical = [
            Tile.VBRIDGE | Tile.BULLBIT, Tile.RIVER, Tile.VBRIDGE | Tile.BULLBIT,
            Tile.VBRIDGE | Tile.BULLBIT, Tile.VBRIDGE | Tile.BULLBIT,
            Tile.VBRIDGE | Tile.BULLBIT, Tile.RIVER]
    horizontalDeltaX = [-2,  2, -2, -1,  0,  1,  2]
    horizontalDeltaY = [ -1, -1,  0,  0,  0,  0,  0]
    openHorizontal = [
          Tile.HBRDG1 | Tile.BULLBIT, Tile.HBRDG3 | Tile.BULLBIT,
          Tile.HBRDG0 | Tile.BULLBIT, Tile.RIVER, Tile.BRWH | Tile.BULLBIT,
          Tile.RIVER, Tile.HBRDG2 | Tile.BULLBIT]
    closeHorizontal = [
          Tile.RIVER, Tile.RIVER, Tile.HBRIDGE | Tile.BULLBIT,
          Tile.HBRIDGE | Tile.BULLBIT, Tile.HBRIDGE | Tile.BULLBIT,
          Tile.HBRIDGE | Tile.BULLBIT, Tile.HBRIDGE | Tile.BULLBIT]

    doBridge = (map, x, y, currentTile, simData) ->
        if currentTile == Tile.BRWV
            # We have an open vertical bridge. Possibly close it.
            if Random.getChance(3) and simData.spriteManager.getBoatDistance(x, y) > 340
                closeBridge(map, x, y, verticalDeltaX, verticalDeltaY, openVertical, closeVertical)
            return true


        if currentTile == Tile.BRWH
            # We have an open horizontal bridge. Possibly close it.
            if Random.getChance(3) and simData.spriteManager.getBoatDistance(x, y) > 340
                closeBridge(map, x, y, horizontalDeltaX, horizontalDeltaY, openHorizontal, closeHorizontal)
            return true

        if simData.spriteManager.getBoatDistance(x, y) < 300 or Random.getChance(7)
            if currentTile & 1
                if x < map.width - 1
                    if map.getTileValue(x + 1, y) == Tile.CHANNEL
                        # We have a closed vertical bridge. Open it.
                        openBridge(map, x, y, verticalDeltaX, verticalDeltaY, closeVertical, openVertical)
                        return true
                return false
            else
                if y > 0
                    if map.getTileValue(x, y - 1) == Tile.CHANNEL
                        # We have a closed horizontal bridge. Open it.
                        openBridge(map, x, y, horizontalDeltaX, horizontalDeltaY, openVertical, closeVertical)
                        return true
        return false

    densityTable = [Tile.ROADBASE, Tile.LTRFBASE, Tile.HTRFBASE]

    roadFound = (map, x, y, simData) ->
        simData.census.roadTotal += 1

        currentTile = map.getTile(x, y)
        tileValue = currentTile.getValue()

        if simData.budget.shouldDegradeRoad()
            if Random.getChance(511)
                currentTile = map.getTile(x, y)

                # Don't degrade tiles with power lines
                if not currentTile.isConductive()
                    if simData.budget.roadEffect < (Random.getRandom16() & 31)
                        mapValue = currentTile.getValue()

                        # Replace bridge tiles with water, otherwise rubble
                        if (tileValue & 15) < 2 or (tileValue & 15) == 15
                            map.setTo(x, y, Tile.RIVER)
                        else
                            map.setTo(x, y, TileUtils.randomRubble())
                        return
        # Bridges are not combustible
        if not currentTile.isCombustible()
            # The comment in the original Micropolis code states bridges count for 4
            # However, with the increment above, it's actually 5. Bug?
            simData.census.roadTotal += 4
            if doBridge(map, x, y, tileValue, simData) then return
        # Examine traffic density, and modify tile to represent last scanned traffic
        # density
        density = 0
        if tileValue < Tile.LTRFBASE
            density = 0
        else if tileValue < Tile.HTRFBASE
            density = 1
        else
            # Heavy traffic counts as two tiles with regards to upkeep cost
            # Note, if this is heavy traffic on a bridge, and it wasn't handled above,
            # it actually counts for 7 road tiles
            simData.census.roadTotal += 1
            density = 2

        currentDensity = simData.blockMaps.trafficDensityMap.worldGet(x, y) >> 6
        # Force currentDensity in range 0-3 (trafficDensityMap values are capped at 240)
        if currentDensity >> 1 then currentDensity -= 1
        if currentDensity == density then return

        newValue = ((tileValue - Tile.ROADBASE) & 15) + densityTable[currentDensity]
        # Preserve all bits except animation
        newFlags = currentTile.getFlags() & ~Tile.ANIMBIT
        if currentDensity > 0
            newFlags |= Tile.ANIMBIT

        map.setTo(x, y, new Tile(newValue, newFlags))

    Road =
        registerHandlers: (mapScanner, repairManager) ->
            mapScanner.addAction(TileUtils.isRoad, roadFound)
