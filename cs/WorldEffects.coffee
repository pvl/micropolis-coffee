define ['Tile'], (Tile) ->

    toKey = (x, y) -> [x, y].join(',')

    fromKey = (k) ->
        k = k.split(',')
        {x: k[0] - 0, y: k[1] - 0}

    class WorldEffects
        constructor: (map) ->
            this._map = map
            this._data = {}

        clear: -> this._data = []

        getTile: (x, y) ->
            key = toKey(x, y)
            tile = this._data[key]
            if tile == undefined
                tile = this._map.getTile(x, y)
            return tile

        getTileValue: (x, y) -> this.getTile(x, y).getValue()

        setTile: (x, y, value, flags) ->
            if flags != undefined and value instanceof Tile
                throw new Error('Flags supplied with already defined tile')

            if flags == undefined and not (value instanceof Tile)
                value = new Tile(value)
            else if flags != undefined
                value = new Tile(value, flags)

            key = toKey(x, y)
            this._data[key] = value

        apply: ->
            keys = Object.keys(this._data)
            for i in [0...keys.length]
                coords = fromKey(keys[i])
                this._map.setTo(coords, this._data[keys[i]])
