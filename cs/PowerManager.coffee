define ['BlockMap', 'Direction', 'Messages', 'Tile'], (BlockMap, Direction, Messages, Tile) ->

    COAL_POWER_STRENGTH = 700
    NUCLEAR_POWER_STRENGTH = 2000

    dX = [1, 2, 1, 2]
    dY = [-1, -1, 0, 0]
    meltdownTable = [30000, 20000, 10000]

    class PowerManager
        constructor: (map) ->
            @_map = map
            @_powerStack = []
            @powerGridMap = new BlockMap(@_map.width, @_map.height, 1, 0)

        setTilePower: (x, y) ->
            tile = @_map.getTile(x, y)
            tileValue = tile.getValue()

            if tileValue == Tile.NUCLEAR or tileValue == Tile.POWERPLANT or
               @powerGridMap.worldGet(x, y) > 0
                tile.addFlags(Tile.POWERBIT)
                return

            tile.removeFlags(Tile.POWERBIT)

        clearPowerStack: ->
            @_powerStackPointer = 0
            @_powerStack = []

        testForConductive: (pos, testDir) ->
            movedPos = new @_map.Position(pos)
            if movedPos.move(testDir)
                if @_map.getTile(movedPos.x, movedPos.y).isConductive()
                    if @powerGridMap.worldGet(movedPos.x, movedPos.y) == 0
                        return true
            return false

        # Note: the algorithm is buggy: if you have two adjacent power
        # plants, the second will be regarded as drawing power from the first
        # rather than as a power source itself
        doPowerScan: (census, messageManager) ->
            # Clear power @_map.
            @powerGridMap.clear()
            # Power that the combined coal and nuclear power plants can deliver.
            maxPower = census.coalPowerPop * COAL_POWER_STRENGTH +
                       census.nuclearPowerPop * NUCLEAR_POWER_STRENGTH

            powerConsumption = 0 # Amount of power used.
            while @_powerStack.length > 0
                pos = @_powerStack.pop()
                anyDir = Direction.INVALID
                while true
                    powerConsumption++
                    if powerConsumption > maxPower
                        messageManager.sendMessage(Messages.NOT_ENOUGH_POWER);
                        return
                    if anyDir != Direction.INVALID
                        pos.move(anyDir)
                    @powerGridMap.worldSet(pos.x, pos.y, 1)
                    conNum = 0
                    dir = Direction.BEGIN
                    while dir < Direction.END and conNum < 2
                        if @testForConductive(pos, dir)
                            conNum++
                            anyDir = dir
                        dir = Direction.increment90(dir)
                    if conNum > 1
                        @_powerStack.push(new @_map.Position(pos))
                    if not conNum
                        break

        coalPowerFound: (map, x, y, simData) =>
            simData.census.coalPowerPop += 1;
            @_powerStack.push(new map.Position(x, y));

            # Ensure animation runs
            dX = [-1, 2, 1, 2];
            dY = [-1, -1, 0, 0];

            for i in [0...4]
                map.addTileFlags(x + dX[i], y + dY[i], Tile.ANIMBIT)

        nuclearPowerFound: (map, x, y, simData) =>
            # TODO With the auto repair system, zone gets repaired before meltdown
            # In original Micropolis code, we bail and don't repair if melting down
            if simData.disasterManager.disastersEnabled and
               Random.getRandom(meltdownTable[simData.gameLevel]) == 0
                simData.disasterManager.doMeltdown(messageManager, x, y)
                return

            simData.census.nuclearPowerPop += 1
            @_powerStack.push(new map.Position(x, y))
            #Ensure animation bits set
            for i in [0...4]
                map.addTileFlags(x, y, Tile.ANIMBIT | Tile.CONDBIT | Tile.POWERBIT | Tile.BURNBIT)

        registerHandlers: (mapScanner, repairManager) ->
            mapScanner.addAction(Tile.POWERPLANT, @coalPowerFound)
            mapScanner.addAction(Tile.NUCLEAR, @nuclearPowerFound)
            repairManager.addAction(Tile.POWERPLANT, 7, 4)
            repairManager.addAction(Tile.NUCLEAR, 7, 4)
