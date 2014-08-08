define ['BaseSprite', 'Messages', 'MiscUtils', 'Random', 'SpriteConstants', 'SpriteUtils'], (BaseSprite, Messages, MiscUtils, Random, SpriteConstants, SpriteUtils) ->
    class AirplaneSprite extends BaseSprite

        xDelta = [0, 0, 6, 8, 6, 0, -6, -8, -6, 8, 8, 8]
        yDelta = [0, -8, -6, 0, 6, 8,  6, 0, -6, 0, 0, 0]

        constructor: (map, spriteManager, x, y) ->
            @init SpriteConstants.SPRITE_AIRPLANE, map, spriteManager, x, y
            @width = 48
            @weight = 48
            @xOffset = -24
            @yOffset = -24
            if x > SpriteUtils.worldToPix(map.width - 20)
                @destX = @x - 200
                @frame = 7
            else
                @destX = @x + 200
                @frame = 11
            @destY = @y


        move: (spriteCycle, messageManager, disasterManager, blockMaps) ->
            frame = @frame
            if (spriteCycle % 5) == 0
                # Frames > 8 mean the plane is taking off
                if frame > 8
                    frame--
                    if frame < 9
                        # Planes always take off to the east
                        frame = 3
                    @frame = frame
                else
                    d = SpriteUtils.getDir @x, @y, @destX, @destY
                    frame = SpriteUtils.turnTo frame, d
                    @frame = frame

            absDist = SpriteUtils.absoluteDistance @x, @y, @destX, @destY
            if absDist < 50
                # We're pretty close to the destination
                @destX = Random.getRandom(SpriteUtils.worldToPix(@map.width)) + 8
                @destY = Random.getRandom(SpriteUtils.worldToPix(@map.height)) + 8

            if disasterManager.enableDisasters
                explode = false

                spriteList = @spriteManager.getSpriteList()
                for i in [0...spriteList.length]
                    s = spriteList[i]
                    if s.frame == 0 or s == sprite
                        continue

                    if (s.type == SpriteConstants.SPRITE_HELICOPTER or s.type == SpriteConstants.SPRITE_AIRPLANE) and SpriteUtils.checkSpriteCollision(this, s)
                        s.explodeSprite messageManager
                        explode = true

                @explodeSprite messageManager if explode
            @x += xDelta[frame]
            @y += yDelta[frame]

            @frame = 0 if @spriteNotInBounds()

        explodeSprite: (messageManager) ->
            @frame = 0
            @spriteManager.makeExplosionAt @x, @y
            messageManager.sendMessage Messages.PLANE_CRASHED

    # Metadata for image loading (PVL FIXME)
    Object.defineProperties(AirplaneSprite,
        {ID: MiscUtils.makeConstantDescriptor(3),
        width: MiscUtils.makeConstantDescriptor(48),
        frames: MiscUtils.makeConstantDescriptor(11)})

    return AirplaneSprite
