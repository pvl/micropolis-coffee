
define ['Game', 'MapGenerator', 'SplashCanvas'], (Game, MapGenerator, SplashCanvas) ->
    class SplashScreen
        constructor: (@tileSet, @spriteSheet) ->
            @map = MapGenerator()
            $('#splashGenerate').click(@regenerateMap.bind(this));
            $('#splashPlay').click(@playMap.bind(this));
            $('.awaitGeneration').toggle();
            @splashCanvas = new SplashCanvas SplashCanvas.DEFAULT_ID, 'splashContainer'
            @splashCanvas.init @map, tileSet

        regenerateMap: ->
            @splashCanvas.clearMap()
            @map = MapGenerator()
            @splashCanvas.paint(@map)

        playMap: ->
            difficulty = $('input[name="difficulty"]:checked').val() - 0;
            $('#splashGenerate').off('click');
            $('#splashPlay').off('click');
            $('#splashContainer').html('');
            g = new Game @map, @tileSet, @spriteSheet, difficulty
