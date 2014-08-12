define ['Messages', 'MiscUtils', 'Random', 'SpriteConstants', 'Tile', 'TileUtils', 'ZoneUtils'], (Messages, MiscUtils, Random, SpriteConstants, Tile, TileUtils, ZoneUtils) ->

    DisChance = [4800, 2400, 60]
    Dx = [ 0, 1, 0, -1]
    Dy = [-1, 0, 1, 0]

    vulnerable = (tile) ->
        tileValue = tile.getValue()
        if tileValue < Tile.RESBASE or tileValue > Tile.LASTZONE or tile.isZone()
            return false
        return true

    class DisasterManager
        constructor: (map, spriteManager, gameLevel) ->
            @_map = map
            @_spriteManager = spriteManager
            @_gameLevel = gameLevel

            @_floodCount = 0

            # TODO enable disasters  PVL FIXME
            Object.defineProperty(this, 'disastersEnabled',
                                  MiscUtils.makeConstantDescriptor(false))

        doDisasters: (census, messageManager) ->
            @_floodCount-- if @_floodCount

            # TODO Scenarios

            if not @disastersEnabled
                return
            if Random.getRandom(DisChance[@_gameLevel])
                switch Random.getRandom(8)
                    when 0, 1
                        @setFire(messageManager)
                    when 2, 3
                        @makeFlood(messageManager)
                    when 5
                        @_spriteManager.makeTornado(messageManager)
                    # when 6
                        # TODO Earthquakes
                        #@makeEarthquake()
                    when 7, 8
                        if census.pollutionAverage > 60
                            @_spriteManager.makeMonster(messageManager)

        scenarioDisaster: ->
            # TODO Scenarios

        # User initiated meltdown: need to find the plant first
        makeMeltdown: (messageManager) ->
            for x in [0...(@_map.width - 1)]
                for y in [0...(@_map.height - 1)]
                    if @_map.getTileValue(x, y) == Tile.NUCLEAR
                        @doMeltdown(messageManager, x, y)
                        return

        # User initiated earthquake
        makeEarthquake: (messageManager) ->
            strength = Random.getRandom(700) + 300
            @doEarthquake(strength)

            messageManager.sendMessage(Messages.EARTHQUAKE, {x: @_map.cityCenterX, y: @_map.cityCenterY})

            for i in [0...strength]
                x = Random.getRandom(@_map.width - 1)
                y = Random.getRandom(@_map.height - 1)

                if vulnerable(@_map.getTile(x, y))
                    if (i & 0x3) != 0
                        @_map.setTo(x, y, TileUtils.randomRubble())
                    else
                        @_map.setTo(x, y, TileUtils.randomFire())

        setFire: (messageManager, times, zonesOnly) ->
            times = times or 1
            zonesOnly = zonesOnly or false

            for i in [0...times]
                x = Random.getRandom(@_map.width - 1)
                y = Random.getRandom(@_map.height - 1)
                tile = @_map.getTile(x, y)

                if not tile.isZone()
                    tile = tile.getValue()
                    #FIXME PVL validate
                    if Tile.LHTHR
                        lowerLimit = zonesOnly
                    else
                        lowerLimit = Tile.TREEBASE
                    if tile > lowerLimit and tile < Tile.LASTZONE
                        @_map.setTo(x, y, TileUtils.randomFire())
                        messageManager.sendMessage(Messages.FIRE_REPORTED, {x: x, y: y})
                        return

        #User initiated plane crash
        makeCrash: (messageManager) ->
            s = @_spriteManager.getSprite(SpriteConstants.SPRITE_PLANE)
            if s != null
                s.explodeSprite(messageManager)
                return

            x = Random.getRandom(@_map.width - 1)
            y = Random.getRandom(@_map.height - 1)
            @_spriteManager.generatePlane(x, y)
            s = @_spriteManager.getSprite(SpriteConstants.SPRITE_AIRPLANE)
            s.explodeSprite(messageManager)

        # User initiated fire
        makeFire: (messageManager) ->
            @setFire(messageManager, 40, false)

        makeFlood: (messageManager) ->
            for i in [0...300]
                x = Random.getRandom(@_map.width - 1)
                y = Random.getRandom(@_map.height - 1)
                tileValue = @_map.getTileValue(x, y)

                if tileValue > Tile.CHANNEL and tileValue <= Tile.WATER_HIGH
                    for j in [0...4]
                        xx = x + Dx[j]
                        yy = y + Dy[j]

                        if not @_map.testBounds(xx, yy)
                            continue

                        tile = @_map.getTile(xx, yy)
                        tileValue = tile.getValue()

                        if tile == Tile.DIRT or (tile.isBulldozable() and tile.isCombustible)
                            @_map.setTo(xx, yy, new Tile(Tile.FLOOD))
                            @_floodCount = 30
                            messageManager.sendMessage(Messages.FLOODING_REPORTED, {x: xx, y: yy})
                            return

        doFlood: (x, y, blockMaps) ->
            if @_floodCount > 0
                # Flood is not over yet
                for i in [0...4]
                    if Random.getChance(7)
                        xx = x + Dx[i]
                        yy = y + Dy[i]

                        if @_map.testBounds(xx, yy)
                            tile = @_map.getTile(xx, yy)
                            tileValue = tile.getValue()

                            if tile.isCombustible() or tileValue == Tile.DIRT or
                               (tileValue >= Tile.WOODS5 and tileValue < Tile.FLOOD)
                                if tile.isZone()
                                    ZoneUtils.fireZone(@map, xx, yy, blockMaps)

                                @_map.setTo(xx, yy, new Tile(Tile.FLOOD + Random.getRandom(2)))
            else
                if Random.getChance(15)
                    @_map.setTo(x, y, new Tile(Tile.DIRT))

        doMeltdown: (messageManager, x, y) ->
            @_spriteManager.makeExplosion(x - 1, y - 1)
            @_spriteManager.makeExplosion(x - 1, y + 2)
            @_spriteManager.makeExplosion(x + 2, y - 1)
            @_spriteManager.makeExplosion(x + 2, y + 2)

            # Whole power plant is at fire
            for dX in [(x - 1)...(x + 3)]
                for dY in [(y - 1)...(y + 3)]
                    @_map.setTo(dX, dY, TileUtils.randomFire())

            # Add lots of radiation tiles around the plant
            for i in [0...200]
                dX = x - 20 + Random.getRandom(40)
                dY = y - 15 + Random.getRandom(30)

                if not @_map.testBounds(dX, dY)
                    continue

                tile = @_map.getTile(dX, dY)

                if tile.isZone()
                    continue

                if tile.isCombustible() or tile.getValue() == Tile.DIRT
                    @_map.setTo(dX, dY, new Tile(Tile.RADTILE))


            # Report disaster to the user
            messageManager.sendMessage(Messages.NUCLEAR_MELTDOWN, {x: x, y: y})
