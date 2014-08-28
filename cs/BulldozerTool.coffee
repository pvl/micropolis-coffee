define ['BaseTool', 'Messages', 'Random', 'Tile', 'TileUtils', 'ZoneUtils'], (BaseTool, Messages, Random, Tile, TileUtils, ZoneUtils) ->
    class BulldozerTool extends BaseTool
        constructor: (map) ->
            @init(10, map, true)

        putRubble: (x, y, size) ->
            for xx in [x...(x+size)]
                for yy in [y...(y+size)]
                    if @_map.testBounds(xx, yy)
                        tile = @_worldEffects.getTile(xx, yy)
                        if tile != Tile.RADTILE and tile != Tile.DIRT
                            @_worldEffects.setTile(xx, yy, Tile.TINYEXP + Random.getRandom(2), Tile.ANIMBIT | Tile.BULLBIT)

        layDoze: (x, y) ->
            tile = @_worldEffects.getTile(x, y)
            if not tile.isBulldozable()
                return @TOOLRESULT_FAILED

            tile = TileUtils.normalizeRoad(tile.getValue())
            switch tile
                when Tile.HBRIDGE,Tile.VBRIDGE,Tile.BRWV,Tile.BRWH,Tile.HBRDG0, \
                     Tile.HBRDG1,Tile.HBRDG2,Tile.HBRDG3,Tile.VBRDG0,Tile.VBRDG1, \
                     Tile.VBRDG2,Tile.VBRDG3,Tile.HPOWER,Tile.VPOWER, \
                     Tile.HRAIL,Tile.VRAIL
                    @_worldEffects.setTile(x, y, Tile.RIVER)

                else
                    @_worldEffects.setTile(x, y, Tile.DIRT)

            @addCost(1)
            return @TOOLRESULT_OK

        doTool: (x, y, messageManager, blockMaps) ->
            @result = Tile.TOOLRESULT_FAILED if not @_map.testBounds(x, y)
            tile = @_worldEffects.getTile(x, y)
            tileValue = tile.getValue()
            zoneSize = 0
            if tile.isZone()
                zoneSize = ZoneUtils.checkZoneSize(tileValue)
                [deltaX, deltaY] = [0,0]
            else
                {zoneSize,deltaX,deltaY} = ZoneUtils.checkBigZone(tileValue)

            if zoneSize > 0
                @addCost(@bulldozerCost)
                [dozeX, dozeY] = [x, y]
                [centerX, centerY] = [x + deltaX, y + deltaY]

                switch zoneSize
                    when 3
                        messageManager.sendMessage(Messages.SOUND_EXPLOSIONHIGH)
                        @putRubble(centerX - 1, centerY - 1, 3)
                    when 4
                        messageManager.sendMessage(Messages.SOUND_EXPLOSIONLOW)
                        @putRubble(centerX - 1, centerY - 1, 4)
                    when 6
                        messageManager.sendMessage(Messages.SOUND_EXPLOSIONHIGH)
                        messageManager.sendMessage(Messages.SOUND_EXPLOSIONLOW)
                        @putRubble(centerX - 1, centerY - 1, 6)

                @result = @TOOLRESULT_OK

            if tileValue == Tile.RIVER or tileValue == Tile.REDGE or tileValue == Tile.CHANNEL
                @result = @layDoze(x, y)
                if tileValue != @_worldEffects.getTileValue(x, y)
                    @addCost(5)
            else
                @result = @layDoze(x, y)

