define ['Random', 'Tile'], (Random, Tile) ->

    unwrapTile = (f) ->
        (tile) ->
            if tile instanceof Tile
                tile = tile.getValue()
            f.call(null, tile)

    canBulldoze = unwrapTile (tileValue) ->
        (tileValue >= Tile.FIRSTRIVEDGE  and tileValue <= Tile.LASTRUBBLE) or
        (tileValue >= Tile.POWERBASE + 2 and tileValue <= Tile.POWERBASE + 12) or
        (tileValue >= Tile.TINYEXP       and tileValue <= Tile.LASTTINYEXP + 2)

    isCommercial = unwrapTile (tile) ->
        tile >= Tile.COMBASE and tile < Tile.INDBASE

    isCommercialZone = (tile) ->
        tile.isZone() and isCommercial(tile)

    isDriveable = unwrapTile (tile) ->
        (tile >= Tile.ROADBASE and tile <= Tile.LASTRAIL) or
        tile == Tile.RAILPOWERV or tile == Tile.RAILPOWERH

    isFire = unwrapTile (tile) ->
        tile >= Tile.FIREBASE and tile < Tile.ROADBASE

    isFlood = unwrapTile (tile) ->
        tile >= Tile.FLOOD and tile < Tile.LASTFLOOD

    isIndustrial = unwrapTile (tile) ->
        tile >= Tile.INDBASE and tile < Tile.PORTBASE

    isIndustrialZone = (tile) ->
        tile.isZone() and isIndustrial(tile)

    isManualExplosion = unwrapTile (tile) ->
        tile >= Tile.TINYEXP and tile <= Tile.LASTTINYEXP

    isRail = unwrapTile (tile) ->
        tile >= Tile.RAILBASE and tile < Tile.RESBASE

    isResidential = unwrapTile (tile) ->
        tile >= Tile.RESBASE and tile < Tile.HOSPITALBASE

    isResidentialZone = (tile) ->
        tile.isZone() and isResidential(tile)

    isRoad = unwrapTile (tile) ->
        tile >= Tile.ROADBASE and tile <= Tile.POWERBASE

    normalizeRoad = unwrapTile (tile) ->
        if (tile >= Tile.ROADBASE and tile <= Tile.LASTROAD + 1) then (tile & 15) + 64 else tile

    randomFire = ->
        new Tile(Tile.FIRE + (Random.getRandom16() & 3), Tile.ANIMBIT)

    randomRubble = ->
        new Tile(Tile.RUBBLE + (Random.getRandom16() & 3), Tile.BULLBIT)

    TileUtils =
        canBulldoze: canBulldoze
        isCommercial: isCommercial
        isCommercialZone: isCommercialZone
        isDriveable: isDriveable
        isFire: isFire
        isFlood: isFlood
        isIndustrial: isIndustrial
        isIndustrialZone: isIndustrialZone
        isManualExplosion: isManualExplosion
        isRail: isRail
        isResidential: isResidential
        isResidentialZone: isResidentialZone
        isRoad: isRoad
        normalizeRoad: normalizeRoad
        randomFire: randomFire
        randomRubble: randomRubble
