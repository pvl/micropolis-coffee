define ['BaseSprite', 'Messages', 'MiscUtils', 'Random', 'SpriteConstants', 'SpriteUtils', 'Tile'], (BaseSprite, Messages, MiscUtils, Random, SpriteConstants, SpriteUtils, Tile) ->

    tileDeltaX = [  0, 16, 0, -16]
    tileDeltaY = [-16, 0, 16, 0 ]
    xDelta = [  0, 4, 0, -4, 0]
    yDelta = [ -4, 0, 4, 0, 0]

    TrainPic2 = [ 1, 2, 1, 2, 5]

    # Frame values
    NORTHSOUTH = 1
    EASTWEST = 2
    NWSE = 3
    NESW = 4
    UNDERWATER = 5

    # Direction values
    NORTH = 0
    EAST = 1
    SOUTH = 2
    WEST = 3
    CANTMOVE = 4

    class TrainSprite extends BaseSprite
        constructor: (map, spriteManager, x, y) ->
            @init(SpriteConstants.SPRITE_TRAIN, map, spriteManager, x, y)
            @width = 32
            @height = 32
            @xOffset = -16
            @yOffset = -16
            @frame = 1
            @dir = 4

        move: (spriteCycle, messageManager, disasterManager, blockMaps) ->
            # Trains can only move in the 4 cardinal directions
            # Over the course of 4 frames, we move through a tile, so
            # ever fourth frame, we try to find a direction to move in
            # (excluding the opposite direction from the current direction
            # of travel). If there is no possible direction found, our direction
            # is set to CANTMOVE. (Thus, if we're in a dead end, we can start heading
            # backwards next time round). If we fail to find a destination after 2 attempts,
            # we die.
            if @frame == NWSE or @frame == NESW
                @frame = TrainPic2[@dir]

            @x += xDelta[@dir]
            @y += yDelta[@dir]
            # Find a new direction.
            if (spriteCycle & 3) == 0
                # Choose a random starting point for our search
                dir = Random.getRandom16() & 3
                for i in [dir...(dir+4)]
                    dir2 = i & 3
                    if @dir != CANTMOVE
                        #Avoid the opposite direction
                        if dir2 == ((@dir + 2) & 3)
                            continue
                    tileValue = SpriteUtils.getTileValue(@map, @x + tileDeltaX[dir2], @y + tileDeltaY[dir2])
                    if (tileValue >= Tile.RAILBASE and tileValue <= Tile.LASTRAIL) or
                       tileValue == Tile.RAILVPOWERH or tileValue == Tile.RAILHPOWERV
                        if @dir != dir2 and @dir != CANTMOVE
                            if (@dir + dir2 == WEST)
                                @frame = NWSE
                            else
                                @frame = NESW
                        else
                            @frame = TrainPic2[dir2]

                        if tileValue == Tile.HRAIL or tileValue == Tile.VRAIL
                            @frame = UNDERWATER
                        @dir = dir2
                        return
                #Nowhere to go. Die.
                if @dir == CANTMOVE
                    @frame = 0
                    return
                # We didn't find a direction this time. We'll try the opposite
                # next time around
                @dir = CANTMOVE

        explodeSprite: (messageManager) ->
            @frame = 0
            @spriteManager.makeExplosionAt(@x, @y)
            messageManager.sendMessage(Messages.TRAIN_CRASHED)

        # Metadata for image loading
        Object.defineProperties(TrainSprite,
            {ID: MiscUtils.makeConstantDescriptor(1),
            width: MiscUtils.makeConstantDescriptor(32),
            frames: MiscUtils.makeConstantDescriptor(5)})
