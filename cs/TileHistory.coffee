define [], ->
    toKey = (x, y) -> [x, y].join(',')

    class TileHistory
        constructor: ->
            @data = {}

        getTile: (x, y) ->
            @data[toKey(x, y)]

        setTile: (x, y, value) ->
            @data[toKey(x, y)] = value
