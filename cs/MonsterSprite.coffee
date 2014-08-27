define ['BaseSprite', 'Messages', 'MiscUtils', 'Random', 'SpriteConstants', 'SpriteUtils', 'Tile', 'TileUtils'], (BaseSprite, Messages, MiscUtils, Random, SpriteConstants, SpriteUtils, Tile, TileUtils) ->

    xDelta = [ 2, 2, -2, -2, 0]
    yDelta = [-2, 2, 2, -2, 0]
    cardinals1 = [ 0, 1, 2, 3]
    cardinals2 = [ 1, 2, 3, 0]
    diagonals1 = [ 2, 5, 8, 11]
    diagonals2 = [11, 2, 5, 8]

    class MonsterSprite extends BaseSprite

        @ID: MiscUtils.makeConstantDescriptor(5)
        @width: MiscUtils.makeConstantDescriptor(48)
        @frames: MiscUtils.makeConstantDescriptor(16)

        constructor: (map, spriteManager, x, y) ->
            @init(SpriteConstants.SPRITE_MONSTER, map, spriteManager, x, y)
            @width = 48
            @height = 48
            @xOffset = -24
            @yOffset = -24

            if x > SpriteUtils.worldToPix(map.width) / 2
                if y > SpriteUtils.worldToPix(map.height) / 2
                    @frame = 10
                else
                    @frame = 7
            else if y > SpriteUtils.worldToPix(map.height) / 2
                @frame = 1
            else
                @frame = 4

            @flag = 0
            @count = 1000
            @destX = SpriteUtils.worldToPix(map.pollutionMaxX)
            @destY = SpriteUtils.worldToPix(map.pollutionMaxY)
            @origX = @x
            @origY = @y
            @_seenLand = false

        move: (spriteCycle, messageManager, disasterManager, blockMaps) ->
            if @soundCount > 0
                @soundCount--

            # Frames 1 - 12 are diagonal sprites, 3 for each direction.
            # 1-3 NE, 2-6 SE, etc. 13-16 represent the cardinal directions.
            currentDir = Math.floor((@frame - 1) / 3)
            if currentDir < 4 # turn n s e w
                # Calculate how far in the 3 step animation we were,
                # move on to the next one
                frame = (@frame - 1) % 3
                if frame == 2
                    @step = 0
                else if frame == 0
                    @step = 1

                if @step
                    frame++
                else
                    frame--
                absDist = SpriteUtils.absoluteDistance(@x, @y, @destX, @destY)
                if absDist < 60
                    if @flag == 0
                        @flag = 1
                        @destX = @origX
                        @destY = @origY
                    else
                        @frame = 0
                        return
                #Perhaps switch to a cardinal direction
                dir = SpriteUtils.getDir(@x, @y, @destX, @destY)
                dir = Math.floor((dir - 1) / 2)

                if dir != currentDir and Random.getChance(10)
                    if Random.getRandom16() & 1
                        frame = cardinals1[currentDir]
                    else
                        frame = cardinals2[currentDir]
                    currentDir = 4
                    if not @soundCount
                        messageManager.sendMessage(Messages.SOUND_MONSTER)
                        @soundCount = 50 + Random.getRandom(100)
            else
                #Travelling in a cardinal direction. Switch to a diagonal
                currentDir = 4
                dir = @frame
                frame = (dir - 13) & 3

                if not (Random.getRandom16() & 3)
                    if Random.getRandom16() & 1
                        frame = diagonals1[frame]
                    else
                        frame = diagonals2[frame]

                    # We mung currentDir and frame here to
                    # make the assignment below work
                    currentDir = Math.floor((frame - 1) / 3)
                    frame = (frame - 1) % 3

            frame = currentDir * 3 + frame + 1
            frame = 16 if frame > 16
            @frame = frame
            @x += xDelta[currentDir]
            @y += yDelta[currentDir]
            @count-- if @count > 0
            tileValue = SpriteUtils.getTileValue(@map, @x, @y)

            if tileValue == -1 or (tileValue == Tile.RIVER and @count < 500)
                @frame = 0

            if tileValue == Tile.DIRT or tileValue > Tile.WATER_HIGH
                @_seenLand = true

            spriteList = @spriteManager.getSpriteList()
            for i in [0...spriteList.length]
                s = spriteList[i]
                if s.frame != 0 and
                   (s.type == SpriteConstants.SPRITE_AIRPLANE or s.type == SpriteConstants.SPRITE_HELICOPTER or
                   s.type == SpriteConstants.SPRITE_SHIP or s.type == SpriteConstants.SPRITE_TRAIN) and
                   SpriteUtils.checkSpriteCollision(this, s)
                    s.explodeSprite(messageManager)

            SpriteUtils.destroyMapTile(@spriteManager, @map, blockMaps, @x, @y)

