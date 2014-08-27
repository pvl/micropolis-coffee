define [], ->

    dataKeys = ['roadFund', 'fireFund', 'policeFund']
    spendKeys = ['roadRate', 'fireRate', 'policeRate']
    budgetResetID = 'budgetReset'
    budgetCancelID = 'budgetCancel'
    budgetOKID = 'budgetOK'
    budgetFormID = 'budgetForm'

    setSpendRangeText = (element, percentage, totalSpend) ->
        labelID = element + 'Label'
        cash = Math.floor(totalSpend * (percentage / 100))
        text = [percentage, '% of $', totalSpend, ' = $', cash].join('')
        $('#' + labelID).text(text)

    onFundingUpdate = (elementID, e) ->
        element = $('#' + elementID)[0]
        percentage = element.value - 0
        dataSource = element.getAttribute('data-source')
        setSpendRangeText(elementID, percentage, this[dataSource])

    onTaxUpdate = (e) ->
        elem = $('#taxRateLabel')[0]
        sourceElem = $('#taxRate')[0]
        $(elem).text(['Tax rate: ', sourceElem.value, '%'].join(''))


    class BudgetWindow
        constructor: (opacityLayerID, budgetWindowID) ->
            @_opacityLayer =  '#' + opacityLayerID
            @_budgetWindowID = '#' + budgetWindowID


        submit: (e) =>
            e.preventDefault()
            # Get element values
            roadPercent = $('#roadRate')[0].value
            firePercent = $('#fireRate')[0].value
            policePercent = $('#policeRate')[0].value
            taxPercent = $('#taxRate')[0].value

            @_callback(false,
                { roadPercent: roadPercent, firePercent: firePercent, policePercent: policePercent, taxPercent: taxPercent } )

            toRemove = [budgetResetID, budgetCancelID, 'taxRate',
                        'roadRate', 'fireRate', 'policeRate']

            for i in [0...toRemove.length]
                $('#' + toRemove[i]).off()

            @_toggleDisplay()


        cancel: (e) =>
            e.preventDefault()
            @_callback(true, null)

            toRemove = [budgetResetID, budgetOKID, 'taxRate',
                        'roadRate', 'fireRate', 'policeRate']

            for i in [0...toRemove.length]
                $('#' + toRemove[i]).off()

            @_toggleDisplay()


        resetItems: (e) =>
            for i in [0...spendKeys.length]
                original = @['original' + spendKeys[i]]
                $('#' + spendKeys[i])[0].value = original
                setSpendRangeText(spendKeys[i], original, @[dataKeys[i]])

            $('#taxRate')[0].value = @originaltaxRate
            onTaxUpdate()
            e.preventDefault()


        _toggleDisplay: ->
            opacityLayer = $(@_opacityLayer)
            opacityLayer = opacityLayer.length == 0 ? null : opacityLayer
            if opacityLayer == null
                throw new Error('Node ' + orig + ' not found')

            budgetWindow = $(@_budgetWindowID)
            budgetWindow = budgetWindow.length == 0 ? null : budgetWindow
            if budgetWindow == null
                throw new Error('Node ' + orig + ' not found')

            opacityLayer.toggle()
            budgetWindow.toggle()


        _registerButtonListeners: ->
            $('#' + budgetResetID).on('click', @resetItems)
            $('#' + budgetCancelID).one('click', @cancel)
            $('#' + budgetFormID).one('submit', @submit)


        open: (callback, budgetData) ->
            @_callback = callback

            # Store max funding levels
            for i in [0...dataKeys.length]
                if budgetData[dataKeys[i]] == undefined
                    throw new Error('Missing budget data')
                this[dataKeys[i]] = budgetData[dataKeys[i]]

            #Update form elements with percentages, and set up listeners
            for i in [0...spendKeys.length]
                if budgetData[spendKeys[i]] == undefined
                    throw new Error('Missing budget data')

                elem = spendKeys[i]
                this['original' + elem] = budgetData[elem]
                setSpendRangeText(elem, budgetData[spendKeys[i]], this[dataKeys[i]])
                elem = $('#' + elem)
                elem.on('input', onFundingUpdate.bind(this, spendKeys[i]))
                elem = elem[0]
                elem.value = budgetData[spendKeys[i]]

            if budgetData.taxRate == undefined
                throw new Error('Missing budget data')

            @originalTaxRate = budgetData.taxRate
            elem = $('#taxRate')
            elem.on('input', onTaxUpdate)
            elem = elem[0]
            elem.value = budgetData.taxRate
            onTaxUpdate()

            # Update static parts
            previousFunds = budgetData.totalFunds
            if previousFunds == undefined
                throw new Error('Missing budget data')

            taxesCollected = budgetData.taxesCollected
            if taxesCollected == undefined
                throw new Error('Missing budget data')

            cashFlow = taxesCollected - @roadFund - @fireFund - @policeFund
            currentFunds = previousFunds + cashFlow
            $('#taxesCollected').text('$' + taxesCollected)
            $('#cashFlow').text((cashFlow < 0 ? '-$' : '$') + cashFlow)
            $('#previousFunds').text((previousFunds < 0 ? '-$' : '$') + previousFunds)
            $('#currentFunds').text('$' + currentFunds)

            @_registerButtonListeners()
            @_toggleDisplay()
