define [], ->
    clamp = (value, min, max) ->
        if value < min
            return min
        if value > max
            return max
        return value

    mixOf = (base, mixins...) ->
        class Mixed extends base
            for mixin in mixins by -1 #earlier mixins override later ones
                for name, method of mixin::
                    Mixed::[name] = method
        return Mixed

    MiscUtils =
        clamp: clamp
        mixOf: mixOf
