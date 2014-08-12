define ['Tile'], (Tile) ->

    isCallable = (f) -> typeof(f) == 'function'

    class RepairManager
        constructor: (map) ->
            @_map = map
            @_actions = []

        addAction: (criterion, period, zoneSize) ->
            @_actions.push({criterion: criterion, period: period, zoneSize: zoneSize})

        repairZone: (x, y, zoneSize) ->
            centre = @_map.getTileValue(x, y)
            tileValue = centre - zoneSize - 2

            for yy in [-1...(zoneSize - 1)]
                for xx in [-1...(zoneSize - 1)]
                    tileValue++

                current = @_map.getTile(x + xx, y + yy)
                if current.isZone() or current.isAnimated()
                    continue

                currentValue = current.getValue()
                if currentValue < Tile.RUBBLE or currentValue >= Tile.ROADBASE
                    @_map.setTo(x + xx, y + yy, new Tile(tileValue, Tile.CONDBIT | Tile.BURNBIT))

        checkTile: (x, y, cityTime) ->
            for i in [0...@_actions.length]
                current = @_actions[i]
                period = current.period

                if (cityTime & period) != 0
                    continue

                tile = @_map.getTile(x, y)
                tileValue = tile.getValue()

                callable = isCallable(current.criterion)
                if callable and current.criterion.call(null, tile)
                    @repairZone(x, y, current.zoneSize)
                else if not callable and current.criterion == tileValue
                    @repairZone(x, y, current.zoneSize)
