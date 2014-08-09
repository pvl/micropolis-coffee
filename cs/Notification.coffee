define [], ->
    badNews = (msg) ->
        elem = $('#notifications')
        elem.removeClass 'neutral'
        elem.removeClass 'good'
        elem.addClass 'bad'
        elem.text msg

    goodNews = (msg) ->
        elem = $('#notifications')
        elem.removeClass 'neutral'
        elem.removeClass 'bad'
        elem.addClass 'good'
        elem.text msg

    news = (msg) ->
        elem = $('#notifications')
        elem.removeClass 'good'
        elem.removeClass 'bad'
        elem.addClass 'neutral'
        elem.text msg

    Notification =
        badNews: badNews,
        goodNews: goodNews,
        news: news
