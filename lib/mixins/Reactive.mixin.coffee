# # Reactive Mixin

# Include this mixin in your class like so :

###
  ```coffeescript
    class Whatever extends Component
      @extend ComponentMixins.Reactive
  ```
###

# Getter setter methods will be created for you instance properties if you add them to the data context in your constructor.

###
  ```coffeescript
    class Whatever extends Component
      @extend ComponentMixins.Reactive
      constructor: ( context = {} ) ->
        @data.instanceProperty = @instanceProperty
        super
  ```
###

ComponentMixins.Reactive =
  extended: ->
    if Meteor.isClient
      @include
        createHelper: ( key, func ) -> @__component__[ key ] = func