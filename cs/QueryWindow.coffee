define [], ->

    queryFormID = "queryForm"
    queryOKID = "queryForm"
    # Keep in sync with QueryTool
    debug = false

    class QueryWindow
        constructor: (opacityLayerID, queryWindowID) ->
            @_opacityLayer =  '#' + opacityLayerID
            @_queryWindowID = '#' + queryWindowID
            @_debugToggled = false
            $('#' + queryFormID).on('submit', @submit)
            $('#' + queryOKID).on('click', @submit)

        submit: (e) =>
            e.preventDefault()
            @_callback()
            @_toggleDisplay()

        _toggleDisplay: ->
            opacityLayer = $(@_opacityLayer)
            opacityLayer = if opacityLayer.length == 0 then null else opacityLayer
            if opacityLayer == null
                throw new Error("Node #{orig} not found")

            queryWindow = $(@_queryWindowID)
            queryWindow = if queryWindow.length == 0 then null else queryWindow
            if queryWindow == null
                throw new Error("Node #{orig} not found")

            opacityLayer.toggle()
            queryWindow.toggle()
            if debug and not @debugToggled
                $('#queryDebug').removeClass('hidden')
                @debugToggled = true

        open: (callback) ->
            @_callback = callback
            @_toggleDisplay()

