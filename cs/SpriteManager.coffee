define ['AirplaneSprite', 'BoatSprite', 'CopterSprite', 'ExplosionSprite', 'Messages', 'MiscUtils', 'MonsterSprite', 'Random', 'SpriteConstants', 'SpriteUtils', 'Tile', 'TornadoSprite', 'TrainSprite'], \
  (AirplaneSprite, BoatSprite, CopterSprite, ExplosionSprite, Messages, MiscUtils, MonsterSprite, Random, SpriteConstants, SpriteUtils, Tile, TornadoSprite, TrainSprite) ->

    class SpriteManager

        constructor: (map) ->
            @spriteList = []
            @map = map
            @spriteCycle = 0
            @constructors = {}
            @constructors[SpriteConstants.SPRITE_TRAIN] = TrainSprite
            @constructors[SpriteConstants.SPRITE_SHIP] = BoatSprite
            @constructors[SpriteConstants.SPRITE_MONSTER] = MonsterSprite
            @constructors[SpriteConstants.SPRITE_HELICOPTER] = CopterSprite
            @constructors[SpriteConstants.SPRITE_AIRPLANE] = AirplaneSprite
            @constructors[SpriteConstants.SPRITE_TORNADO] = TornadoSprite
            @constructors[SpriteConstants.SPRITE_EXPLOSION] = ExplosionSprite

        getSprite: (type) ->
            filteredList = @spriteList.filter (s) ->
                s.frame != 0 and s.type == type

            if filteredList.length == 0 then return null
            return filteredList[0]

        getSpriteList: -> @spriteList.slice()

        getSpritesInView: (startX, startY, lastX, lastY) ->
            sprites = []
            startX = SpriteUtils.worldToPix(startX)
            startY = SpriteUtils.worldToPix(startY)
            lastX = SpriteUtils.worldToPix(lastX)
            lastY = SpriteUtils.worldToPix(lastY)
            @spriteList.filter (s) ->
                (s.x + s.xOffset >= startX and s.y + s.yOffset >= startY) and
                not (s.x + s.xOffset >= lastX and s.y + s.yOffset >= lastY)

        moveObjects: (simData) ->
            messageManager = simData.messageManager
            disasterManager = simData.disasterManager
            blockMaps = simData.blockMaps

            @spriteCycle += 1

            list = @spriteList.slice()

            for i in [0...list.length]
                sprite = list[i]
                if sprite.frame == 0 then continue
                sprite.move(@spriteCycle, messageManager, disasterManager, blockMaps)

            @pruneDeadSprites()

        makeSprite: (type, x, y) ->
            @spriteList.push(new @constructors[type](@map, this, x, y))

        makeTornado: (messageManager) ->
            sprite = @getSprite(SpriteConstants.SPRITE_TORNADO)
            if sprite != null
                sprite.count = 200
                return

            x = Random.getRandom(SpriteUtils.worldToPix(@map.width) - 800) + 400
            y = Random.getRandom(SpriteUtils.worldToPix(@map.height) - 200) + 100

            @makeSprite(SpriteConstants.SPRITE_TORNADO, x, y)
            messageManager.sendMessage(Messages.TORNADO_SIGHTED,
                        {x: SpriteUtils.pixToWorld(x), y: SpriteUtils.pixToWorld(y)})

        makeExplosion: (x, y) ->
            if @map.testBounds(x, y)
                @makeExplosionAt(SpriteUtils.worldToPix(x), SpriteUtils.worldToPix(y))

        makeExplosionAt: (x, y) ->
            @makeSprite(SpriteConstants.SPRITE_EXPLOSION, x, y)

        generatePlane: (x, y) ->
            if @getSprite(SpriteConstants.SPRITE_AIRPLANE) != null
                return
            @makeSprite(SpriteConstants.SPRITE_AIRPLANE,
                            SpriteUtils.worldToPix(x),
                            SpriteUtils.worldToPix(y))

        generateTrain: (census, x, y) ->
            if census.totalPop > 20 and
               @getSprite(SpriteConstants.SPRITE_TRAIN) == null and
               Random.getRandom(25) == 0
                @makeSprite(SpriteConstants.SPRITE_TRAIN,
                                SpriteUtils.worldToPix(x) + 8,
                                SpriteUtils.worldToPix(y) + 8)

        generateShip: ->
            # XXX This code is borked. The map generator will never
            # place a channel tile on the edges of the map
            if Random.getChance(3)
                for x in [4...(@map.width - 2)]
                    if @map.getTileValue(x, 0) == Tile.CHANNEL
                        makeShipHere(x, 0)
                        return
            if Random.getChance(3)
                for y in [1...(@map.height - 2)]
                    if @map.getTileValue(0, y) == Tile.CHANNEL
                        makeShipHere(0, y)
                        return
            if Random.getChance(3)
                for x in [4...(@map.width - 2)]
                    if @map.getTileValue(x, @map.height - 1) == Tile.CHANNEL
                        makeShipHere(x, @map.height - 1)
                        return
            if Random.getChance(3)
                for y in [1...(@map.height - 2)]
                    if @map.getTileValue(@map.width - 1, y) == Tile.CHANNEL
                        makeShipHere(@map.width - 1, y)
                        return

        getBoatDistance: (x, y) ->
            dist = 99999
            pixelX = SpriteUtils.worldToPix(x) + 8
            pixelY = SpriteUtils.worldToPix(y) + 8

            for i in [0...@spriteList.length]
                if sprite.type == SpriteConstants.SPRITE_SHIP and sprite.frame != 0
                    sprDist = SpriteUtils.absoluteValue(sprite.x - pixelX) +
                                  SpriteUtils.absoluteValue(sprite.y - pixelY)

                    dist = Math.min(dist, sprDist)
            return dist

        makeShipHere: (x, y) ->
            @makeSprite(SpriteConstants.SPRITE_SHIP,
                    SpriteUtils.worldToPix(x),
                    SpriteUtils.worldToPix(y))

        generateCopter: (x, y) ->
            if @getSprite(SpriteConstants.SPRITE_HELICOPTER) != null
                return
            @makeSprite(SpriteConstants.SPRITE_HELICOPTER,
                    SpriteUtils.worldToPix(x),
                    SpriteUtils.worldToPix(y))

        makeMonsterAt: (messageManager, x, y) ->
            @makeSprite(SpriteConstants.SPRITE_MONSTER,
                    SpriteUtils.worldToPix(x),
                    SpriteUtils.worldToPix(y))
            messageManager.sendMessage(Messages.MONSTER_SIGHTED, {x: x, y: y})

        makeMonster: (messageManager) ->
            sprite = @getSprite(SpriteConstants.SPRITE_MONSTER)
            if sprite != null
                sprite.soundCount = 1
                sprite.count = 1000
                sprite.destX = SpriteUtils.worldToPix(@map.pollutionMaxX)
                sprite.destY = SpriteUtils.worldToPix(@map.pollutionMaxY)

            done = 0
            for i in [0...300]
                x = Random.getRandom(@map.width - 20) + 10
                y = Random.getRandom(@map.height - 10) + 5

                tile = @map.getTile(x, y)
                if tile.getValue() == Tile.RIVER
                    @makeMonsterAt(messageManager, x, y)
                    done = 1
                    break
            if done == 0 then @makeMonsterAt(messageManager, 60, 50)

        pruneDeadSprites: (type) ->
            @spriteList = @spriteList.filter( (s) -> s.frame != 0)
