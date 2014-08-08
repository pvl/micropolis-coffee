define [], ->
    getChance = (chance) ->
        (getRandom16() & chance) == 0

    getERandom = (max) ->
        r1 = getRandom max
        r2 = getRandom max
        return Math.min r1, r2

    getRandom = (max) ->
        Math.floor Math.random() * (max + 1)

    getRandom16 = ->
        getRandom 65535

    getRandom16Signed = ->
        value = getRandom16()
        if value >= 32768
            value = 32768 - value
        return value

    Random =
        getChance: getChance,
        getERandom: getERandom,
        getRandom: getRandom,
        getRandom16: getRandom16,
        getRandom16Signed: getRandom16Signed

    return Random
