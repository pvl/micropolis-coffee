
define ['Game', 'mapGenerator', 'SplashCanvas'], (Game, mapGenerator, SplashCanvas) ->
    class SplashScreen
        constructor: (@tileSet, @spriteSheet) ->
            @map = mapGenerator()
            $('#splashGenerate').click(@regenerateMap)
            $('#splashPlay').click(@playMap)
            $('.awaitGeneration').toggle()
            @splashCanvas = new SplashCanvas(SplashCanvas.DEFAULT_ID, 'splashContainer')
            @splashCanvas.init(@map, tileSet)

        regenerateMap: =>
            @splashCanvas.clearMap()
            @map = mapGenerator()
            @splashCanvas.paint(@map)

        playMap: =>
            difficulty = $('input[name="difficulty"]:checked').val() - 0
            $('#splashGenerate').off('click')
            $('#splashPlay').off('click')
            $('#splashContainer').html('')
            g = new Game(@map, @tileSet, @spriteSheet, difficulty)
