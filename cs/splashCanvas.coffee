
define ['MouseBox', 'TileSet'], (MouseBox, TileSet) ->
    class SplashCanvas
        @DEFAULT_WIDTH: 360
        @DEFAULT_HEIGHT: 300
        @DEFAULT_ID: "SplashCanvas"

        constructor: (id, parentNode) ->
            if typeof parentNode == 'string'
                orig = parentNode
                parentNode = $('#' + parentNode)
                if parentNode.length == 0
                    parentNode = parentNode[0]
                else
                    throw new Error 'Node ' + orig + ' not found'

            @_canvas = document.createElement 'canvas'
            @_canvas.id = id
            @_canvas.width = @DEFAULT_WIDTH
            @_canvas.height = @DEFAULT_HEIGHT
            #Remove any existing element with the same id
            current = document.getElementById id
            if current != null
                if current.parentNode == parentNode
                    parentNode.replaceChild(@_canvas, current)
                else
                    throw new Error 'ID ' + id + ' already exists in document!'
            else
                parentNode.appendChild(@_canvas)

        init: (map, tileSet) ->
            if not tileSet.loaded
                throw new Error 'TileSet not ready!'
            @_tileSet = tileSet
            @paint(map)

        _paintTile: (tileVal, x, y, canvas) ->
            canvas = canvas or @_canvas
            src = @_tileSet[tileVal]
            ctx = canvas.getContext '2d'
            ctx.drawImage src,x*3,y*3,3,3

        clearMap: ->
            ctx = @_canvas.getContext '2d'
            ctx.fillStyle = 'black'
            ctx.fillRect 0,0,@_canvas.width,@_canvas.height

        paint: (map) ->
            ctx = @_canvas.getContext '2d'
            ctx.clearRect 0,0,@_canvas.width,@_canvas.height
            for y in [0...map.height]
                for x in [0...map.width]
                    @_paintTile map.getTileValue(x,y),x,y



