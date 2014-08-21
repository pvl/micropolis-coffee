define ['Random', 'SpriteConstants', 'Tile', 'TileUtils'], (Random, SpriteConstants, Tile, TileUtils) ->

    railFound = (map, x, y, simData) ->
        simData.census.railTotal += 1
        simData.spriteManager.generateTrain(simData.census, x, y)

        if simData.budget.shouldDegradeRoad()
            if Random.getChance(511)
                currentTile = map.getTile(x, y)

                # Don't degrade tiles with power lines
                if currentTile.isConductive()
                    return

                if simData.budget.roadEffect < (Random.getRandom16() & 31)
                    mapValue = currentTile.getValue()

                    # Replace bridge tiles with water, otherwise rubble
                    if tile < Tile.RAILBASE + 2
                        map.setTo(x, y, Tile.RIVER)
                    else
                        map.setTo(x, y, TileUtils.randomRubble())

    airportFound = (map, x, y, simData) ->
        simData.census.airportPop += 1

        tile = map.getTile(x, y)
        if tile.isPowered()
            if map.getTileValue(x + 1, y - 1) == Tile.RADAR
                map.setTo(x + 1, y - 1, new Tile(Tile.RADAR0, Tile.CONDBIT | Tile.ANIMBIT | Tile.BURNBIT))

            if Random.getRandom(5) == 0
                simData.spriteManager.generatePlane(x, y)
                return

            if Random.getRandom(12) == 0
                simData.spriteManager.generateCopter(x, y)
        else
            map.setTo(x + 1, y - 1, new Tile(Tile.RADAR, Tile.CONDBIT | Tile.BURNBIT))

    portFound = (map, x, y, simData) ->
        simData.census.seaportPop += 1

        tile = map.getTile(x, y)
        if tile.isPowered() and simData.spriteManager.getSprite(SpriteConstants.SPRITE_SHIP) == null
            simData.spriteManager.generateShip()

    Transport =
        registerHandlers: (mapScanner, repairManager) ->
            mapScanner.addAction(TileUtils.isRail, railFound)
            mapScanner.addAction(Tile.PORT, portFound)
            mapScanner.addAction(Tile.AIRPORT, airportFound)

            repairManager.addAction(Tile.PORT, 15, 4)
            repairManager.addAction(Tile.AIRPORT, 7, 6)
