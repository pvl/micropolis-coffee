define ['Tile'], (Tile) ->

    isCallable = (f) -> typeof(f) == 'function'

    class MapScanner
        constructor: (map) ->
            @_map = map
            @_actions = []

        addAction: (criterion, action) ->
            @_actions.push({criterion: criterion, action: action})

        mapScan: (startX, maxX, simData) ->
            for y in [0...@_map.height]
                for x in [startX...maxX]
                    tile = @_map.getTile(x, y)
                    tileValue = tile.getValue()

                    if (tileValue < Tile.FLOOD)
                        continue

                    if tile.isConductive()
                        simData.powerManager.setTilePower(x, y)

                    if tile.isZone()
                        simData.repairManager.checkTile(x, y, simData.cityTime)
                        powered = tile.isPowered()
                        if powered
                            simData.census.poweredZoneCount += 1
                        else
                            simData.census.unpoweredZoneCount += 1

                    for i in [0...@_actions.length]
                        current = @_actions[i]
                        callable = isCallable(current.criterion)

                        if callable and current.criterion.call(null, tile)
                            current.action.call(null, @_map, x, y, simData)
                            break
                        else if not callable and current.criterion == tileValue
                            current.action.call(null, @_map, x, y, simData)
                            break
