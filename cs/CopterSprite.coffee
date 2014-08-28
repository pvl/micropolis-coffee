define ['BaseSprite', 'Messages', 'Random', 'SpriteConstants', 'SpriteUtils', 'Tile'], (BaseSprite, Messages, Random, SpriteConstants, SpriteUtils, Tile) ->

    xDelta = [0, 0, 3, 5, 3, 0, -3, -5, -3]
    yDelta = [0, -5, -3, 0, 3, 5, 3, 0, -3]

    class CopterSprite extends BaseSprite

        @ID: 2
        @width: 32
        @frames: 8

        constructor: (map, spriteManager, x, y) ->
            @init(SpriteConstants.SPRITE_HELICOPTER, map, spriteManager, x, y)
            @width = 32
            height = 32
            @xOffset = -16
            @yOffset = -16
            @frame = 5
            @count = 1500
            @destX = Random.getRandom(SpriteUtils.worldToPix(map.width)) + 8
            @destY = Random.getRandom(SpriteUtils.worldToPix(map.height)) + 8
            @origX = x
            @origY = y

        move: (spriteCycle, messageManager, disasterManager, blockMaps) ->
            @soundCount-- if @soundCount > 0
            @count-- if @count > 0
            if @count == 0
                #Head towards a monster, and certain doom
                s = @spriteManager.getSprite(SpriteConstants.SPRITE_MONSTER)
                if s != null
                    @destX = s.x
                    @destY = s.y
                else
                    #No monsters. Hm. I bet flying near that tornado is sensible
                    s = @spriteManager.getSprite(SpriteConstants.SPRITE_TORNADO)
                    if s != null
                        @destX = s.x
                        @destY = s.y
                    else
                        @destX = @origX
                        @destY = @origY
                #If near destination, let's get her on the ground
                absDist = SpriteUtils.absoluteDistance(@x, @y, @origX, @origY)
                if absDist < 30
                    @frame = 0
                    return
            if @soundCount == 0
                x = SpriteUtils.pixToWorld(@x)
                y = SpriteUtils.pixToWorld(@y)

                if x >= 0 and x < @map.width and y >= 0 and y < @map.height
                    if blockMaps.trafficDensityMap.worldGet(x, y) > 170 and (Random.getRandom16() & 7) == 0
                        messageManager.sendMessage(Messages.HEAVY_TRAFFIC, {x: x, y: y})
                        messageManager.sendMessage(Messages.SOUND_HEAVY_TRAFFIC)
                        @soundCount = 200

            frame = @frame
            if (spriteCycle & 3) == 0
                dir = SpriteUtils.getDir(@x, @y, @destX, @destY)
                frame = SpriteUtils.turnTo(frame, dir)
                @frame = frame

            @x += xDelta[frame]
            @y += yDelta[frame]

        explodeSprite: (messageManager) ->
            @frame = 0
            @spriteManager.makeExplosionAt(@x, @y)
            messageManager.sendMessage(Messages.HELICOPTER_CRASHED)

