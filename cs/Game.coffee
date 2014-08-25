define ['BudgetWindow', 'DisasterWindow', 'GameCanvas', 'EvaluationWindow', 'InfoBar', 'InputStatus', 'Messages', 'MessageManager', 'Notification', 'QueryWindow', 'RCI', 'Simulation', 'Text'], \
  (BudgetWindow, DisasterWindow, GameCanvas, EvaluationWindow, InfoBar, InputStatus, Messages, MessageManager, Notification, QueryWindow, RCI, Simulation, Text) ->

    nextFrame = window.mozRequestAnimationFrame or window.webkitRequestAnimationFrame

    class Game
        constructor: (gameMap, tileSet, spriteSheet, difficulty) ->
            difficulty = difficulty or 0

            @gameMap = gameMap
            @tileSet = tileSet
            @simulation = new Simulation(@gameMap, difficulty, 1)
            @rci = new RCI('RCIContainer')
            @budgetWindow = new BudgetWindow('opaque', 'budget')
            @queryWindow = new QueryWindow('opaque', 'queryWindow')
            @evalWindow = new EvaluationWindow('opaque', 'evalWindow')
            @disasterWindow = new DisasterWindow('opaque', 'disasterWindow')

            @gameCanvas = new GameCanvas('canvasContainer')
            @gameCanvas.init(@gameMap, @tileSet, spriteSheet)
            @inputStatus = new InputStatus(@gameMap)
            @mouse = null
            @sprites = null
            @lastCoord = null

            # Unhide controls
            @revealControls()

            @budgetShowing = false
            @queryShowing = false
            @evalShowing = false
            @simNeedsBudget = false
            @isPaused = false

            @tick()
            @animate()

        revealControls: ->
            $('.initialHidden').each (e) ->
                $(this).removeClass('initialHidden')

            Notification.news(Text.neutralMessages[Messages.WELCOME])
            @rci.update(0, 0, 0)

        handleDisasterClosed: (request) =>
            @disasterShowing = false
            if request == DisasterWindow.DISASTER_NONE
                return
            m = new MessageManager()
            switch request
                when DisasterWindow.DISASTER_MONSTER
                    @simulation.spriteManager.makeMonster(m)
                when DisasterWindow.DISASTER_FIRE
                    @simulation.disasterManager.makeFire(m)
                when DisasterWindow.DISASTER_FLOOD
                    @simulation.disasterManager.makeFlood(m)
                when DisasterWindow.DISASTER_CRASH
                    @simulation.disasterManager.makeCrash(m)
                when DisasterWindow.DISASTER_MELTDOWN
                    @simulation.disasterManager.makeMeltdown(m)
                when DisasterWindow.DISASTER_TORNADO
                    @simulation.spriteManager.makeTornado(m)
            @processMessages(m.getMessages())

        handleEvalClosed: =>
            @evalShowing = false

        handleQueryClosed: =>
            @queryShowing = false

        handleBudgetClosed: (cancelled, data) =>
            @budgetShowing = false
            if not cancelled
                @simulation.budget.roadPercent = data.roadPercent / 100
                @simulation.budget.firePercent = data.firePercent / 100
                @simulation.budget.policePercent = data.policePercent / 100
                @simulation.budget.setTax(data.taxPercent)
                if @simNeededBudget
                    @simulation.budget.doBudget(new MessageManager())
                    @simNeededBudget = false
                else
                    @simulation.budget.updateFundEffects()

        handleDisasterRequest: ->
            @disasterShowing = true
            @disasterWindow.open(@handleDisasterClosed)

            # Let the input know we handled this request
            @inputStatus.disasterHandled()
            nextFrame(@tick)

        handleEvalRequest: ->
            @evalShowing = true
            @evalWindow.open(@handleEvalClosed, @simulation.evaluation)

            # Let the input know we handled this request
            @inputStatus.evalHandled()
            nextFrame(@tick)

        handleBudgetRequest: ->
            @budgetShowing = true
            budgetData =
                roadFund: @simulation.budget.roadFund,
                roadRate: Math.floor(@simulation.budget.roadPercent * 100),
                fireFund: @simulation.budget.fireFund,
                fireRate: Math.floor(@simulation.budget.firePercent * 100),
                policeFund: @simulation.budget.policeFund,
                policeRate: Math.floor(@simulation.budget.policePercent * 100),
                taxRate: @simulation.budget.cityTax,
                totalFunds: @simulation.budget.totalFunds,
                taxesCollected: @simulation.budget.taxFund

            @budgetWindow.open(@handleBudgetClosed, budgetData)
            # Let the input know we handled this request
            @inputStatus.budgetHandled()
            nextFrame(@tick)

        handleTool: (x, y) ->
            #Were was the tool clicked?
            tileCoords = @gameCanvas.canvasCoordinateToTileCoordinate(x, y)
            if tileCoords == null
                @inputStatus.clickHandled()
                return
            tool = @inputStatus.currentTool
            budget = @simulation.budget
            evaluation = @simulation.evaluation
            messageMgr = new MessageManager()
            # do it!
            tool.doTool(tileCoords.x, tileCoords.y, messageMgr, @simulation.blockMaps)
            tool.modifyIfEnoughFunding(budget, messageMgr)
            switch tool.result
                when tool.TOOLRESULT_NEEDS_BULLDOZE
                    $('#toolOutput').text(Text.toolMessages.needsDoze)
                when tool.TOOLRESULT_NO_MONEY
                    $('#toolOutput').text(Text.toolMessages.noMoney)
                else
                    $('#toolOutput').html('&nbsp;')
            @processMessages(messageMgr.getMessages())
            @inputStatus.clickHandled()

        handleSpeedChange: ->
            # XXX Currently only offer pause and run to the user
            # No real difference among the speeds until we optimise
            # the sim
            @isPaused = not @isPaused
            if (@isPaused)
                @simulation.setSpeed(Simulation.SPEED_PAUSED)
            else
                @simulation.setSpeed(Simulation.SPEED_SLOW)
            @inputStatus.speedChangeHandled()

        handleInput: ->
            if @inputStatus.budgetRequested
                @handleBudgetRequest()
                return

            if @inputStatus.evalRequested
                @handleEvalRequest()
                return

            if @inputStatus.disasterRequested
                @handleDisasterRequest()
                return

            if @inputStatus.speedChangeRequested
                @handleSpeedChange()
                return

            # Handle keyboard movement
            if @inputStatus.left
                @gameCanvas.moveWest()
            else if @inputStatus.up
                @gameCanvas.moveNorth()
            else if @inputStatus.right
                @gameCanvas.moveEast()
            else if @inputStatus.down
                @gameCanvas.moveSouth()

            # Was a tool clicked?
            if @inputStatus.currentTool != null and
               @inputStatus.clickX != -1 and
               @inputStatus.clickY != -1
                @handleTool(@inputStatus.clickX, @inputStatus.clickY)


        processMessages: (messages) ->
            # Don't want to output more than one user message
            messageOutput = false
            for i in [0...messages.length]
                m = messages[i]
                switch m.message
                    when Messages.BUDGET_NEEDED
                        @simNeededBudget = true
                        @handleBudgetRequest()
                    when Messages.QUERY_WINDOW_NEEDED
                        @queryWindow.open(@handleQueryClosed)
                    when Messages.DATE_UPDATED
                        InfoBar.setDate(m.data.month, m.data.year)
                    when Messages.EVAL_UPDATED
                        InfoBar.setClass(Text.cityClass[m.data.classification])
                        InfoBar.setScore(m.data.score)
                        InfoBar.setPopulation(m.data.population)
                    when Messages.FUNDS_CHANGED
                        InfoBar.setFunds(m.data)
                    when Messages.VALVES_UPDATED
                        @rci.update(m.data.residential, m.data.commercial, m.data.industrial)
                    else
                        if not messageOutput and Text.goodMessages[m.message] != undefined
                            messageOutput = true
                            Notification.goodNews(Text.goodMessages[m.message])
                        else if not messageOutput and Text.badMessages[m.message] != undefined
                            messageOutput = true
                            Notification.badNews(Text.badMessages[m.message])
                        else if not messageOutput and Text.neutralMessages[m.message] != undefined
                            messageOutput = true
                            Notification.news(Text.neutralMessages[m.message])

        calculateMouseForPaint: ->
            # Determine whether we need to draw a tool outline in the
            # canvas
            mouse = null
            if @inputStatus.mouseX != -1 and @inputStatus.toolWidth > 0
                tileCoords = @gameCanvas.canvasCoordinateToTileOffset(@inputStatus.mouseX, @inputStatus.mouseY)
                if tileCoords != null
                    mouse = {}

                    mouse.x = tileCoords.x
                    mouse.y = tileCoords.y

                    # The inputStatus fields came from DOM attributes, so will be strings.
                    # Coerce back to numbers.
                    mouse.width = @inputStatus.toolWidth - 0
                    mouse.height = @inputStatus.toolWidth - 0
                    mouse.colour = @inputStatus.toolColour or 'yellow'
            return mouse

        calculateSpritesForPaint: ->
            origin = @gameCanvas.getTileOrigin()
            end = @gameCanvas.getMaxTile()
            spriteList = @simulation.spriteManager.getSpritesInView(origin.x, origin.y, end.x + 1, end.y + 1)

            if spriteList.length == 0
                return null

            return spriteList

        tick: =>
            @handleInput()

            if @budgetShowing or @queryShowing or @disasterShowing or @evalShowing
                window.setTimeout(@tick, 0)
                return
            if not @simulation.isPaused()
                # Run the sim
                messages = @simulation.simTick()
                @processMessages(messages)
            # Run this even when paused: you can still build when paused
            @mouse = @calculateMouseForPaint()
            window.setTimeout(@tick, 0)

        animate: =>
            # Don't run on blur - bad things seem to happen
            # when switching back to our tab in Fx
            if @budgetShowing or @queryShowing or
               @disasterShowing or @evalShowing
                nextFrame(@animate)
                return
            # TEMP
            @frameCount++
            date = new Date()
            elapsed = Math.floor((date - @animStart) / 1000)
            # TEMP
            if elapsed > 0
                @d.textContent = Math.floor(@frameCount/elapsed) + ' fps'

            if not @isPaused
                @simulation.spriteManager.moveObjects(@simulation._constructSimData())

            @sprite = @calculateSpritesForPaint()
            @gameCanvas.paint(@mouse, @sprite, @isPaused)

            nextFrame(@animate)
