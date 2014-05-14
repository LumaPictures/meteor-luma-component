# Component Base Class
class Component

  # ## Template Instance

  # ##### constructor( Object or Null )
  constructor: ( context = {} ) ->
    if Meteor.isClient
      templateInstance = context
      if "data" of templateInstance
        @data = templateInstance.data
    if Meteor.isServer
      @data = context

    @data = {} unless @data

    if @data and @defaults then @data.defaults = @defaults

    if Meteor.isClient and templateInstance.__component__
      uniqueId = context.__component__.guid
      if @data.id then @data.selector = @data.id else @data.selector = "#{ @constructor.name }-#{ uniqueId }"

    # Add getter setter methods for everything in the component data context.
    @addGetterSetter( 'data', attr ) for attr of @data if @data

    if @options and @defaults
      @options _.defaults @options(), @defaults()

    if Meteor.isClient
      component = _.extend templateInstance, @
      component.data.self = component
    if Meteor.isServer
      component = @

    @log "created", component

  # ##### rendered()
  rendered: -> @log "rendered", @

  # ##### destroyed()
  destroyed: -> @log "destroyed", @

  # ## Logging

  # A handy option for granular debug logs.
  # Set debug to any string to only log messages that contain that string.
  #   + `all` logs all messages
  # ##### client examples
  #   + `created` logs the initial component state
  #   + `rendered` logs the instantiated component on render
  #   + `destroyed` logs when the component is detroyed
  #   + `options` logs the options for that instantiated component
  # ##### server examples
  #   + `"query"` : will log the base and filtered queries for every subscription.
  #   + `"added"` : will log all documents added to subscriptions.
  #   + `"changed"` : will log all documents changed for a subscription.
  #   + `"removed"` : will log all documents removed from a collection.

  # ##### isDebug()
  isDebug: ->
    if @debug
      return @debug()
    else return false

  # ##### log( String, Object )
  log: ( message, object ) ->
    if @isDebug()
      if @isDebug() is "all" or message.indexOf( @isDebug() ) isnt -1
        console.log "#{ @constructor.name }:#{ @selector() }:#{ message } ->", object

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

  # ##### extend( Object )
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

  # ##### include( Object )
  @include: ( obj ) ->
    for key, value of obj when key not in Component.keywords
      # Assign properties to the prototype
      @::[ key ] = value

    obj.included?.apply @
    return @

  # ##### @keywords [ Array ]
  # The little dance around the keywords property is to ensure we have callback support when mixins extend a class.
  @keywords: [ 'extended', 'included' ]