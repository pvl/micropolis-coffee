require ['splashScreen', 'SpriteLoader', 'TileSet', 'TileSetURI'], (SplashScreen, SpriteLoader, TileSet, TileSetURI) ->

    i = null
    tileSet = null

    spritesLoaded = (spriteImages) ->
        s = new SplashScreen tileSet, spriteImages

    spriteError = -> alert 'Failed to load sprites'

    loadSprites = ->
        sl = new SpriteLoader
        sl.load spritesLoaded, spriteError

    tileSetError = -> alert 'Failed to load tileset!'

    loadTileSet = ->
        tileSet = new TileSet i, loadSprites, tileSetError

    imgError = -> alert 'Failed to load tile images!'

    i = new Image
    i.onload = loadTileSet
    i.onerror = imgError
    i.src = 'images/tiles.png'
