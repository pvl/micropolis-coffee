define ['Tile'], (Tile) ->

    handleService = (censusStat, budgetEffect, blockMap) ->
        (map, x, y, simData) ->
            simData.census[censusStat] += 1

            effect = simData.budget[budgetEffect]
            isPowered = map.getTile(x, y).isPowered()
            # Unpowered buildings are half as effective
            if not isPowered
                effect = Math.floor(effect / 2)

            pos = new map.Position(x, y)
            connectedToRoads = simData.trafficManager.findPerimeterRoad(pos)
            if not connectedToRoads
                effect = Math.floor(effect / 2)

            currentEffect = simData.blockMaps[blockMap].worldGet(x, y)
            currentEffect += effect
            simData.blockMaps[blockMap].worldSet(x, y, currentEffect)

    policeStationFound = handleService('policeStationPop', 'policeEffect', 'policeStationMap')
    fireStationFound = handleService('fireStationPop', 'fireEffect', 'fireStationMap')

    EmergencyServices =
        registerHandlers: (mapScanner, repairManager) ->
            mapScanner.addAction(Tile.POLICESTATION, policeStationFound)
            mapScanner.addAction(Tile.FIRESTATION, fireStationFound)
