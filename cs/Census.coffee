define ['MiscUtils'], (MiscUtils) ->

    topics = ['res', 'com', 'ind', 'crime','money', 'pollution']

    class Census
        constructor: ->
            @clearCensus()
            @changed = false
            @crimeRamp = 0
            @pollutionRamp = 0

            # Set externally
            @landValueAverage = 0
            @pollutionAverage = 0
            @crimeAverage = 0
            @totalPop = 0

            for topic in topics
                name10 = topic + 'Hist10'
                name120 = topic + 'Hist120'
                @[name10] = @createArray()
                @[name120] = @createArray()

        createArray: ->
            new_array = []
            for a in [0...120]
                new_array[a] = 0

        rotate10Arrays: ->
            for topic in topics
                name10 = topic + 'Hist10'
                @[name10] = [0].concat(@[name10].slice(0, -1))

        rotate120Arrays: ->
            for topic in topics
                name120 = topic + 'Hist120'
                @[name120] = [0].concat(@[name120].slice(0, -1))

        clearCensus: ->
            @poweredZoneCount = 0
            @unpoweredZoneCount = 0
            @firePop = 0
            @roadTotal = 0
            @railTotal = 0
            @resPop = 0
            @comPop = 0
            @indPop = 0
            @resZonePop = 0
            @comZonePop = 0
            @indZonePop = 0
            @hospitalPop = 0
            @churchPop = 0
            @policeStationPop = 0
            @fireStationPop = 0
            @stadiumPop = 0
            @coalPowerPop = 0
            @nuclearPowerPop = 0
            @seaportPop = 0
            @airportPop = 0

        take10Census: (budget) ->
            @rotate10Arrays()
            resPopDenom = 8
            @resHist10[0] = Math.floor(@resPop / resPopDenom)
            @comHist10[0] = @comPop
            @indHist10[0] = @indPop

            @crimeRamp += Math.floor((@crimeAverage - @crimeRamp) / 4)
            @crimeHist10[0] = Math.min(@crimeRamp, 255)

            @pollutionRamp += Math.floor((@pollutionAverage - @pollutionRamp) / 4)
            @pollutionHist10[0] = Math.min(@pollutionRamp, 255)

            x = Math.floor(budget.cashFlow / 20) + 128
            @moneyHist10[0] = MiscUtils.clamp(x, 0, 255)

            resPopScaled = @resPop >> 8

            if @hospitalPop < @resPopScaled
              @needHospital = 1
            else if @hospitalPop > @resPopScaled
              @needHospital = -1
            else if @hospitalPop == @resPopScaled
              @needHospital = 0

            @changed = true

        take120Census: ->
            @rotate120Arrays()
            resPopDenom = 8
            @resHist120[0] = Math.floor(@resPop / resPopDenom)
            @comHist120[0] = @comPop
            @indHist120[0] = @indPop
            @crimeHist120[0] = @crimeHist10[0]
            @pollutionHist120[0] = @pollutionHist10[0]
            @moneyHist120[0] = @moneyHist10[0]
            @changed = true
