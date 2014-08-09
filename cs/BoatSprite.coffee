define ['BaseSprite', 'Messages', 'MiscUtils', 'Random', 'SpriteConstants', 'SpriteUtils', 'Tile'], (BaseSprite, Messages, MiscUtils, Random, SpriteConstants, SpriteUtils, Tile) ->

    tileDeltaX = [0,  0,  1,  1,  1,  0, -1, -1, -1]
    tileDeltaY = [0, -1, -1,  0,  1,  1,  1,  0, -1]
    xDelta = [0,  0,  2,  2,  2,  0, -2, -2, -2]
    yDelta = [0, -2, -2,  0,  2,  2,  2,  0, -2]
    tileWhiteList = [Tile.RIVER, Tile.CHANNEL, Tile.POWERBASE,
                        Tile.POWERBASE + 1, Tile.RAILBASE,
                        Tile.RAILBASE + 1, Tile.BRWH, Tile.BRWV]

    CANTMOVE = 10

    class BoatSprite extends BaseSprite

        constructor: (map, spriteManager, x, y) ->
            @init(SpriteConstants.SPRITE_SHIP, map, spriteManager, x, y)
            [@width, @height] = [48, 48]
            [@xOffset, @yOffset]  = [-24, -24]

            if x < SpriteUtils.worldToPix(4)
                @frame = 3
            else if x >= SpriteUtils.worldToPix(map.width - 4)
                @frame = 7
            else if y < SpriteUtils.worldToPix(4)
                @frame = 5;
            else if y >= SpriteUtils.worldToPix(map.height - 4)
                @frame = 1;
            else
                @frame = 3

            newDir = @frame
            @dir = 10
            @count = 1

        # This is an odd little function. It returns true if
        # oldDir is 180° from newDir and tileValue is underwater
        # rail or wire, and returns false otherwise
        oppositeAndUnderwater: (tileValue, oldDir, newDir) ->
            opposite = oldDir + 4

            opposite -= 8 if opposite > 8

            if newDir != opposite
                return false

            if (tileValue == Tile.POWERBASE or tileValue == Tile.POWERBASE + 1 or
               tileValue == Tile.RAILBASE or tileValue == Tile.RAILBASE + 1)
                return true

            return false

        move: (spriteCycle, messageManager, disasterManager, blockMaps) ->
            tile = Tile.RIVER
            @soundCount-- if @soundCount > 0
            if @soundCount == 0
                if (Random.getRandom16() & 3) == 1
                    # TODO Scenarios
                    # TODO Sound
                    messageManager.sendMessage(Messages.SOUND_HONKHONK)
                @soundCount = 200
            @count-- if @count > 0
            if @count == 0
                #Ships turn slowly: only 45° every 9 cycles
                @count = 9
                #If already executing a turn, continue to do so
                if @frame != @newDir
                    @frame = SpriteUtils.turnTo(@frame, @newDir)
                    return
                # Otherwise pick a new direction
                # Choose a random starting direction to search from
                # 0 = N, 1 = NE, ... 7 = NW
                startDir = Random.getRandom16() & 7
                for dir in [startDir...(startDir+8)]
                    frame = (dir & 7) + 1
                    if frame == @dir
                        continue
                    x = SpriteUtils.pixToWorld(@x) + tileDeltaX[frame]
                    y = SpriteUtils.pixToWorld(@y) + tileDeltaY[frame]
                    if @map.testBounds(x, y)
                        tileValue = @map.getTileValue(x, y)
                        #Test for a suitable water tile
                        if tileValue == Tile.CHANNEL or tileValue == Tile.BRWH or
                           tileValue == Tile.BRWV or underwaterOrOpposite(tileValue, @dir, frame)
                            @newDir = frame
                            @frame = SpriteUtils.turnTo(@frame, @newDir)
                            @dir = frame + 4
                            @dir -= 8 if @dir > 8
                            break
                if dir == (startDir + 8)
                    @dir = CANTMOVE
                    @newDir = (Random.getRandom16() & 7) + 1
            else
                frame = @frame
                if frame == @newDir
                    @x += xDelta[frame]
                    @y += yDelta[frame]

            if @spriteNotInBounds()
                @frame = 0
                return

            # If we didn't find a new direction, we might explode
            # depending on the last tile we looked at.
            for i in [0...8]
                if t == tileWhiteList[i]
                    break
                if i == 7
                    @explodeSprite(messageManager)
                    SpriteUtils.destroyMapTile(@spriteManager, @map, blockMaps, @x, @y)

        explodeSprite: (messageManager) ->
            @frame = 0
            @spriteManager.makeExplosionAt(@x, @y)
            messageManager.sendMessage(Messages.SHIP_CRASHED)

        #Metadata for image loading
        Object.defineProperties(BoatSprite,
            {ID: MiscUtils.makeConstantDescriptor(4),
            width: MiscUtils.makeConstantDescriptor(48),
            frames: MiscUtils.makeConstantDescriptor(8)})
