define ['Messages', 'MiscUtils'], (Messages, MiscUtils) ->

    RLevels = [0.7, 0.9, 1.2]
    FLevels = [1.4, 1.2, 0.8]

    class Budget
        constructor: ->
            Object.defineProperties(this,
                {MAX_ROAD_EFFECT: MiscUtils.makeConstantDescriptor(32),
                MAX_POLICESTATION_EFFECT: MiscUtils.makeConstantDescriptor(1000),
                MAX_FIRESTATION_EFFECT:  MiscUtils.makeConstantDescriptor(1000)})

            @roadEffect = @MAX_ROAD_EFFECT
            @policeEffect = @MAX_POLICESTATION_EFFECT
            @fireEffect = @MAX_FIRESTATION_EFFECT
            @totalFunds = 0
            @cityTax = 7
            @cashFlow = 0
            @taxFund = 0
            # The 'fund's respresent the cost of funding all these services on
            # the map 100%
            @roadFund = 0
            @fireFund = 0
            @policeFund = 0

            # Percentage of budget used
            @roadPercent = 1
            @firePercent = 1
            @policePercent = 1

            # Cash value of spending. Should equal Math.round(_Fund * _Percent)
            @roadSpend = 0
            @fireSpend = 0
            @policeSpend = 0

            @autoBudget = true

        doBudget: (messageManager) -> @doBudgetNow(false, messageManager)

        # User initiated budget
        doBudgetMenu: (messageManager) -> @doBudgetNow(false, messageManager)

        doBudgetNow: (fromWindow, messageManager) ->
            # How much would we be spending based on current percentages?
            @roadSpend = Math.round(@roadFund * @roadPercent)
            @fireSpend = Math.round(@fireFund * @firePercent)
            @policeSpend = Math.round(@policeFund * @policePercent)
            total = @roadSpend + @fireSpend + @policeSpend

            # If we don't have any services on the map, we can bail early
            if total == 0
                @roadPercent = 1
                @firePercent = 1
                @policePercent = 1
                @roadEffect = @MAX_ROAD_EFFECT
                @policeEffect = @MAX_POLICESTATION_EFFECT
                @fireEffect = @MAX_FIRESTATION_EFFECT

            cashAvailable = @totalFunds + @taxFund
            cashRemaining = cashAvailable

            # How much are we actually going to spend?
            roadValue = 0
            fireValue = 0
            policeValue = 0

            # Spending priorities: road, fire, police
            if (cashRemaining >= @roadSpend)
                roadValue = @roadSpend
            else
                roadValue = cashRemaining
            cashRemaining -= roadValue

            if (cashRemaining >= @fireSpend)
                fireValue = @fireSpend
            else
                fireValue = cashRemaining
            cashRemaining -= fireValue

            if (cashRemaining >= @policeSpend)
                policeValue = @policeSpend
            else
                policeValue = cashRemaining
            cashRemaining -= policeValue

            if @roadFund > 0
                @roadPercent = new Number(roadValue / @roadFund).toPrecision(2) - 0
            else
                @roadPercent = 1

            if @fireFund > 0
                @firePercent = new Number(fireValue / @fireFund).toPrecision(2) - 0
            else
                @fireFund = 1

            if @policeFund > 0
                @policePercent = new Number(policeValue / @policeFund).toPrecision(2) - 0
            else
                @policeFund = 1

            if not @autoBudget or fromWindow
                # If we were called as the result of a manual budget,
                # go ahead and spend the money
                if not fromWindow
                    @doBudgetSpend(roadValue, fireValue, policeValue, @cityTax, messageManager)
                return
            # Autobudget
            if cashAvailable >= total
                # We were able to fully fund services. Go ahead and spend
                @doBudgetSpend(roadValue, fireValue, policeValue, @cityTax, messageManager)
                return
            # Uh-oh. Not enough money. Make this the user's problem.
            # They don't know it yet, but they're about to get a budget window.
            @autoBudget = false
            messageManager.sendMessage(Messages.AUTOBUDGET_CHANGED, @autoBudget)
            messageManager.sendMessage(Messages.BUDGET_NEEDED)
            messageManager.sendMessage(Messages.NO_MONEY)

        doBudgetSpend: (roadValue, fireValue, policeValue, taxRate, messageManager) ->
            @roadSpend = roadValue
            @fireSpend = fireValue
            @policeSpend = policeValue
            @setTax(taxRate)
            total = @roadSpend + @fireSpend + @policeSpend

            @spend(-(@taxFund - total), messageManager)
            @updateFundEffects()

        updateFundEffects: ->
            # Update effects
            @roadEffect = @MAX_ROAD_EFFECT
            @policeEffect = @MAX_POLICESTATION_EFFECT
            @fireEffect = @MAX_FIRESTATION_EFFECT

            if @roadFund > 0
                @roadEffect = Math.floor(@roadEffect * @roadSpend / @roadFund)

            if @fireFund > 0
                @fireEffect = Math.floor(@fireEffect * @fireSpend / @fireFund)

            if @policeFund > 0
                @policeEffect = Math.floor(@policeEffect * @policeSpend / @policeFund)

        collectTax: (gameLevel, census, messageManager) ->
            @cashFlow = 0

            @policeFund = census.policeStationPop * 100
            @fireFund = census.fireStationPop * 100
            @roadFund = Math.floor((census.roadTotal + (census.railTotal * 2)) * RLevels[gameLevel])
            @taxFund = Math.floor(Math.floor(census.totalPop * census.landValueAverage / 120) * @cityTax * FLevels[gameLevel])

            if census.totalPop > 0
                @cashFlow = @taxFund - (@policeFund + @fireFund + @roadFund)
                @doBudget(messageManager)
            else
                # We don't want roads etc deteriorating when population hasn't yet been established
                # (particularly early game)
                @roadEffect   = @MAX_ROAD_EFFECT
                @policeEffect = @MAX_POLICESTATION_EFFECT
                @fireEffect   = @MAX_FIRESTATION_EFFECT

        setTax: (amount, messageManager) ->
            if amount == @cityTax then return
            @cityTax = amount
            if messageManager != undefined
                messageManager.sendMessage(Messages.TAXRATE_CHANGED, @cityTax)

        setFunds: (amount, messageManager) ->
            if amount == @totalFunds then return
            @totalFunds = Math.max(0, amount)

            if messageManager != undefined
                messageManager.sendMessage(Messages.FUNDS_CHANGED, @totalFunds)

        spend: (amount, messageManager) ->
            @setFunds(@totalFunds - amount, messageManager)

        shouldDegradeRoad: ->
            @roadEffect < Math.floor(15 * @MAX_ROAD_EFFECT / 16)


