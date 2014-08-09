define ['Tile'], (Tile) ->
    emptyStadiumFound = (map, x, y, simData) ->
        simData.census.stadiumPop += 1
        if map.getTile(x, y).isPowered()
            # Occasionally start the big game
            if ((simData.cityTime + x + y) & 31) == 0
                map.putZone x, y, Tile.FULLSTADIUM, 4
                map.addTileFlags x, y, Tile.POWERBIT
                map.setTo x + 1, y, new Tile(Tile.FOOTBALLGAME1, Tile.ANIMBIT)
                map.setTo x + 1, y + 1, new Tile(Tile.FOOTBALLGAME2, Tile.ANIMBIT)

    fullStadiumFound = (map, x, y, simData) ->
        simData.census.stadiumPop += 1
        isPowered = map.getTile(x, y).isPowered()
        if ((simData.cityTime + x + y) & 7) == 0
            map.putZone x, y, Tile.STADIUM, 4
            map.addTileFlags(x, y, Tile.POWERBIT) if isPowered

    Stadia =
        registerHandlers: (mapScanner, repairManager) ->
            mapScanner.addAction Tile.STADIUM, emptyStadiumFound
            mapScanner.addAction Tile.FULLSTADIUM, fullStadiumFound
            repairManager.addAction Tile.STADIUM, 15, 4
