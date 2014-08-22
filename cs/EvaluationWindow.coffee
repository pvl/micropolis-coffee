define ['Text'], (Text) ->

    evaluationFormID = "evaluationForm"
    evaluationOKID = "evalOK"

    class EvaluationWindow
        constructor: (opacityLayerID, evaluationWindowID) ->
            @_opacityLayer =  '#' + opacityLayerID
            @_evaluationWindowID = '#' + evaluationWindowID
            $('#' + evaluationFormID).on('submit', @submit)
            $('#' + evaluationOKID).on('click', @submit)

        submit: (e) =>
            e.preventDefault()
            # TODO Fix for enter keypress: submit isn't fired on FF due to form
            # only containing the submit button
            @_callback()
            @_toggleDisplay()

        _toggleDisplay: ->
            opacityLayer = $(@_opacityLayer)
            opacityLayer = if opacityLayer.length == 0 then null else opacityLayer
            if opacityLayer == null
                throw new Error("Node #{orig} not found")

            evaluationWindow = $(@_evaluationWindowID)
            evaluationWindow = if evaluationWindow.length == 0 then null else evaluationWindow;
            if evaluationWindow == null
                throw new Error("Node #{orig} not found")

            opacityLayer.toggle()
            evaluationWindow.toggle()

        _populateWindow: (evaluation) ->
            $('#evalYes').text(evaluation.cityYes)
            $('#evalNo').text(100 - evaluation.cityYes)
            for i in [0...4]
                problemNo = evaluation.getProblemNumber(i)
                text = ''
                if problemNo != -1
                    text = Text.problems[problemNo]
                $('#evalProb' + (i + 1)).text(text)

            $('#evalPopulation').text(evaluation.cityPop)
            $('#evalMigration').text(evaluation.cityPopDelta)
            $('#evalValue').text(evaluation.cityAssessedValue)
            $('#evalLevel').text(Text.gameLevel[evaluation.gameLevel])
            $('#evalClass').text(Text.cityClass[evaluation.cityClass])
            $('#evalScore').text(evaluation.cityScore)
            $('#evalScoreDelta').text(evaluation.cityScoreDelta)

        open: (callback, evaluation) ->
            @_callback = callback
            @_populateWindow(evaluation)
            @_toggleDisplay()
