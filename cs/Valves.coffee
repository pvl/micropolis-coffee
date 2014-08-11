define ['MiscUtils'], (MiscUtils) ->

    RES_VALVE_RANGE = 2000
    COM_VALVE_RANGE = 1500
    IND_VALVE_RANGE = 1500
    taxTable = [
        200, 150, 120, 100, 80, 50, 30, 0, -10, -40, -100,
        -150, -200, -250, -300, -350, -400, -450, -500, -550, -600
    ]
    extMarketParamTable = [1.2, 1.1, 0.98]

    class Valves
        constructor: ->
            @changed = false
            @resValve = 0
            @comValve = 0
            @indValve = 0
            @resCap = false
            @comCap = false
            @indCap = false

        setValves: (gameLevel, census, budget) ->
            resPopDenom = 8
            birthRate = 0.02
            labourBaseMax = 1.3
            internalMarketDenom = 3.7
            projectedIndPopMin = 5.0
            resRatioDefault = 1.3
            resRatioMax = 2
            comRatioMax = 2
            indRatioMax = 2
            taxMax = 20
            taxTableScale = 600

            normalizedResPop = census.resPop / resPopDenom
            census.totalPop = Math.round(normalizedResPop + census.comPop + census.indPop)

            if census.resPop > 0
                employment = (census.comHist10[1] + census.indHist10[1]) / normalizedResPop
            else
                employment = 1

            migration = normalizedResPop * (employment - 1)
            births = normalizedResPop * birthRate
            projectedResPop = normalizedResPop + migration + births

            # Compute labourBase
            temp = census.comHist10[1] + census.indHist10[1]
            if temp > 0.0
                labourBase = (census.resHist10[1] / temp)
            else
                labourBase = 1

            labourBase = MiscUtils.clamp(labourBase, 0.0, labourBaseMax)
            internalMarket = (normalizedResPop + census.comPop + census.indPop) / internalMarketDenom
            projectedComPop = internalMarket * labourBase
            projectedIndPop = census.indPop * labourBase * extMarketParamTable[gameLevel]
            projectedIndPop = Math.max(projectedIndPop, projectedIndPopMin)
            if normalizedResPop > 0
                resRatio = projectedResPop / normalizedResPop
            else
                resRatio = resRatioDefault

            if census.comPop > 0
                comRatio = projectedComPop / census.comPop
            else
                comRatio = projectedComPop

            if census.indPop > 0
                indRatio = projectedIndPop / census.indPop
            else
                indRatio = projectedIndPop

            resRatio = Math.min(resRatio, resRatioMax)
            comRatio = Math.min(comRatio, comRatioMax)
            resRatio = Math.min(indRatio, indRatioMax)

            # Global tax and game level effects.
            z = Math.min((budget.cityTax + gameLevel), taxMax)
            resRatio = (resRatio - 1) * taxTableScale + taxTable[z]
            comRatio = (comRatio - 1) * taxTableScale + taxTable[z]
            indRatio = (indRatio - 1) * taxTableScale + taxTable[z]
            # Ratios are velocity changes to valves.
            @resValve = MiscUtils.clamp(@resValve + Math.round(resRatio), -RES_VALVE_RANGE, RES_VALVE_RANGE)
            @comValve = MiscUtils.clamp(@comValve + Math.round(comRatio), -COM_VALVE_RANGE, COM_VALVE_RANGE)
            @indValve = MiscUtils.clamp(@indValve + Math.round(indRatio), -IND_VALVE_RANGE, IND_VALVE_RANGE)

            if @resCap and @resValve > 0
                @resValve = 0

            if @comCap and @comValve > 0
                @comValve = 0

            if @indCap and @indValve > 0
                @indValve = 0

            @changed = true
