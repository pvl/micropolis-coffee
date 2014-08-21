define [], ->
    MouseBox =
        draw: (c, pos, width, height, options) ->
            lineWidth = options.lineWidth or 3.0
            strokeStyle = options.colour or 'yellow'
            shouldOutline = (('outline' in options) and options.outline == true) or false

            startModifier = -1
            endModifier = 1
            if not shouldOutline
                startModifier = 1
                endModifier = -1

            startX = pos.x + startModifier * lineWidth / 2
            width = width + endModifier * lineWidth
            startY = pos.y + startModifier * lineWidth / 2
            height = height + endModifier * lineWidth

            ctx = c.getContext('2d')
            ctx.lineWidth = lineWidth
            ctx.strokeStyle = strokeStyle
            ctx.strokeRect(startX, startY, width, height)
