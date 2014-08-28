define ['BaseSprite', 'Messages', 'Random', 'SpriteConstants', 'SpriteUtils'], (BaseSprite, Messages, Random, SpriteConstants, SpriteUtils) ->

    xDelta = [2, 3, 2, 0, -2, -3]
    yDelta = [-2, 0, 2, 3, 2, 0]

    class TornadoSprite extends BaseSprite

        @ID: 6
        @width: 48
        @frames: 3

        constructor: (map, spriteManager, x, y) ->
            @init(SpriteConstants.SPRITE_TORNADO, map, spriteManager, x, y)
            @width = 48
            @height = 48
            @xOffset = -24
            @yOffset = -40
            @frame = 1
            @count = 200

        move: (spriteCycle, messageManager, disasterManager, blockMaps) ->
            frame = @frame
            # If middle frame, move right or left
            # depending on the flag value
            # If frame = 1, perhaps die based on flag
            # value
            if frame == 2
                if @flag
                    frame = 3
                else
                    frame = 1
            else
                if frame == 1
                    @flag = 1
                else
                    @flag = 0
                frame = 2

            if @count > 0
                @count--

            @frame = frame
            spriteList = @spriteManager.getSpriteList()
            for i in [0...spriteList.length]
                s = spriteList[i]
                # Explode vulnerable sprites
                if s.frame != 0 and
                   (s.type == SpriteConstants.SPRITE_AIRPLANE or s.type == SpriteConstants.SPRITE_HELICOPTER or
                   s.type == SpriteConstants.SPRITE_SHIP or s.type == SpriteConstants.SPRITE_TRAIN) and
                   SpriteUtils.checkSpriteCollision(this, s)
                    s.explodeSprite(messageManager)

            frame = Random.getRandom(5)
            @x += xDelta[frame]
            @y += yDelta[frame]

            @frame = 0 if @spriteNotInBounds()

            if @count != 0 and Random.getRandom(500) == 0
                @frame = 0

            SpriteUtils.destroyMapTile(@spriteManager, @map, blockMaps, @x, @y)

