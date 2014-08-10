define ['BaseTool', 'Connector', 'Tile', 'TileUtils','MiscUtils'], (BaseTool, Connector, Tile, TileUtils, MiscUtils) ->
    class RoadTool extends MiscUtils.mixOf BaseTool, Connector
        constructor: (map) ->
            @init(10, map, true, true)

        layRoad: (x, y) ->
            @doAutoBulldoze(x, y)
            tile = @_worldEffects.getTileValue(x, y)
            cost = 10

            switch tile
                when Tile.DIRT
                    @_worldEffects.setTile(x, y, Tile.ROADS, Tile.BULLBIT | Tile.BURNBIT)

                when Tile.RIVER, Tile.REDGE, Tile.CHANNEL
                    cost = 50
                    if x < @_map.width - 1
                        tile = @_worldEffects.getTileValue(x + 1, y)
                        tile = TileUtils.normalizeRoad(tile)
                        if tile == Tile.VRAILROAD or tile == Tile.HBRIDGE or (tile >= Tile.ROADS and tile <= Tile.HROADPOWER)
                            @_worldEffects.setTile(x, y, Tile.HBRIDGE, Tile.BULLBIT)
                            break

                    if x > 0
                        tile = @_worldEffects.getTileValue(x - 1, y)
                        tile = TileUtils.normalizeRoad(tile)
                        if tile == Tile.VRAILROAD or tile == Tile.HBRIDGE or (tile >= Tile.ROADS and tile <= Tile.INTERSECTION)
                            @_worldEffects.setTile(x, y, Tile.HBRIDGE, Tile.BULLBIT)
                            break

                    if y < @_map.height - 1
                        tile = @_worldEffects.getTileValue(x, y + 1)
                        tile = TileUtils.normalizeRoad(tile)
                        if tile == Tile.HRAILROAD or tile == Tile.VROADPOWER or (tile >= Tile.VBRIDGE and tile <= Tile.INTERSECTION)
                            @_worldEffects.setTile(x, y, Tile.VBRIDGE, Tile.BULLBIT)
                            break

                    if y > 0
                        tile = @_worldEffects.getTileValue(x, y - 1)
                        tile = TileUtils.normalizeRoad(tile)
                        if tile == Tile.HRAILROAD or tile == Tile.VROADPOWER or (tile >= Tile.VBRIDGE and tile <= Tile.INTERSECTION)
                            @_worldEffects.setTile(x, y, Tile.VBRIDGE, Tile.BULLBIT)
                            break

                    return @TOOLRESULT_FAILED

                when Tile.LHPOWER
                    @_worldEffects.setTile(x, y, Tile.VROADPOWER | Tile.CONDBIT | Tile.BURNBIT | Tile.BULLBIT)

                when Tile.LVPOWER
                    @_worldEffects.setTile(x, y, Tile.HROADPOWER | Tile.CONDBIT | Tile.BURNBIT | Tile.BULLBIT)

                when Tile.LHRAIL
                    @_worldEffects.setTile(x, y, Tile.HRAILROAD | Tile.BURNBIT | Tile.BULLBIT)

                when Tile.LVRAIL
                    @_worldEffects.setTile(x, y, Tile.VRAILROAD | Tile.BURNBIT | Tile.BULLBIT)

                else
                    return Tile.TOOLRESULT_FAILED

            @addCost(cost)
            @checkZoneConnections(x, y)
            return @TOOLRESULT_OK

        doTool: (x, y, messageManager, blockMaps) ->
            @result = @layRoad(x, y)
