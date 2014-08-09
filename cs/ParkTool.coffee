define ['BaseTool', 'Random', 'Tile', 'TileUtils'], (BaseTool, Random, Tile, TileUtils) ->
    class ParkTool extends BaseTool
        constructor: (map) -> @init 10, map, true

        doTool: (x, y, messageManager, blockMaps) ->
            value = Random.getRandom 4
            tileFlags = Tile.BURNBIT | Tile.BULLBIT

            if value == 4
                tileValue = Tile.FOUNTAIN
                tileFlags |= Tile.ANIMBIT
            else
                tileValue = value + Tile.WOODS2

            @_worldEffects.setTile x, y, tileValue, tileFlags
            @addCost 10
            @result = @TOOLRESULT_OK



