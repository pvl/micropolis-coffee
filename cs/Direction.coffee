define [], ->
    Direction =
        "INVALID": -1,
        "NORTH": 0,
        "NORTHEAST": 1,
        "EAST": 2,
        "SOUTHEAST": 3,
        "SOUTH": 4,
        "SOUTHWEST": 5,
        "WEST": 6,
        "NORTHWEST": 7,
        "BEGIN": 0,
        "END": 8,

        # Move direction clockwise by 45 degrees. No bounds checking
        # i.e. result could be >= END. Has no effect on INVALID. Undefined
        # when dir >= END
        increment45: (dir, count) ->
            throw new TypeError() if arguments.length < 1
            return dir if dir == @INVALID
            if not count and count != 0
                count = 1
            return dir + count

        # Move direction clockwise by 90 degrees. No bounds checking
        # i.e. result could be >= END. Has no effect on INVALID. Undefined
        # when dir >= END
        increment90: (dir) ->
            throw new TypeError() if arguments.length < 1
            return @increment45(dir, 2)

        # Move direction clockwise by 45 degrees, taking the direction modulo 8
        # if necessary to force it into valid bounds. Has no effect on INVALID.
        rotate45: (dir, count) ->
            throw new TypeError() if arguments.length < 1
            return dir if dir == @INVALID
            if not count and count != 0
                count = 1
            return ((dir - @NORTH + count) & 7) + @NORTH

        # Move direction clockwise by 90 degrees, taking the direction modulo 8
        # if necessary to force it into valid bounds. Has no effect on INVALID.
        rotate90: (dir) ->
            throw new TypeError() if arguments.length < 1
            return @rotate45(dir, 2)

        # Move direction clockwise by 180 degrees, taking the direction modulo 8
        # if necessary to force it into valid bounds. Has no effect on INVALID.
        rotate180: (dir) ->
            throw new TypeError() if arguments.length < 1
            return @rotate45(dir, 4)

    return Direction
