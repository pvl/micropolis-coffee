define ['Evaluate', 'Messages', 'Simulation'], (Evaluation, Messages, Simulation) ->

    # TODO Some kind of rudimentary L20N based on navigator.language?

    # Query tool strings
    densityStrings = ['Low', 'Medium', 'High', 'Very High']
    landValueStrings = ['Slum', 'Lower Class', 'Middle Class', 'High']
    crimeStrings = ['Safe', 'Light', 'Moderate', 'Dangerous']
    pollutionStrings = ['None', 'Moderate', 'Heavy', 'Very Heavy']
    rateStrings = ['Declining', 'Stable', 'Slow Growth', 'Fast Growth']
    zoneTypes = ['Clear', 'Water', 'Trees', 'Rubble', 'Flood', 'Radioactive Waste',
                   'Fire', 'Road', 'Power', 'Rail', 'Residential', 'Commercial',
                   'Industrial', 'Seaport', 'Airport', 'Coal Power', 'Fire Department',
                   'Police Department', 'Stadium', 'Nuclear Power', 'Draw Bridge',
                   'Radar Dish', 'Fountain', 'Industrial', 'Steelers 38  Bears 3',
                   'Draw Bridge', 'Ur 238']

    # Evaluation window
    gameLevel = {}
    gameLevel['' + Simulation.LEVEL_EASY] = 'Easy'
    gameLevel['' + Simulation.LEVEL_MED] = 'Medium'
    gameLevel['' + Simulation.LEVEL_HARD] = 'Hard'

    cityClass = {}
    cityClass[Evaluation.CC_VILLAGE] = 'VILLAGE'
    cityClass[Evaluation.CC_TOWN] = 'TOWN'
    cityClass[Evaluation.CC_CITY] = 'CITY'
    cityClass[Evaluation.CC_CAPITAL] = 'CAPITAL'
    cityClass[Evaluation.CC_METROPOLIS] = 'METROPOLIS'
    cityClass[Evaluation.CC_MEGALOPOLIS] = 'MEGALOPOLIS'

    problems = {}
    problems[Evaluation.CRIME] = 'Crime'
    problems[Evaluation.POLLUTION] = 'Pollution'
    problems[Evaluation.HOUSING] = 'Housing'
    problems[Evaluation.TAXES] = 'Taxes'
    problems[Evaluation.TRAFFIC] = 'Traffic'
    problems[Evaluation.UNEMPLOYMENT] = 'Unemployment'
    problems[Evaluation.FIRE] = 'Fire'

    # months
    months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    # Tool strings
    toolMessages =
        noMoney: 'Insufficient funds to build that',
        needsDoze: 'Area must be bulldozed first'

    # Message strings
    neutralMessages = {}
    neutralMessages[Messages.FIRE_STATION_NEEDS_FUNDING] = 'Fire departments need funding'
    neutralMessages[Messages.NEED_AIRPORT] = 'Commerce requires an Airport'
    neutralMessages[Messages.NEED_FIRE_STATION] = 'Citizens demand a Fire Department'
    neutralMessages[Messages.NEED_ELECTRICITY] = 'Build a Power Plant'
    neutralMessages[Messages.NEED_MORE_INDUSTRIAL] = 'More industrial zones needed'
    neutralMessages[Messages.NEED_MORE_COMMERCIAL] = 'More commercial zones needed'
    neutralMessages[Messages.NEED_MORE_RESIDENTIAL] = 'More residential zones needed'
    neutralMessages[Messages.NEED_MORE_RAILS] = 'Inadequate rail system'
    neutralMessages[Messages.NEED_MORE_ROADS] = 'More roads required'
    neutralMessages[Messages.NEED_POLICE_STATION] = 'Citizens demand a Police Department'
    neutralMessages[Messages.NEED_SEAPORT] = 'Industry requires a Sea Port'
    neutralMessages[Messages.NEED_STADIUM] = 'Residents demand a Stadium'
    neutralMessages[Messages.ROAD_NEEDS_FUNDING] = 'Roads deteriorating, due to lack of funds'
    neutralMessages[Messages.POLICE_NEEDS_FUNDING] = 'Police departments need funding'
    neutralMessages[Messages.WELCOME] = 'Welcome to Micropolis'

    badMessages = {}
    badMessages[Messages.BLACKOUTS_REPORTED] = 'Brownouts, build another Power Plant'
    badMessages[Messages.COPTER_CRASHED] = 'A helicopter crashed '
    badMessages[Messages.EARTHQUAKE] = 'Major earthquake reported !!'
    badMessages[Messages.EXPLOSION_REPORTED] = 'Explosion detected '
    badMessages[Messages.FLOODING_REPORTED] = 'Flooding reported !'
    badMessages[Messages.FIRE_REPORTED] = 'Fire reported '
    badMessages[Messages.HEAVY_TRAFFIC] = 'Heavy Traffic reported'
    badMessages[Messages.HIGH_CRIME] = 'Crime very high'
    badMessages[Messages.HIGH_POLLUTION] = 'Pollution very high'
    badMessages[Messages.MONSTER_SIGHTED] = 'A Monster has been sighted !'
    badMessages[Messages.NO_MONEY] = 'YOUR CITY HAS GONE BROKE'
    badMessages[Messages.NOT_ENOUGH_POWER] = 'Blackouts reported. Check power map'
    badMessages[Messages.NUCLEAR_MELTDOWN] = 'A Nuclear Meltdown has occurred !!'
    badMessages[Messages.PLANE_CRASHED] = 'A plane has crashed '
    badMessages[Messages.SHIP_CRASHED] = 'Shipwreck reported '
    badMessages[Messages.TAX_TOO_HIGH] = 'Citizens upset. The tax rate is too high'
    badMessages[Messages.TORNADO_SIGHTED] = 'Tornado reported !'
    badMessages[Messages.TRAFFIC_JAMS] = 'Frequent traffic jams reported'
    badMessages[Messages.TRAIN_CRASHED] = 'A train crashed '

    goodMessages = {}
    goodMessages[Messages.REACHED_CAPITAL] = 'Population has reached 50,000'
    goodMessages[Messages.REACHED_CITY] = 'Population has reached 10,000'
    goodMessages[Messages.REACHED_MEGALOPOLIS] = 'Population has reached 500,000'
    goodMessages[Messages.REACHED_METROPOLIS] = 'Population has reached 100,000'
    goodMessages[Messages.REACHED_TOWN] = 'Population has reached 2,000'

    ret =
        badMessages: badMessages
        cityClass: cityClass
        crimeStrings: crimeStrings
        densityStrings: densityStrings
        gameLevel: gameLevel
        goodMessages: goodMessages
        landValueStrings: landValueStrings
        months: months
        neutralMessages: neutralMessages
        problems: problems
        pollutionStrings: pollutionStrings
        rateStrings: rateStrings
        toolMessages: toolMessages
        zoneTypes: zoneTypes
