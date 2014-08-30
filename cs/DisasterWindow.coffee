define [], () ->

    disasterSelectID = 'disasterSelect'
    disasterCancelID = 'disasterCancel'
    disasterOKID = 'disasterOK'
    disasterFormID = 'disasterForm'

    class DisasterWindow

        @DISASTER_NONE: 'None'
        @DISASTER_MONSTER: 'Monster'
        @DISASTER_FIRE: 'Fire'
        @DISASTER_FLOOD: 'Flood'
        @DISASTER_CRASH: 'Crash'
        @DISASTER_MELTDOWN: 'Meltdown'
        @DISASTER_TORNADO: 'Tornado'

        constructor: (opacityLayerID, disasterWindowID) ->
            @_opacityLayer =  '#' + opacityLayerID
            @_disasterWindowID = '#' + disasterWindowID
            @_requestedDisaster = DisasterWindow.DISASTER_NONE

        cancel: (e) =>
            e.preventDefault()
            $('#' + disasterFormID).off()
            @_toggleDisplay()
            @_callback(DisasterWindow.DISASTER_NONE)

        submit = (e) =>
            e.preventDefault()
            # Get element values
            requestedDisaster = $('#' + disasterSelectID)[0].value
            $('#' + disasterFormID).off()
            @_toggleDisplay()
            @_callback(requestedDisaster)

        _toggleDisplay: ->
            opacityLayer = $(@_opacityLayer)
            opacityLayer = opacityLayer.length == 0 ? null : opacityLayer
            if opacityLayer == null
                throw new Error('Node ' + orig + ' not found')

            disasterWindow = $(@_disasterWindowID)
            disasterWindow = disasterWindow.length == 0 ? null : disasterWindow
            if disasterWindow == null
                throw new Error('Node ' + orig + ' not found')

            opacityLayer.toggle()
            disasterWindow.toggle()

        _registerButtonListeners: ->
            $('#' + disasterCancelID).one('click', @cancel)
            $('#' + disasterFormID).one('submit', @submit)

        open: (callback) ->
            @_callback = callback
            # Ensure options have right values
            $('#disasterNone').attr('value', DisasterWindow.DISASTER_NONE)
            $('#disasterMonster').attr('value', DisasterWindow.DISASTER_MONSTER)
            $('#disasterFire').attr('value', DisasterWindow.DISASTER_FIRE)
            $('#disasterFlood').attr('value', DisasterWindow.DISASTER_FLOOD)
            $('#disasterCrash').attr('value', DisasterWindow.DISASTER_CRASH)
            $('#disasterMeltdown').attr('value', DisasterWindow.DISASTER_MELTDOWN)
            $('#disasterTornado').attr('value', DisasterWindow.DISASTER_TORNADO)

            @_registerButtonListeners()
            @_toggleDisplay()

