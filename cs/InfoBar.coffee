define ['Text'], (Text) ->

    #TODO L20N
    setClass = (classification) -> $('#cclass').text(classification)

    setDate = (m, year) -> $('#date').text([Text.months[m], year].join(' '))

    setFunds = (funds) -> $('#funds').text(funds)

    setPopulation = (pop) -> $('#population').text(pop)

    setScore = (score) -> $('#score').text(score)

    InforBar =
        setClass: setClass
        setDate: setDate
        setFunds: setFunds
        setPopulation: setPopulation
        setScore: setScore
