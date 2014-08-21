define [], ->

    class MessageManager
        constructor: ->
            this.data = []

        sendMessage: (message, data) ->
            this.data.push({message: message, data: data})

        clear: () ->
            this.data = []

        getMessages: () ->
            this.data.slice()


