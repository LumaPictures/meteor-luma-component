# Component Base Class
class Component
  # ##### constructor()
  constructor: ( context = {} ) ->
    if Meteor.isClient
      if "data" of context
        @data = context.data
    if Meteor.isServer
      @data = context

    # Add getter setter methods for everything in the component data context.
    if @data
      @addGetterSetter( 'data', attr ) for attr of @data

    if Meteor.isClient
      return _.extend context, @
    if Meteor.isServer
      return @

  # ##### addGetterSetter( String, String )
  # Adds Getter Setter methods to all properties of the supplied object
  #   * propertyAttr : the key of the data container object
  #   * attr : the property key currently being added
  # The resulting object should look something like this :
  ###
    ```javascript
      { data:
        { doors: 2,
          color: 'red',
          options: {
            performance: [Object],
            convertible: [Object]
        }
      },
        doors: [Function],
        color: [Function],
        options: [Function]
      }
    ```
  ###
  addGetterSetter: ( propertyAttr, attr ) ->
    # extend this with a function accessible by calling @.<attr>()
    @[ attr ] = (args...) ->
      # if the accessor is called without and arguments
      if args.length == 0
        # return the data
        @[ propertyAttr ][ attr ]
      # if the accessor is called with arguments
      else if args.length == 1
        # set the data to the first element of args
        @[ propertyAttr ][ attr ] = args[ 0 ]
      else throw new Error "Only one argument is allowed to a setter method."

  # ## Mixins

  # Component provides mixin support through two static functions, @extend() and @include()
  # which we can use for extending the class with static and instance properties respectively.

  # ##### Component.extend( Object )
  # Extend can be used to extend a class with static methods directly or extend an entire mixin object  with instance methods.
  # An example mixin object looks like :
  ###
    ```coffeescript
      ORM =
      find: ( id ) -> return id
      create: ( attrs ) -> return attrs
      extended: ->
        @include
          save: ( id ) -> return id
          destroy: ( id ) -> return true
    ```
  ###
  @extend: ( obj ) ->
    for key, value of obj when key not in Component.keywords
      @[ key ] = value

    obj.extended?.apply @
    return @

  # ##### Component.include( Object )
  @include: ( obj ) ->
    for key, value of obj when key not in Component.keywords
      # Assign properties to the prototype
      @::[ key ] = value

    obj.included?.apply @
    return @

  # The little dance around the keywords property is to ensure we have callback support when mixins extend a class.
  @keywords: [ 'extended', 'included' ]