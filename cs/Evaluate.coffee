define ['MiscUtils', 'Random'], (MiscUtils, Random) ->

    PROBLEMS = ['CVP_CRIME', 'CVP_POLLUTION', 'CVP_HOUSING', 'CVP_TAXES',
                'CVP_TRAFFIC', 'CVP_UNEMPLOYMENT', 'CVP_FIRE']
    NUMPROBLEMS = PROBLEMS.length
    NUM_COMPLAINTS = 4

    getTrafficAverage = (blockMaps) ->
        trafficDensityMap = blockMaps.trafficDensityMap
        landValueMap = blockMaps.landValueMap
        trafficTotal = 0
        count = 1

        for x in [0...landValueMap.mapWidth] by landValueMap.blockSize
            for y in [0...landValueMap.mapHeight] by landValueMap.blockSize
                if landValueMap.worldGet(x, y) > 0
                    trafficTotal += trafficDensityMap.worldGet(x, y)
                    count++

        trafficAverage = Math.floor(trafficTotal / count) * 2.4
        return trafficAverage

    getFireSeverity = (census) -> Math.min(census.firePop * 5, 255)

    getUnemployment = (census) ->
        b = (census.comPop + census.indPop) * 8

        if b == 0 then return 0

        # Ratio total people / working. At least 1.
        r = census.resPop / b
        b = Math.round((r - 1) * 255)
        return Math.min(b, 255)

    class Evaluation
        constructor: (gameLevel) ->
            @problemVotes = []
            @problemOrder = []
            @evalInit()
            @gameLevel = '' + gameLevel
            @changed = false

        cityEvaluation: (simData) ->
            census = simData.census

            if census.totalPop > 0
                problemTable = []
                for i in [0...NUMPROBLEMS]
                    problemTable.push(0)

                @getAssessedValue(census)
                @doPopNum(census)
                @doProblems(simData.census, simData.budget, simData.blockMaps, problemTable)
                @getScore(simData, problemTable)
                @doVotes()
                @changeEval()
            else
                @evalInit()
                @cityYes = 50
                @changeEval()

        evalInit: ->
            @cityYes = 0
            @cityPop = 0
            @cityPopDelta = 0
            @cityAssessedValue = 0
            @cityClass = Evaluation.CC_VILLAGE
            @cityScore = 500
            @cityScoreDelta = 0
            for i in [0...NUMPROBLEMS]
                @problemVotes[i] = 0

            for i in [0...NUM_COMPLAINTS]
                @problemOrder[i] = NUMPROBLEMS

        getAssessedValue: (census) ->
            value = census.roadTotal * 5
            value += census.railTotal * 10
            value += census.policeStationPop * 1000
            value += census.fireStationPop * 1000
            value += census.hospitalPop * 400
            value += census.stadiumPop * 3000
            value += census.seaportPop * 5000
            value += census.airportPop * 10000
            value += census.coalPowerPop * 3000
            value += census.nuclearPowerPop * 6000

            @cityAssessedValue = value * 1000

        getPopulation: (census) ->
            (census.resPop + (census.comPop + census.indPop) * 8) * 20

        doPopNum: (census) ->
            oldCityPop = @cityPop
            @cityPop = @getPopulation(census)
            if oldCityPop == -1
                oldCityPop = @cityPop

            @cityPopDelta = @cityPop - oldCityPop
            @cityClass = @getCityClass(@cityPop)

        getCityClass: (cityPopulation) ->
            @cityClassification = Evaluation.CC_VILLAGE

            if cityPopulation > 2000
                @cityClassification = Evaluation.CC_TOWN

            if @cityPopulation > 10000
                @cityClassification = Evaluation.CC_CITY

            if @cityPopulation > 50000
                @cityClassification = Evaluation.CC_CAPITAL

            if @cityPopulation > 100000
                @cityClassification = Evaluation.CC_METROPOLIS

            if @cityPopulation > 500000
                @cityClassification = Evaluation.CC_MEGALOPOLIS
            return @cityClassification

        voteProblems: (problemTable) ->
            for i in [0...NUMPROBLEMS]
                @problemVotes[i] = 0
            problem = 0
            voteCount = 0
            loopCount = 0
            while voteCount < 100 and loopCount < 600
                if Random.getRandom(300) < problemTable[problem]
                    @problemVotes[problem]++
                    voteCount++

                problem++
                if problem > NUMPROBLEMS
                    problem = 0

                loopCount++
            return

        doProblems: (census, budget, blockMaps, problemTable) ->
            problemTaken = []

            for i in [0...NUMPROBLEMS]
                problemTaken[i] = false
                problemTable[i] = 0

            problemTable[Evaluation.CRIME]        = census.crimeAverage
            problemTable[Evaluation.POLLUTION]    = census.pollutionAverage
            problemTable[Evaluation.HOUSING]      = census.landValueAverage * 7 / 10
            problemTable[Evaluation.TAXES]        = budget.cityTax * 10
            problemTable[Evaluation.TRAFFIC]      = getTrafficAverage(blockMaps)
            problemTable[Evaluation.UNEMPLOYMENT] = getUnemployment(census)
            problemTable[Evaluation.FIRE]         = getFireSeverity(census)

            @voteProblems(problemTable)

            for i in [0...NUM_COMPLAINTS]
                # Find biggest problem not taken yet
                maxVotes = 0
                bestProblem = NUMPROBLEMS
                for j in [0...NUMPROBLEMS]
                    if (@problemVotes[j] > maxVotes) and (not problemTaken[j])
                        bestProblem = j
                        maxVotes = @problemVotes[j]

                # bestProblem == NUMPROBLEMS means no problem found
                @problemOrder[i] = bestProblem
                if bestProblem < NUMPROBLEMS
                    problemTaken[bestProblem] = true

        getScore: (simData, problemTable) ->
            census = simData.census
            budget = simData.budget
            valves = simData.valves
            cityScoreLast = @cityScore
            score = 0
            for i in [0...NUMPROBLEMS]
                score += problemTable[i]

            score = Math.floor(score / 3)
            score = Math.min(score, 256)
            score = MiscUtils.clamp((256 - score) * 4, 0, 1000)

            if valves.resCap
                score = Math.round(score * 0.85)
            if valves.comCap
                score = Math.round(score * 0.85)
            if valves.indCap
                score = Math.round(score * 0.85)
            if budget.roadEffect < budget.MAX_ROAD_EFFECT
                score -= budget.MAX_ROAD_EFFECT - budget.roadEffect
            if budget.policeEffect < budget.MAX_POLICE_STATION_EFFECT
                score = Math.round(score * (0.9 + (budget.policeEffect / (10.0001 * budget.MAX_POLICE_STATION_EFFECT))))
            if budget.fireEffect < budget.MAX_FIRE_STATION_EFFECT
                score = Math.round(score * (0.9 + (budget.fireEffect / (10.0001 * budget.MAX_FIRE_STATION_EFFECT))))
            if valves.resValve < -1000
                score = Math.round(score * 0.85)
            if valves.comValve < -1000
                score = Math.round(score * 0.85)
            if valves.indValve < -1000
                score = Math.round(score * 0.85)
            scale = 1.0
            if @cityPop == 0 or @cityPopDelta == 0
                scale = 1.0 # there is nobody or no migration happened
            else if @cityPopDelta == @cityPop
                scale = 1.0 # city sprang into existence or doubled in size
            else if @cityPopDelta > 0
                scale = (@cityPopDelta / @cityPop) + 1.0
            else if @cityPopDelta < 0
                scale = 0.95 + Math.floor(@cityPopDelta / (@cityPop - @cityPopDelta))

            score = Math.round(score * scale)
            score = score - getFireSeverity(census) - budget.cityTax # dec score for fires and tax
            scale = census.unpoweredZoneCount + census.poweredZoneCount # dec score for unpowered zones
            if scale > 0.0
                score = Math.round(score * (census.poweredZoneCount / scale))

            score = MiscUtils.clamp(score, 0, 1000)
            @cityScore = Math.round((@cityScore + score) / 2)
            @cityScoreDelta = @cityScore - cityScoreLast

        doVotes: ->
            @cityYes = 0
            for i in [0...100]
                if Random.getRandom(1000) < @cityScore
                    @cityYes++

        changeEval: -> @changed = true

        countProblems: ->
            for i in [0...NUM_COMPLAINTS]
                if @problemOrder[i] == NUMPROBLEMS
                    break
            return i

        getProblemNumber: (i) ->
            if i < 0 or i >= NUM_COMPLAINTS or @problemOrder[i] == NUMPROBLEMS
                return -1
            else
                return @problemOrder[i]

        getProblemVotes: (i) ->
            if i < 0 or i >= NUM_COMPLAINTS or @problemOrder[i] == NUMPROBLEMS
                return -1
            else
                return @problemVotes[@problemOrder[i]]

    Object.defineProperties(Evaluation,
        {CC_VILLAGE: MiscUtils.makeConstantDescriptor('VILLAGE'),
        CC_TOWN: MiscUtils.makeConstantDescriptor('TOWN'),
        CC_CITY: MiscUtils.makeConstantDescriptor('CITY'),
        CC_CAPITAL: MiscUtils.makeConstantDescriptor('CAPITAL'),
        CC_METROPOLIS: MiscUtils.makeConstantDescriptor('METROPOLIS'),
        CC_MEGALOPOLIS: MiscUtils.makeConstantDescriptor('MEGALOPOLIS'),
        CRIME: MiscUtils.makeConstantDescriptor(0),
        POLLUTION: MiscUtils.makeConstantDescriptor(1),
        HOUSING: MiscUtils.makeConstantDescriptor(2),
        TAXES: MiscUtils.makeConstantDescriptor(3),
        TRAFFIC: MiscUtils.makeConstantDescriptor(4),
        UNEMPLOYMENT: MiscUtils.makeConstantDescriptor(5),
        FIRE: MiscUtils.makeConstantDescriptor(6)})

    return Evaluation
