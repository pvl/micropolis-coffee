define ['Tile', 'TileHistory'], (Tile, TileHistory) ->

    class AnimationManager
        constructor: (map, animationPeriod, blinkPeriod) ->
            animationPeriod or= 5
            blinkPeriod or= 30

            @_map = map
            @animationPeriod = animationPeriod
            @blinkPeriod = blinkPeriod
            @shouldBlink = false
            @count = 1

            # When painting we keep track of what frames
            # have been painted at which map coordinates so we can
            # consistently display the correct frame even as the
            # canvas moves
            @_lastPainted = null

            @_data = []
            @initArray()
            @registerAnimations()

        initArray: ->
            # Map all tiles to their own value in case we ever
            # look up a tile that is not animated
            for i in [0...Tile.TILE_COUNT]
                @_data[i] = i

        inSequence: (tileValue, lastValue) ->
            # It is important that we use the base value as the starting point
            # rather than the last painted value: base values often don't recur
            # in their sequences
            seen = [tileValue]
            current = @_data[tileValue]

            while seen.indexOf(current) == -1
                if current == lastValue
                    return true

                seen.push(current)
                current = @_data[current]
            return false

        getTiles: (startX, startY, boundX, boundY, isPaused) ->
            isPaused or= false
            shouldChangeAnimation = false
            if not isPaused
                @count += 1

            if (@count % @blinkPeriod) == 0
                @shouldBlink = not @shouldBlink

            if (@count % @animationPeriod) == 0 and not isPaused
                shouldChangeAnimation = true

            newPainted = new TileHistory()
            tilesToPaint = []

            for x in [startX...boundX]
                for y in [startY...boundY]
                    if x < 0 or x >= @_map.width or y < 0 or y >= @_map.height
                        continue

                    tile = @_map.getTile(x, y)
                    if tile.isZone()and not tile.isPowered() and @shouldBlink
                        tilesToPaint.push({x: x, y: y, tileValue: Tile.LIGHTNINGBOLT})
                        continue

                    if not tile.isAnimated()
                        continue

                    tileValue = tile.getValue()
                    newTile = Tile.TILE_INVALID
                    if @_lastPainted
                        last = @_lastPainted.getTile(x, y)

                    if shouldChangeAnimation
                        # Have we painted any of this sequence before? If so, paint the next tile
                        if last and @inSequence(tileValue, last)
                            newTile = @_data[last]
                        else
                            # Either we haven't painted anything here before, or the last tile painted
                            # there belongs to a different tile's animation sequence
                            newTile = @_data[tileValue]
                    else
                        # Have we painted any of this sequence before? If so, paint the same tile
                        if last and @inSequence(tileValue, last)
                            newTile = last

                    if newTile == Tile.TILE_INVALID
                        continue

                    tilesToPaint.push({x: x, y: y, tileValue: newTile})
                    newPainted.setTile(x, y, newTile)

            @_lastPainted = newPainted
            return tilesToPaint

        registerSingleAnimation: (arr) ->
            for i in [1...arr.length]
                @_data[arr[i - 1]] = arr[i]

        registerAnimations: ->
            @registerSingleAnimation([56, 57, 58, 59, 60, 61, 62, 63, 56])
            @registerSingleAnimation([80, 128, 112, 96, 80])
            @registerSingleAnimation([81, 129, 113, 97, 81])
            @registerSingleAnimation([82, 130, 114, 98, 82])
            @registerSingleAnimation([83, 131, 115, 99, 83])
            @registerSingleAnimation([84, 132, 116, 100, 84])
            @registerSingleAnimation([85, 133, 117, 101, 85])
            @registerSingleAnimation([86, 134, 118, 102, 86])
            @registerSingleAnimation([87, 135, 119, 103, 87])
            @registerSingleAnimation([88, 136, 120, 104, 88])
            @registerSingleAnimation([89, 137, 121, 105, 89])
            @registerSingleAnimation([90, 138, 122, 106, 90])
            @registerSingleAnimation([91, 139, 123, 107, 91])
            @registerSingleAnimation([92, 140, 124, 108, 92])
            @registerSingleAnimation([93, 141, 125, 109, 93])
            @registerSingleAnimation([94, 142, 126, 110, 94])
            @registerSingleAnimation([95, 143, 127, 111, 95])
            @registerSingleAnimation([144, 192, 176, 160, 144])
            @registerSingleAnimation([145, 193, 177, 161, 145])
            @registerSingleAnimation([146, 194, 178, 162, 146])
            @registerSingleAnimation([147, 195, 179, 163, 147])
            @registerSingleAnimation([148, 196, 180, 164, 148])
            @registerSingleAnimation([149, 197, 181, 165, 149])
            @registerSingleAnimation([150, 198, 182, 166, 150])
            @registerSingleAnimation([151, 199, 183, 167, 151])
            @registerSingleAnimation([152, 200, 184, 168, 152])
            @registerSingleAnimation([153, 201, 185, 169, 153])
            @registerSingleAnimation([154, 202, 186, 170, 154])
            @registerSingleAnimation([155, 203, 187, 171, 155])
            @registerSingleAnimation([156, 204, 188, 172, 156])
            @registerSingleAnimation([157, 205, 189, 173, 157])
            @registerSingleAnimation([158, 206, 190, 174, 158])
            @registerSingleAnimation([159, 207, 191, 175, 159])
            @registerSingleAnimation([621, 852, 853, 854, 855, 856, 857, 858, 859, 852])
            @registerSingleAnimation([641, 884, 885, 886, 887, 884])
            @registerSingleAnimation([644, 888, 889, 890, 891, 888])
            @registerSingleAnimation([649, 892, 893, 894, 895, 892])
            @registerSingleAnimation([650, 896, 897, 898, 899, 896])
            @registerSingleAnimation([676, 900, 901, 902, 903, 900])
            @registerSingleAnimation([677, 904, 905, 906, 907, 904])
            @registerSingleAnimation([686, 908, 909, 910, 911, 908])
            @registerSingleAnimation([689, 912, 913, 914, 915, 912])
            @registerSingleAnimation([747, 916, 917, 918, 919, 916])
            @registerSingleAnimation([748, 920, 921, 922, 923, 920])
            @registerSingleAnimation([751, 924, 925, 926, 927, 924])
            @registerSingleAnimation([752, 928, 929, 930, 931, 928])
            @registerSingleAnimation([820, 952, 953, 954, 955, 952])
            @registerSingleAnimation([832, 833, 834, 835, 836, 837, 838, 839, 832])
            @registerSingleAnimation([840, 841, 842, 843, 840])
            @registerSingleAnimation([844, 845, 846, 847, 848, 849, 850, 851, 844])
            @registerSingleAnimation([932, 933, 934, 935, 936, 937, 938, 939, 932])
            @registerSingleAnimation([940, 941, 942, 943, 944, 945, 946, 947, 940])
            return
