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
                    this.x = 0
                    this.y = 0
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
                    this.x = pos
                    this.y = deltaX
                else
                    this._assignFrom(pos)

                    if arguments.length == 2
                        moveOK = this.move(deltaX)
                    else if arguments.length == 3
                        this.x += deltaX
                        this.y += deltaY
                if this.x < 0 or this.x >= width or this.y < 0 or this.y >= height or not moveOK
                    throw new Error('Invalid parameter')

            _assignFrom: (from) ->
                this.x = from.x
                this.y = from.y

            toString: -> "(#{this.x},#{this.y})"

            toInt: -> this.y * width + this.x

            move: (dir) ->
                switch dir
                    when Direction.INVALID
                        return true
                    when Direction.NORTH
                        if this.y > 0
                            this.y--
                            return true
                    when Direction.NORTHEAST
                        if this.y > 0 and this.x < width - 1
                            this.y--
                            this.x++
                            return true
                    when Direction.EAST
                        if this.x < width - 1
                            this.x++
                            return true
                    when Direction.SOUTHEAST
                        if this.y < height - 1 and this.x < width - 1
                            this.x++
                            this.y++
                            return true
                    when Direction.SOUTH
                        if this.y < height - 1
                            this.y++
                            return true
                    when Direction.SOUTHWEST
                        if this.y < height - 1 and this.x > 0
                            this.y++
                            this.x--
                            return true
                    when Direction.WEST
                        if this.x > 0
                            this.x--
                            return true
                    when Direction.NORTHWEST
                        if this.y > 0 and this.x > 0
                            this.y--
                            this.x--
                            return true
                return false
