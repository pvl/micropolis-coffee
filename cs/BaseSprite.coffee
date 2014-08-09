define ['SpriteUtils'], (SpriteUtils) ->

    class BaseSprite
        init: (@type, @map, @spriteManager, @x, @y) ->
            @origX = 0;
            @origY = 0;
            @destX = 0;
            @destY = 0;
            @count = 0;
            @soundCount = 0;
            @dir = 0;
            @newDir = 0;
            @step = 0;
            @flag = 0;
            @turn = 0;
            @accel = 0;
            @speed = 100

        getFileName: ->
            ['obj', @type, '-', @frame - 1].join('')

        spriteNotInBounds: ->
            x = SpriteUtils.pixToWorld(@x)
            y = SpriteUtils.pixToWorld(@y)
            x < 0 or y < 0 or x >= @map.width or y >= @map.height

