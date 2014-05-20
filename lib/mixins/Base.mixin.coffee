# # Base Component Mixin

# Component Mixins follow a pattern outlined in the [ Little Book on Coffeescript ](http://arcturo.github.io/library/coffeescript/03_classes.html)

###
  ```coffeescript
    ComponentMixins.SomeMixin =
      extended: ->
        classProperty: "Yo Dawg"

        classMethod: ( someArg ) ->
          if _.isString someArg then return "#{ someArg }...."

        @include
          instanceProperty: "Hey..."

          instanceMethod: ( someArg ) ->
            if someArg
              return @instanceProperty

          events:
            "click": ( event, template ) ->
              template.instanceMethod event.val
  ```
###

# Mixins are included in your component by using the @extend method

###
  ```coffeescript
    class @ExampleComponent extends Component
      @extend ComponentMixins.SomeMixin
  ```
###

ComponentMixins = {}