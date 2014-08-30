define ['BlockMap', 'BlockMapUtils', 'Budget', 'Census', 'Commercial', 'DisasterManager', 'EmergencyServices', 'Evaluate', 'Industrial', 'MapScanner', 'Messages', 'MessageManager', 'MiscTiles', 'PowerManager', 'RepairManager', 'Residential', 'Road', 'SpriteManager', 'Stadia', 'Traffic', 'Transport', 'Valves'], \
  (BlockMap, BlockMapUtils, Budget, Census, Commercial, DisasterManager, EmergencyServices, Evaluate, Industrial, MapScanner, Messages, MessageManager, MiscTiles, PowerManager, RepairManager, Residential, Road, SpriteManager, Stadia, Traffic, Transport, Valves) ->

    speedPowerScan = [2, 4, 5]
    speedPollutionTerrainLandValueScan = [2, 7, 17]
    speedCrimeScan = [1, 8, 18]
    speedPopulationDensityScan = [1, 9,19]
    speedFireAnalysis = [1, 10, 20]
    CENSUS_FREQUENCY_10 = 4
    CENSUS_FREQUENCY_120 = CENSUS_FREQUENCY_10 * 10
    TAX_FREQUENCY = 48

    class Simulation

        @LEVEL_EASY: 0
        @LEVEL_MED:  1
        @LEVEL_HARD: 2
        @SPEED_PAUSED: 0
        @SPEED_SLOW: 1
        @SPEED_MED: 2
        @SPEED_FAST: 3

        constructor: (gameMap, gameLevel, speed) ->
            if gameLevel != Simulation.LEVEL_EASY and
               gameLevel != Simulation.LEVEL_MED and
               gameLevel != Simulation.LEVEL_HARD
                throw new Error('Invalid level!')

            if speed != Simulation.SPEED_PAUSED and
               speed != Simulation.SPEED_SLOW and
               speed != Simulation.SPEED_MED and
               speed != Simulation.SPEED_FAST
                throw new Error('Invalid speed!')

            @_map = gameMap
            @_gameLevel = gameLevel

            @_speed = speed
            @_speedCycle = 0
            @_phaseCycle = 0
            @_simCycle = 0
            @_doInitialEval = true
            @_cityTime = 50
            @_cityPopLast = 0
            @_messageLast = Messages.VILLAGE_REACHED
            @_startingYear = 1900

            # Last valves updated to the user
            @_resValveLast = 0
            @_comValveLast = 0
            @_indValveLast = 0

            # Last date sent to front end
            @_cityYearLast = -1
            @_cityMonthLast = -1

            # And now, the main cast of characters
            @evaluation = new Evaluate(@_gameLevel)
            @_valves = new Valves()
            @budget = new Budget()
            @_census = new Census()
            @_messageManager = new MessageManager()
            @_powerManager = new PowerManager(@_map)
            @spriteManager = new SpriteManager(@_map)
            @_mapScanner = new MapScanner(@_map)
            @_repairManager = new RepairManager(@_map)
            @_traffic = new Traffic(@_map, @spriteManager)
            @disasterManager = new DisasterManager(@_map, @spriteManager, @_gameLevel)

            @blockMaps =
               comRateMap: new BlockMap(@_map.width, @_map.height, 8, 0),
               crimeRateMap: new BlockMap(@_map.width, @_map.height, 2, 0),
               fireStationMap: new BlockMap(@_map.width, @_map.height, 8, 0),
               fireStationEffectMap: new BlockMap(@_map.width, @_map.height, 8, 0),
               landValueMap: new BlockMap(@_map.width, @_map.height, 2, 0),
               policeStationMap: new BlockMap(@_map.width, @_map.height, 8, 0),
               policeStationEffectMap: new BlockMap(@_map.width, @_map.height, 8, 0),
               pollutionDensityMap: new BlockMap(@_map.width, @_map.height, 2, 0),
               populationDensityMap: new BlockMap(@_map.width, @_map.height, 2, 0),
               rateOfGrowthMap: new BlockMap(@_map.width, @_map.height, 8, 0),
               tempMap1: new BlockMap(@_map.width, @_map.height, 2, 0),
               tempMap2: new BlockMap(@_map.width, @_map.height, 2, 0),
               tempMap3: new BlockMap(@_map.width, @_map.height, 4, 0),
               terrainDensityMap: new BlockMap(@_map.width, @_map.height, 4, 0),
               trafficDensityMap: new BlockMap(@_map.width, @_map.height, 2, 0)

            @init()


        setSpeed: (s) ->
            if s != Simulation.SPEED_PAUSED and
               s != Simulation.SPEED_SLOW and
               s != Simulation.SPEED_MED and
               s != Simulation.SPEED_FAST
                throw new Error('Invalid speed!')

            @_speed = s


        isPaused: ->
            @_speed == Simulation.SPEED_PAUSED


        simTick: ->
            @_simFrame()
            # Move sprite objects
            #@spriteManager.moveObjects(@_constructSimData())
            @_updateFrontEnd()
            # TODO Graphs
            return @_messageManager.getMessages()


        _simFrame: ->
            if @budget.awaitingValues
                return

            if @_speed == 0
                return

            if @_speed == 1 and (@_speedCycle % 5) != 0
                return

            if @_speed == 2 and (@_speedCycle % 3) != 0
                return

            @_messageManager.clear()
            simData = @_constructSimData()
            @_simulate(simData)

        _clearCensus: ->
            @_census.clearCensus()
            @_powerManager.clearPowerStack()
            @blockMaps.fireStationMap.clear()
            @blockMaps.policeStationMap.clear()

        _constructSimData: ->
            res =
              blockMaps: @blockMaps,
              budget: @budget,
              census: @_census,
              cityTime: @_cityTime,
              disasterManager: @disasterManager,
              gameLevel: @_gameLevel,
              messageManager: @_messageManager,
              repairManager: @_repairManager,
              powerManager: @_powerManager,
              simulator: this,
              spriteManager: @spriteManager,
              trafficManager: @_traffic,
              valves: @_valves

        init: ->
            # Register actions
            Commercial.registerHandlers(@_mapScanner, @_repairManager)
            EmergencyServices.registerHandlers(@_mapScanner, @_repairManager)
            Industrial.registerHandlers(@_mapScanner, @_repairManager)
            MiscTiles.registerHandlers(@_mapScanner, @_repairManager)
            @_powerManager.registerHandlers(@_mapScanner, @_repairManager)
            Road.registerHandlers(@_mapScanner, @_repairManager)
            Residential.registerHandlers(@_mapScanner, @_repairManager)
            Stadia.registerHandlers(@_mapScanner, @_repairManager)
            Transport.registerHandlers(@_mapScanner, @_repairManager)

            @budget.setFunds(20000)
            simData = @_constructSimData()
            @evaluation.evalInit()
            @_valves.setValves(@_gameLevel, @_census, @budget)
            @_clearCensus()
            @_mapScanner.mapScan(0, @_map.width, simData)
            @_powerManager.doPowerScan(@_census, @_messageManager)
            BlockMapUtils.pollutionTerrainLandValueScan(@_map, @_census, @blockMaps)
            BlockMapUtils.crimeScan(@_census, @blockMaps)
            BlockMapUtils.populationDensityScan(@_map, @blockMaps)
            BlockMapUtils.fireAnalysis(@blockMaps)
            @_census.totalPop = 1

        _simulate: (simData) ->
            @_phaseCycle &= 15
            speedIndex = @_speed - 1

            switch @_phaseCycle
                when 0
                    if ++@_simCycle > 1023
                        @_simCycle = 0

                    if @_doInitialEval
                        @_doInitialEval = false
                        @evaluation.cityEvaluation(simData)

                    @_cityTime++

                    if (@_simCycle & 1) == 0
                        @_valves.setValves(@_gameLevel, @_census, @budget)

                    @_clearCensus()

                when 1,2,3,4,5,6,7,8
                    @_mapScanner.mapScan((@_phaseCycle - 1) * @_map.width / 8,
                                  @_phaseCycle * @_map.width / 8, simData)

                when 9
                    if @_cityTime % CENSUS_FREQUENCY_10 == 0
                        @_census.take10Census(budget)

                    if @_cityTime % CENSUS_FREQUENCY_120 == 0
                        @_census.take120Census(budget)

                    if @_cityTime % TAX_FREQUENCY == 0
                        @budget.collectTax(@_gameLevel, @_census, @_messageManager)
                        @evaluation.cityEvaluation(simData)

                when 10
                    if (@_simCycle % 5) == 0
                        BlockMapUtils.decRateOfGrowthMap(simData.blockMaps)

                    BlockMapUtils.decTrafficMap(@blockMaps)
                    @_sendMessages()

                when 11
                    if (@_simCycle % speedPowerScan[speedIndex]) == 0
                        @_powerManager.doPowerScan(@_census, @_messageManager)

                when 12
                    if (@_simCycle % speedPollutionTerrainLandValueScan[speedIndex]) == 0
                        BlockMapUtils.pollutionTerrainLandValueScan(@_map, @_census, @blockMaps)

                when 13
                    if (@_simCycle % speedCrimeScan[speedIndex]) == 0
                        BlockMapUtils.crimeScan(@_census, @blockMaps)

                when 14
                    if (@_simCycle % speedPopulationDensityScan[speedIndex]) == 0
                        BlockMapUtils.populationDensityScan(@_map, @blockMaps)

                when 15
                    if (@_simCycle % speedFireAnalysis[speedIndex]) == 0
                        BlockMapUtils.fireAnalysis(@blockMaps)
                    @disasterManager.doDisasters(@_census, @_messageManager)

            # Go on the the next phase.
            @_phaseCycle = (@_phaseCycle + 1) & 15



        _sendMessages: ->
            @_checkGrowth()

            totalZonePop = @_census.resZonePop + @_census.comZonePop +
                               @_census.indZonePop
            powerPop = @_census.nuclearPowerPop + @_census.coalPowerPop

            switch (@_cityTime & 63)
                when 1
                    if Math.floor(totalZonePop / 4) >= @_census.resZonePop
                        @_messageManager.sendMessage(Messages.NEED_MORE_RESIDENTIAL)

                when 5
                    if Math.floor(totalZonePop / 8) >= @_census.comZonePop
                        @_messageManager.sendMessage(Messages.NEED_MORE_COMMERCIAL)

                when 10
                    if Math.floor(totalZonePop / 8) >= @_census.indZonePop
                        @_messageManager.sendMessage(Messages.NEED_MORE_INDUSTRIAL)

                when 14
                    if totalZonePop > 10 and totalZonePop * 2 > @_census.roadTotal
                        @_messageManager.sendMessage(Messages.NEED_MORE_ROADS)

                when 18
                    if totalZonePop > 50 and totalZonePop > @_census.railTotal
                        @_messageManager.sendMessage(Messages.NEED_MORE_RAILS)

                when 22
                    if totalZonePop > 10 and powerPop == 0
                        @_messageManager.sendMessage(Messages.NEED_ELECTRICITY)

                when 26
                    if @_census.resPop > 500 and @_census.stadiumPop == 0
                        @_messageManager.sendMessage(MESSAGE_NEED_STADIUM)
                        @_valves.resCap = true
                    else
                        @_valves.resCap = false

                when 28
                    if @_census.indPop > 70 and @_census.seaportPop == 0
                        @_messageManager.sendMessage(Messages.NEED_SEAPORT)
                        @_valves.indCap = true
                    else
                        @_valves.indCap = false

                when 30
                    if @_census.comPop > 100 and @_census.airportPop == 0
                        @_messageManager.sendMessage(Messages._NEED_AIRPORT)
                        @_valves.comCap = true
                    else
                        @_valves.comCap = false

                when 32
                    zoneCount = @_census.unpoweredZoneCount + @_census.poweredZoneCount
                    if zoneCount > 0
                        if @_census.poweredZoneCount / zoneCount < 0.7
                            @_messageManager.sendMessage(Messages.BLACKOUTS_REPORTED)

                when 35
                    if @_census.pollutionAverage > 60
                        @_messageManager.sendMessage(Messages.HIGH_POLLUTION)

                when 42
                    if @_census.crimeAverage > 100
                        @_messageManager.sendMessage(Messages.HIGH_CRIME)

                when 45
                    if @_census.totalPop > 60 and @_census.fireStationPop == 0
                        @_messageManager.sendMessage(Messages.NEED_FIRE_STATION)

                when 48
                    if @_census.totalPop > 60 and @_census.policeStationPop == 0
                        @_messageManager.sendMessage(Messages.NEED_POLICE_STATION)

                when 51
                    if @budget.cityTax > 12
                        @_messageManager.sendMessage(Messages.TAX_TOO_HIGH)

                when 54
                    if @budget.roadEffect < Math.floor(5 * @budget.MAX_ROAD_EFFECT / 8) and @_census.roadTotal > 30
                        @_messageManager.sendMessage(Messages.ROAD_NEEDS_FUNDING)

                when 57
                    if @budget.fireEffect < Math.floor(7 * @budget.MAX_FIRE_STATION_EFFECT / 10) and @_census.totalPop > 20
                        @_messageManager.sendMessage(Messages.FIRE_STATION_NEEDS_FUNDING)

                when 60
                    if @budget.policeEffect < Math.floor(7 * @budget.MAX_POLICE_STATION_EFFECT / 10) and @_census.totalPop > 20
                        @_messageManager.sendMessage(Messages.POLICE_NEEDS_FUNDING)

                when 63
                    if @_census.trafficAverage > 60
                        @_messageManager.sendMessage(Messages.TRAFFIC_JAMS, -1, -1, true)

            return


        _checkGrowth: ->
            if (@_cityTime & 3) == 0
                message = ''
                thisCityPop = @evaluation.getPopulation(@_census)
                if @_cityPopLast > 0
                    lastClass = @evaluation.getCityClass(@_cityPopLast)
                    newClass = @evaluation.getCityClass(thisCityPop)

                    if lastClass != newClass
                        switch newClass
                            #when Evaluate.CC_VILLAGE
                            # Don't mention it.

                            when Evaluate.CC_TOWN
                                message = Messages.REACHED_TOWN

                            when Evaluate.CC_CITY
                                message = Messages.REACHED_CITY

                            when Evaluate.CC_CAPITAL
                                message = Messages.REACHED_CAPITAL

                            when Evaluate.CC_METROPOLIS
                                message = Messages.REACHED_METROPOLIS

                            when Evaluate.CC_MEGALOPOLIS
                                message = Messages.REACHED_MEGALOPOLIS

                if message != '' and message != @_messageLast
                    @_messageManager.sendMessage(message)
                    @_messageLast = message

                @_cityPopLast = thisCityPop


        _updateFrontEnd: ->
            # Have valves changed?
            if @_valves.changed
                @_resLast = @_valves.resValve
                @_comLast = @_valves.comValve
                @_indLast = @_valves.indValve

                # Note: the valves changed the population
                @_messageManager.sendMessage(Messages.VALVES_UPDATED,
                                             {residential: @_valves.resValve,
                                             commercial: @_valves.comValve,
                                             industrial: @_valves.indValve})
                @_valves.changed = false

            @_updateTime()

            if @evaluation.changed
                @_messageManager.sendMessage(Messages.EVAL_UPDATED,
                        {classification: @evaluation.cityClass,
                        population: @evaluation.cityPop,
                        score: @evaluation.cityScore})
                @evaluation.changed = false


        _setYear: (year) ->
            if (year < @_startingYear)
                year = @_startingYear

            year = (year - @_startingYear) - (@_cityTime / 48)
            @_cityTime += year * 48
            @_updateTime()


        _updateTime: ->
            megalinium = 1000000
            cityYear = Math.floor(@_cityTime / 48) + @_startingYear
            cityMonth = Math.floor(@_cityTime % 48) >> 2

            if cityYear >= megalinium
                @setYear(startingYear)
                return

            if @_cityYearLast != cityYear or @_cityMonthLast != cityMonth
                @_cityYearLast = cityYear
                @_cityMonthLast = cityMonth
                @_messageManager.sendMessage(Messages.DATE_UPDATED,
                                    {month: cityMonth, year: cityYear})

