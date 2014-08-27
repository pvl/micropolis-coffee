define ['BaseSprite', 'Messages', 'MiscUtils', 'Random', 'SpriteConstants', 'SpriteUtils', 'Tile', 'TileUtils'], (BaseSprite, Messages, MiscUtils, Random, SpriteConstants, SpriteUtils, Tile, TileUtils) ->

    class ExplosionSprite extends BaseSprite

        @ID: MiscUtils.makeConstantDescriptor(7)
        @width: MiscUtils.makeConstantDescriptor(48)
        @frames: MiscUtils.makeConstantDescriptor(6)

        constructor: (map, spriteManager, x, y) ->
            @init(SpriteConstants.SPRITE_EXPLOSION, map, spriteManager, x, y)
            @width = 48
            @height = 48
            @xOffset = -24
            @yOffset = -24
            @frame = 1

        startFire: (x, y) ->
            x = SpriteUtils.pixToWorld(x)
            y = SpriteUtils.pixToWorld(y)

            if not @map.testBounds(x, y)
                return

            tile = @map.getTile(x, y)
            tileValue = tile.getValue()

            if not tile.isCombustible() and tileValue != Tile.DIRT
                return

            if tile.isZone()
                return

            @map.setTo(x, y, TileUtils.randomFire())

        move: (spriteCycle, messageManager, disasterManager, blockMaps) ->
            if (spriteCycle & 1) == 0
                if @frame == 1
                    # Convert sprite coordinates to tile coordinates.
                    explosionX = SpriteUtils.pixToWorld(@x)
                    explosionY = SpriteUtils.pixToWorld(@y)
                    messageManager.sendMessage(Messages.SOUND_EXPLOSIONHIGH)
                    messageManager.sendMessage(Messages.EXPLOSION_REPORTED, {x: explosionX, y: explosionY})
                @frame++
            if @frame > 6
                @frame = 0
                @startFire(@x, @y)
                @startFire(@x - 16, @y - 16)
                @startFire(@x + 16, @y + 16)
                @startFire(@x - 16, @y + 16)
                @startFire(@x + 16, @y + 16)

