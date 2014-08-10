define ['BaseTool', 'Connector', 'Tile', 'TileUtils','MiscUtils'], (BaseTool, Connector, Tile, TileUtils, MiscUtils) ->

    class BuildingTool extends MiscUtils.mixOf BaseTool, Connector
        constructor: (cost, centreTile, map, size, animated) ->
            @init(cost, map, false)
            @centreTile = centreTile
            @size = size
            @animated = animated

        putBuilding: (leftX, topY) ->
            baseTile = @centreTile - @size - 1
            for dy in [0...@size]
                posY = topY + dy
                for dx in [0...@size]
                    posX = leftX + dx
                    tileValue = baseTile
                    tileFlags = Tile.BNCNBIT
                    if dx == 1
                        if dy == 1
                            tileFlags |= Tile.ZONEBIT
                        else if dy == 2 and @animated
                            tileFlags |= Tile.ANIMBIT
                    @_worldEffects.setTile(posX, posY, tileValue, tileFlags)
                    baseTile++

        prepareBuildingSite: (leftX, topY) ->
            #Check that the entire site is on the map
            if leftX < 0 or leftX + @size > @_map.width
                return @TOOLRESULT_FAILED

            if topY < 0 or topY + @size > @_map.height
                return @TOOLRESULT_FAILED

            #Check whether the tiles are clear
            for dy in [0...@size]
                posY = topY + dy
                for dx in [0...@size]
                    posX = leftX + dx
                    tileValue = @_worldEffects.getTileValue(posX, posY)
                    continue if tileValue == Tile.DIRT
                    if not @autoBulldoze
                        # No Tile.DIRT and no bull-dozer => not buildable
                        return @TOOLRESULT_NEEDS_BULLDOZE

                    if not TileUtils.canBulldoze(tileValue)
                        #tilevalue cannot be auto-bulldozed
                        return @TOOLRESULT_NEEDS_BULLDOZE

                    @_worldEffects.setTile(posX, posY, Tile.DIRT)
                    @addCost(@bulldozerCost)
            return @TOOLRESULT_OK

        buildBuilding: (x, y) ->
            #Correct to top left
            x--
            y--
            prepareResult = @prepareBuildingSite(x, y)
            if prepareResult != @TOOLRESULT_OK
                return prepareResult
            @addCost(@toolCost)
            @putBuilding(x, y)
            @checkBorder(x, y)
            return @TOOLRESULT_OK

        doTool: (x, y, messageManager, blockMaps) ->
            @result = @buildBuilding(x, y)
