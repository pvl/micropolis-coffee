define ['BaseTool', 'Connector', 'Tile', 'TileUtils','MiscUtils'], (BaseTool, Connector, Tile, TileUtils, MiscUtils) ->
    class RailTool extends MiscUtils.mixOf BaseTool, Connector
        constructor: (map) ->
            @init(20, map, true, true)

        layRail: (x, y) ->
            @doAutoBulldoze(x, y)
            cost = 20
            tile = @_worldEffects.getTileValue(x, y)
            tile = TileUtils.normalizeRoad(tile)
            switch tile
                when Tile.DIRT
                    @_worldEffects.setTile x, y, Tile.LHRAIL | Tile.BULLBIT | Tile.BURNBIT

                when Tile.RIVER, Tile.REDGE, Tile.CHANNEL
                    cost = 100
                    if x < @_map.width - 1
                        tile = @_worldEffects.getTileValue(x+1, y)
                        tile = TileUtils.normalizeRoad(tile)
                        if tile == Tile.RAILHPOWERV or tile == Tile.HRAIL or (tile >= Tile.LHRAIL and tile <= Tile.HRAILROAD)
                            @_worldEffects.setTile(x, y, Tile.HRAIL, Tile.BULLBIT)
                            break

                    if x > 0
                        tile = @_worldEffects.getTileValue(x-1, y)
                        tile = TileUtils.normalizeRoad(tile)
                        if tile == Tile.RAILHPOWERV or tile == Tile.HRAIL or (tile > Tile.VRAIL and tile < Tile.VRAILROAD)
                            @_worldEffects.setTile(x, y, Tile.HRAIL, Tile.BULLBIT)
                            break

                    if y < @_map.height - 1
                        tile = @_worldEffects.getTileValue(x, y + 1)
                        tile = TileUtils.normalizeRoad(tile)
                        if tile == Tile.RAILVPOWERH or tile == Tile.VRAILROAD or (tile > Tile.HRAIL and tile < Tile.HRAILROAD)
                            @_worldEffects.setTile(x, y, Tile.VRAIL, Tile.BULLBIT)
                            break

                    if y > 0
                        tile = @_worldEffects.getTileValue(x, y - 1)
                        tile = TileUtils.normalizeRoad(tile)
                        if tile == Tile.RAILVPOWERH or tile == Tile.VRAILROAD or (tile > Tile.HRAIL and tile < Tile.HRAILROAD)
                            @_worldEffects.setTile(x, y, Tile.VRAIL, Tile.BULLBIT)
                            break

                    return @TOOLRESULT_FAILED

                when Tile.LHPOWER
                    @_worldEffects.setTile(x, y, Tile.RAILVPOWERH, Tile.CONDBIT | Tile.BURNBIT | Tile.BULLBIT)

                when Tile.LVPOWER
                    @_worldEffects.setTile(x, y, Tile.RAILHPOWERV, Tile.CONDBIT | Tile.BURNBIT | Tile.BULLBIT)

                when Tile.ROADS
                    @_worldEffects.setTile(x, y, Tile.VRAILROAD, Tile.BURNBIT | Tile.BULLBIT)

                when Tile.ROADS2
                    @_worldEffects.setTile(x, y, Tile.HRAILROAD, Tile.BURNBIT | Tile.BULLBIT)

                else
                    return @TOOLRESULT_FAILED

            @addCost(cost)
            @checkZoneConnections(x, y)
            return @TOOLRESULT_OK

        doTool: (x, y, messageManager, blockMaps) ->
            @result = @layRail(x, y)
