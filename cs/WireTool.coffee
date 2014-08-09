define ['BaseTool', 'Connector', 'Tile', 'TileUtils','MiscUtils'], (BaseTool, Connector, Tile, TileUtils, MiscUtils) ->
    class WireTool extends MiscUtils.mixOf BaseTool, Connector
        constructor: (map) ->
            @init(20, map, true, true)

        layWire: (x, y) ->
            @doAutoBulldoze(x, y)
            cost = 5
            tile = TileUtils.normalizeRoad(@_worldEffects.getTileValue(x, y))
            switch tile
                when Tile.DIRT
                    @_worldEffects.setTile(x, y, Tile.LHPOWER, Tile.CONDBIT | Tile.BURNBIT | Tile.BULLBIT)

                when Tile.RIVER, Tile.REDGE, Tile.CHANNEL
                    cost = 25
                    if x < @_map.width-1
                        tile = @_worldEffects.getTile(x + 1, y)
                        if tile.isConductive()
                            tile = TileUtils.normalizeRoad(tile.getValue())
                            if tile != Tile.HROADPOWER and tile != Tile.RAILHPOWERV and tile != Tile.HPOWER
                                @_worldEffects.setTile(x, y, Tile.VPOWER, Tile.CONDBIT | Tile.BULLBIT)
                                break
                    if x > 0
                        tile = @_worldEffects.getTile(x-1, y)
                        if tile.isConductive()
                            tile = TileUtils.normalizeRoad(tile.getValue())
                            if tile != Tile.HROADPOWER and tile != Tile.RAILHPOWERV and tile != Tile.HPOWER
                                @_worldEffects.setTile(x, y, Tile.VPOWER, Tile.CONDBIT | Tile.BULLBIT)
                                break

                    if y < @_map.height - 1
                        tile = @_worldEffects.getTile(x, y + 1);
                        if tile.isConductive()
                            tile = TileUtils.normalizeRoad(tile.getValue())
                            if tile != Tile.VROADPOWER and tile != Tile.RAILVPOWERH and tile != Tile.VPOWER
                                @_worldEffects.setTile(x, y, Tile.HPOWER, Tile.CONDBIT | Tile.BULLBIT)
                                break

                    if y > 0
                        tile = @_worldEffects.getTile(x, y - 1)
                        if tile.isConductive()
                            tile = TileUtils.normalizeRoad(tile.getValue())
                            if tile != Tile.VROADPOWER and tile != Tile.RAILVPOWERH and tile != Tile.VPOWER
                                @_worldEffects.setTile(x, y, Tile.HPOWER, Tile.CONDBIT | Tile.BULLBIT)
                                break
                    @TOOLRESULT_FAILED

                when Tile.ROADS
                    @_worldEffects.setTile(x, y, Tile.HROADPOWER, Tile.CONDBIT | Tile.BURNBIT | Tile.BULLBIT)

                when Tile.ROADS2
                    @_worldEffects.setTile(x, y, Tile.VROADPOWER, Tile.CONDBIT | Tile.BURNBIT | Tile.BULLBIT)

                when Tile.LHRAIL
                    @_worldEffects.setTile(x, y, Tile.RAILHPOWERV, Tile.CONDBIT | Tile.BURNBIT | Tile.BULLBIT)

                when Tile.LVRAIL
                    @_worldEffects.setTile(x, y, Tile.RAILVPOWERH, Tile.CONDBIT | Tile.BURNBIT | Tile.BULLBIT)

                else
                    return @TOOLRESULT_FAILED
            @addCost(cost)
            @checkZoneConnections(x, y)
            return @TOOLRESULT_OK

        doTool: (x, y, messageManager, blockMaps) ->
            @result = @layWire(x, y)


