define ['MiscUtils'], (MiscUtils) ->

    class RCI
        constructor: (id, parentNode) ->
            e = new Error('Invalid parameter')
            if arguments.length < 1
                throw e
            # Argument shuffling
            if parentNode == undefined
                parentNode = id
                id = RCI.DEFAULT_ID
            if typeof(parentNode) == 'string'
                orig = parentNode
                parentNode = $('#' + parentNode)
                parentNode = if parentNode.length == 0 then null else parentNode[0]
                if parentNode == null
                    throw new Error('Node ' + orig + ' not found')

            @_padding = 3 # 3 rectangles in each bit of padding
            @_buckets = 10 # 0.2000 is scaled in to 10 buckets
            @_rectSize = 5 # Each rect is 5px
            @_scale = Math.floor(2000 / @_buckets)

            # Each bar is 1 unit of padding wide, and there are 2 units
            # of padding between the 3 bars. There are 2 units of padding
            # either side. So 9 units of padding total
            @_canvasWidth = 9 * @_rectSize

            # Each bar can be at most bucket rectangles tall, but we multiply
            # that by 2 as we can have positive and negative directions. There
            # should be 1 unit of padding either side. The text box in the middle
            # is 1 unit of padding
            @_canvasHeight = (2 * @_buckets + 3 * @_padding) * @_rectSize

            @_canvas = $('<canvas></canvas>', {id: id})[0]
            # Remove any existing element with the same id
            elems = $('#' + id)
            current = if elems.length > 0 then elems[0] else null
            if current != null
                if current.parentNode == parentNode
                    parentNode.replaceChild(@_canvas, current)
                else
                    throw new Error('ID ' + id + ' already exists in document!')
            else
                parentNode.appendChild(@_canvas)

        _clear: (ctx) ->
            ctx.clearRect(0, 0, @_canvas.width, @_canvas.height)

        _drawRect: (ctx) ->
            # The rect is inset by one unit of padding
            boxLeft = @_padding * @_rectSize
            # and is the length of a bar plus a unit of padding down
            boxTop = (@_buckets + @_padding) * @_rectSize
            # It must accomodate 3 bars, 2 bits of internal padding
            # with padding either side
            boxWidth = 7 * @_padding * @_rectSize
            boxHeight = @_padding * @_rectSize

            ctx.fillStyle = 'rgb(192, 192, 192)'
            ctx.fillRect(boxLeft, boxTop, boxWidth, boxHeight)

        _drawValue: (ctx, index, value) ->
            # Need to scale com and ind
            if index > 1
                value = Math.floor(2000/1500 * value)

            colours = ['rgb(0,255,0)', 'rgb(0, 0, 139)', 'rgb(255, 255, 0)']
            barHeightRect = Math.floor(Math.abs(value) / @_scale)
            barStartY = if (value >= 0)
                @_buckets + @_padding - barHeightRect
              else
                @_buckets + 2 * @_padding
            barStartX = 2 * @_padding + (index * 2 * @_padding)

            ctx.fillStyle = colours[index]
            ctx.fillRect(barStartX * @_rectSize, barStartY * @_rectSize,
                         @_padding * @_rectSize, barHeightRect * @_rectSize)

        _drawLabel: (ctx, index) ->
            labels = ['R', 'C', 'I']
            textLeft = 2 * @_padding + (index * 2 * @_padding) +
                                   Math.floor(@_padding/2)

            ctx.font = 'normal xx-small sans-serif'
            ctx.fillStyle = 'rgb(0, 0, 0)'
            ctx.textBaseline = 'bottom'
            ctx.fillText(labels[index], textLeft * @_rectSize,
                         (@_buckets + 2 * @_padding) * @_rectSize)

        update: (res, com, ind) ->
            ctx = @_canvas.getContext('2d')
            @_clear(ctx)
            @_drawRect(ctx)

            values = [res, com, ind]
            for i in [0...3]
                @_drawValue(ctx, i, values[i])
                @_drawLabel(ctx, i)

        Object.defineProperty(RCI, 'DEFAULT_ID', MiscUtils.makeConstantDescriptor('RCICanvas'))
