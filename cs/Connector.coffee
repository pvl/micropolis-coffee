define ['Tile', 'TileUtils'], (Tile, TileUtils) ->
    RoadTable = [
        Tile.ROADS, Tile.ROADS2, Tile.ROADS, Tile.ROADS3,
        Tile.ROADS2, Tile.ROADS2, Tile.ROADS4, Tile.ROADS8,
        Tile.ROADS, Tile.ROADS6, Tile.ROADS, Tile.ROADS7,
        Tile.ROADS5, Tile.ROADS10, Tile.ROADS9, Tile.INTERSECTION
    ]

    RailTable = [
        Tile.LHRAIL, Tile.LVRAIL, Tile.LHRAIL, Tile.LVRAIL2,
        Tile.LVRAIL, Tile.LVRAIL, Tile.LVRAIL3, Tile.LVRAIL7,
        Tile.LHRAIL, Tile.LVRAIL5, Tile.LHRAIL, Tile.LVRAIL6,
        Tile.LVRAIL4, Tile.LVRAIL9, Tile.LVRAIL8, Tile.LVRAIL10
    ]

    WireTable = [
        Tile.LHPOWER, Tile.LVPOWER, Tile.LHPOWER, Tile.LVPOWER2,
        Tile.LVPOWER, Tile.LVPOWER, Tile.LVPOWER3, Tile.LVPOWER7,
        Tile.LHPOWER, Tile.LVPOWER5, Tile.LHPOWER, Tile.LVPOWER6,
        Tile.LVPOWER4, Tile.LVPOWER9, Tile.LVPOWER8, Tile.LVPOWER10
    ]

    class Connector

        fixSingle: (x, y) ->
            adjTile = 0
            tile = TileUtils.normalizeRoad(@_worldEffects.getTile(x, y))
            if tile >= Tile.ROADS and tile <= Tile.INTERSECTION
                if y > 0
                    tile = TileUtils.normalizeRoad(@_worldEffects.getTile(x, y-1))
                    if ((tile == Tile.HRAILROAD or (tile >= Tile.ROADBASE and tile <= Tile.VROADPOWER)) and
                       tile != Tile.HROADPOWER and tile != Tile.VRAILROAD and
                       tile != Tile.ROADBASE)
                        adjTile |= 1

                if x < @_map.width - 1
                    tile = TileUtils.normalizeRoad(@_worldEffects.getTile(x+1, y))
                    if ((tile == Tile.VRAILROAD or (tile >= Tile.ROADBASE and tile <= Tile.VROADPOWER)) and
                       tile != Tile.VROADPOWER and tile != Tile.HRAILROAD and
                       tile != Tile.VBRIDGE)
                        adjTile |= 2

                if y < @_map.height - 1
                    tile = TileUtils.normalizeRoad(@_worldEffects.getTile(x, y+1))
                    if ((tile == Tile.HRAILROAD or (tile >= Tile.ROADBASE and tile <= Tile.VROADPOWER)) and
                       tile != Tile.HROADPOWER and tile != Tile.VRAILROAD and
                       tile != Tile.ROADBASE)
                        adjTile |= 4

                if x > 0
                    tile = TileUtils.normalizeRoad(@_worldEffects.getTile(x-1, y))
                    if ((tile == Tile.VRAILROAD or (tile >= Tile.ROADBASE and tile <= Tile.VROADPOWER)) and
                       tile != Tile.VROADPOWER and tile != Tile.HRAILROAD and
                       tile != Tile.VBRIDGE)
                        adjTile |= 8

                @_worldEffects.setTile(x, y, RoadTable[adjTile] | Tile.BULLBIT | Tile.BURNBIT)

            else if tile >= Tile.LHRAIL and tile <= Tile.LVRAIL10
                if y > 0
                    tile = TileUtils.normalizeRoad(@_worldEffects.getTile(x, y - 1))
                    if (tile >= Tile.RAILHPOWERV and tile <= Tile.VRAILROAD and
                       tile != Tile.RAILHPOWERV and tile != Tile.HRAILROAD and
                       tile != Tile.HRAIL)
                        adjTile |= 1

                if x < @_map.width - 1
                    tile = TileUtils.normalizeRoad(@_worldEffects.getTile(x + 1, y))
                    if (tile >= Tile.RAILHPOWERV and tile <= Tile.VRAILROAD and
                       tile != Tile.RAILVPOWERH and tile != Tile.VRAILROAD and
                       tile != Tile.VRAIL)
                        adjTile |= 2

                if y < @_map.height - 1
                    tile = TileUtils.normalizeRoad(@_worldEffects.getTile(x, y + 1))
                    if (tile >= Tile.RAILHPOWERV and tile <= Tile.VRAILROAD and
                       tile != Tile.RAILHPOWERV and tile != Tile.HRAILROAD and
                       tile != Tile.HRAIL)
                        adjTile |= 4

                if x > 0
                    tile = TileUtils.normalizeRoad(@_worldEffects.getTile(x - 1, y))
                    if (tile >= Tile.RAILHPOWERV and tile <= Tile.VRAILROAD and
                       tile != Tile.RAILVPOWERH and tile != Tile.VRAILROAD and
                       tile != Tile.VRAIL)
                        adjTile |= 8

                @_worldEffects.setTile(x, y, RailTable[adjTile] | Tile.BULLBIT | Tile.BURNBIT)

            else if tile >= Tile.LHPOWER and tile <= Tile.LVPOWER10
                if y > 0
                    tile = @_worldEffects.getTile(x, y - 1)
                    if tile.isConductive()
                        tile = TileUtils.normalizeRoad(tile.getValue())
                        if tile != Tile.VPOWER and tile != Tile.VROADPOWER and tile != Tile.RAILVPOWERH
                            adjTile |= 1

                else if x < @_map.width - 1
                    tile = @_worldEffects.getTile(x + 1, y)
                    if tile.isConductive()
                        tile = TileUtils.normalizeRoad(tile.getValue())
                        if tile != Tile.HPOWER and tile != Tile.HROADPOWER and tile != Tile.RAILHPOWERV
                            adjTile |= 2

                else if y < this._map.height - 1
                    tile = @_worldEffects.getTile(x, y + 1)
                    if tile.isConductive()
                        tile = TileUtils.normalizeRoad(tile.getValue())
                        if tile != Tile.VPOWER and tile != Tile.VROADPOWER and tile != Tile.RAILVPOWERH
                            adjTile |= 4

                else if x > 0
                    tile = @_worldEffects.getTile(x - 1, y)
                    if tile.isConductive()
                        tile = TileUtils.normalizeRoad(tile.getValue())
                        if tile != Tile.HPOWER and tile != Tile.HROADPOWER and tile != Tile.RAILHPOWERV
                            adjTile |= 8

                @_worldEffects.setTile(x, y, WireTable[adjTile] | Tile.BLBNCNBIT)

        checkZoneConnections: (x, y) ->
            @fixSingle(x, y)
            if y > 0
                @fixSingle(x, y - 1)
            if x < @_map.width - 1
                @fixSingle(x + 1, y)
            if y < this._map.height - 1
                @fixSingle(x, y + 1)
            if x > 0
                @fixSingle(x - 1, y)

        checkBorder: (x, y, size) ->
            #Adjust to top left tile
            x = x - 1
            y = y - 1
            for i in [0...size]
                @fixZone(x + i, y - 1)
            for i in [0...size]
                @fixZone(x - 1, y + i)
            for i in [0...size]
                @fixZone(x + i, y + size)
            for i in [0...size]
                @fixZone(x + size, y + i)
