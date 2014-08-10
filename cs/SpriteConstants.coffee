define ['MiscUtils'], (MiscUtils) ->
    SpriteConstants = {}
    Object.defineProperties(SpriteConstants,
        {
            SPRITE_TRAIN: MiscUtils.makeConstantDescriptor(1),
            SPRITE_SHIP: MiscUtils.makeConstantDescriptor(4),
            SPRITE_MONSTER: MiscUtils.makeConstantDescriptor(5),
            SPRITE_HELICOPTER: MiscUtils.makeConstantDescriptor(2),
            SPRITE_AIRPLANE: MiscUtils.makeConstantDescriptor(3),
            SPRITE_TORNADO: MiscUtils.makeConstantDescriptor(6),
            SPRITE_EXPLOSION: MiscUtils.makeConstantDescriptor(7)
        })

  return SpriteConstants
