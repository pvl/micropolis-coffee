define ['Tile', 'ZoneUtils'], (Tile, ZoneUtils) ->

    pixToWorld = (p) -> p >> 4
    worldToPix = (w) -> w << 4

    # Attempt to move 45° towards the desired direction, either
    # clockwise or anticlockwise, whichever gets us there quicker
    turnTo = (presentDir, desiredDir) ->
        if presentDir == desiredDir
            return presentDir

        if presentDir < desiredDir
            # select clockwise or anticlockwise
            if desiredDir - presentDir < 4
                presentDir++
            else
                presentDir--
        else
            if presentDir - desiredDir < 4
                presentDir--
            else
                presentDir++

        if presentDir > 8
            presentDir = 1

        if presentDir < 1
            presentDir = 8

        return presentDir

    getTileValue = (map, x, y) ->
        wX = pixToWorld(x)
        wY = pixToWorld(y)

        if wX < 0 or wX >= map.width or wY < 0 or wY >= map.height
            return -1

        return map.getTileValue(wX, wY)

    # Choose the best direction to get from the origin to the destination
    # If the destination is equidistant in both x and y deltas, a diagonal
    # will be chosen, otherwise the most 'dominant' difference will be selected
    # (so if a destination is 4 units north and 2 units east, north will be chosen).
    # This code seems to always choose south if we're already there which seems like
    # a bug
    directionTable = [0, 3, 2, 1, 3, 4, 5, 7, 6, 5, 7, 8, 1]

    getDir = (orgX, orgY, destX, destY) ->
        deltaX = destX - orgX
        deltaY = destY - orgY

        if deltaX < 0
            if deltaY < 0
                i = 11
            else
                i = 8
        else
            if deltaY < 0
                i = 2
            else
                i = 5
        deltaX = Math.abs(deltaX)
        deltaY = Math.abs(deltaY)

        if deltaX * 2 < deltaY
            i++
        else if deltaY * 2 < deltaX
            i--

        if i < 0 or i > 12
            i = 0

        return directionTable[i]

    absoluteDistance = (orgX, orgY, destX, destY) ->
        deltaX = destX - orgX
        deltaY = destY - orgY
        return Math.abs(deltaX) + Math.abs(deltaY)

    checkWet = (tileValue) ->
        if tileValue == Tile.HPOWER or tileValue == Tile.VPOWER or
           tileValue == Tile.HRAIL or tileValue == Tile.VRAIL or
           tileValue == Tile.BRWH or tileValue == Tile.BRWV
            return true
        else
            return false

    destroyMapTile = (spriteManager, map, blockMaps, ox, oy) ->
        pixToWorld(ox)
        y = pixToWorld(oy)

        if not map.testBounds(x, y)
            return

        tile = map.getTile(x, y)
        tileValue = tile.getValue()

        if tileValue < Tile.TREEBASE
            return

        if not tile.isCombustible()
            if tileValue >= Tile.ROADBASE and tileValue <= Tile.LASTROAD
                map.setTo(x, y, new Tile(Tile.RIVER))
            return

        if tile.isZone()
            ZoneUtils.fireZone(map, x, y, blockMaps)

        if tileValue > Tile.RZB
            spriteManager.makeExplosionAt(ox, oy)

        if checkWet(tileValue)
            map.setTo(x, y, new Tile(Tile.RIVER))
        else
            map.setTo(x, y, new Tile(Tile.TINYEXP, Tile.BULLBIT | Tile.ANIMBIT))

    getDistance = (x1, y1, x2, y2) ->
        Math.abs(x1 - x2) + Math.abs(y1 - y2)

    checkSpriteCollision = (s1, s2) ->
        s1.frame != 0 and s2.frame != 0 and getDistance(s1.x, s1.y, s2.x, s2.y) < 30

    SpriteUtils =
        absoluteDistance: absoluteDistance
        checkSpriteCollision: checkSpriteCollision
        destroyMapTile: destroyMapTile
        getDir: getDir
        getTileValue: getTileValue
        turnTo: turnTo
        pixToWorld: pixToWorld
        worldToPix: worldToPix
