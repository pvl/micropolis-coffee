#PVL FIXME, this should be handled using inheritance

define ['Messages', 'Tile', 'TileUtils', 'WorldEffects'], (Messages, Tile, TileUtils, WorldEffects) ->

    class BaseTool

        TOOLRESULT_OK = 0
        TOOLRESULT_FAILED = 1
        TOOLRESULT_NO_MONEY = 2
        TOOLRESULT_NEEDS_BULLDOZE = 3

        autoBulldoze: true #FIXME PVL should this be a class attribute?
        bulldozerCost: 1

        init: (cost, map, shouldAutoBulldoze, isDraggable) ->
            isDraggable = isDraggable or false
            @toolCost = cost
            @result = null
            @isDraggable = isDraggable
            @_shouldAutoBulldoze = shouldAutoBulldoze
            @_map = map
            @_worldEffects = new WorldEffects(map)
            @_applicationCost = 0

        clear: ->
            @_applicationCost = 0
            @_worldEffects.clear()
            @result = null

        addCost: (cost) -> @_applicationCost += cost

        doAutoBulldoze: (x, y) ->
            if not @_shouldAutoBulldoze
                return

            tile = @_worldEffects.getTile(x, y)
            if tile.isBulldozable()
                tile = TileUtils.normalizeRoad(tile)
                if (tile >= Tile.TINYEXP and tile <= Tile.LASTTINYEXP) or (tile < Tile.HBRIDGE and tile != Tile.DIRT)
                    @addCost 1
                    @_worldEffects.setTile(x, y, Tile.DIRT)

        apply: (budget, messageManager) ->
            @_worldEffects.apply()
            budget.spend(@_applicationCost, messageManager)
            messageManager.sendMessage(Messages.DID_TOOL)
            @clear()

        modifyIfEnoughFunding: (budget, messageManager) ->
            if @result != @TOOLRESULT_OK
                return false

            if budget.totalFunds < @_applicationCost
                @result = @TOOLRESULT_NO_MONEY
                return false

            @apply(budget, messageManager)
            return true

