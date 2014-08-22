define ['Direction'], (Direction) ->

    validDirs = [Direction.NORTH, Direction.NORTHEAST, Direction.EAST, Direction.SOUTHEAST,
                Direction.SOUTH, Direction.SOUTHWEST, Direction.WEST, Direction.NORTHWEST,
                Direction.INVALID]

    isNumber = (param) -> typeof(param) == 'number'

    isDirection = (param) -> isNumber(param) and validDirs.indexOf(param) != -1

    PositionMaker = (width, height) ->
        if arguments.length < 2 or typeof(width) != 'number' or
           typeof(height) != 'number' or width < 0 or height < 0
            throw new Error('Invalid parameter')

        class Position
            constructor: (pos, deltaX, deltaY) ->
                if arguments.length == 0
                    @x = 0
                    @y = 0
                    return this

                # This overloaded constructor accepts the following parameters
                # Position(x, y) - positive integral coordinates
                # Position(Position p) - assign from existing position
                # Position(Position p, Direction d) - assign from existing position and move in direction d
                # Position(Position p, deltaX, deltaY) - assign from p and then adjust x/y coordinates
                # Check for the possible combinations of arguments, and error out for invalid arguments
                if (arguments.length == 1 or arguments.length == 3) and not (pos instanceof Position)
                    throw new Error('Invalid parameter')
                if arguments.length == 3 and (not isNumber(deltaX) or not isNumber(deltaY))
                    throw new Error('Invalid parameter')
                if arguments.length == 2 and
                  ((isNumber(pos) and not isNumber(deltaX)) or
                  (pos instanceof Position and not isNumber(deltaX)) or
                  (pos instanceof Position and isNumber(deltaX) and not isDirection(deltaX)) or
                  (not isNumber(pos) and not (pos instanceof Position)))
                    throw new Error('Invalid parameter')
                moveOK = true
                if isNumber(pos)
                    # Coordinates
                    @x = pos
                    @y = deltaX
                else
                    @_assignFrom(pos)

                    if arguments.length == 2
                        moveOK = @move(deltaX)
                    else if arguments.length == 3
                        @x += deltaX
                        @y += deltaY
                if @x < 0 or @x >= width or @y < 0 or @y >= height or not moveOK
                    throw new Error('Invalid parameter')

            _assignFrom: (from) ->
                @x = from.x
                @y = from.y

            toString: -> "(#{@x},#{@y})"

            toInt: -> @y * width + @x

            move: (dir) ->
                switch dir
                    when Direction.INVALID
                        return true
                    when Direction.NORTH
                        if @y > 0
                            @y--
                            return true
                    when Direction.NORTHEAST
                        if @y > 0 and @x < width - 1
                            @y--
                            @x++
                            return true
                    when Direction.EAST
                        if @x < width - 1
                            @x++
                            return true
                    when Direction.SOUTHEAST
                        if @y < height - 1 and @x < width - 1
                            @x++
                            @y++
                            return true
                    when Direction.SOUTH
                        if @y < height - 1
                            @y++
                            return true
                    when Direction.SOUTHWEST
                        if @y < height - 1 and @x > 0
                            @y++
                            @x--
                            return true
                    when Direction.WEST
                        if @x > 0
                            @x--
                            return true
                    when Direction.NORTHWEST
                        if @y > 0 and @x > 0
                            @y--
                            @x--
                            return true
                return false
