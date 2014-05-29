# Component Base Class
class Component

  # ## __name__ [ String ]
  # A dance around minification of class names in @constructor.name
  __name__: undefined

  # ## Template Instance
  events: {}

  # ##### constructor( Object or Null )
  constructor: ( context = {} ) ->
    throw new Error "All components must have defined a unique __name__ instance property" if @__name__ is undefined
    @prepareDataContext context
    @prepareDefaultOptions()
    @prepareId context
    # Add getter setter methods for everything in the component data context.
    @addGetterSetter( 'data', attr ) for attr of @data if @data
    @prepareOptions()
    @extendComponent context

  # ##### prepareDataContext( Object )
  prepareDataContext: ( context ) ->
    # If a new component is instantiated on the client the context should be a template instance
    if Meteor.isClient
      templateInstance = context
      # If the template instance has a data context set the component data property to the data context.
      if "data" of templateInstance
        @data = templateInstance.data
    # If a new component is instantiated on the server the context is just the data
    if Meteor.isServer
      @data = context

    # if no data context was set initialize it to an empty object
    @data = {} unless @data

  # ##### prepareDefaultOptions()
  prepareDefaultOptions: ->
    # if defaults are defined set them on the data context
    if @data and @defaults then @data.defaults = @defaults

    # Initialize options to an empty object if they are not defined
    unless @data.options then @data.options = {}

  # ##### prepareId( Object )
  prepareId: ( context ) ->
    if Meteor.isClient
      templateInstance = context
      if templateInstance.__component__
        # Bind events to the template context
        templateInstance.__component__.events = @events
        # Dynamically generate an id if none was provided
        unless @data.id
          @data.id = "#{ @__name__ }-#{ templateInstance.__component__.guid }"
        # Create a unique selector from the id property
        @data.selector = "##{ @data.id }"
      else throw new Error "Component is not yet instantiated."

    if Meteor.isServer
      if @data.subscription
        @data.id = @data.subscription
      else throw new Error "All server side components require a subscription, which is used as the id."

  # ##### prepareOptions()
  prepareOptions: ->
    # If default options are present merge them in with the options property
    if @options and @defaults
      @options _.defaults @options(), @defaults()

  # ##### extendComponent( Object )
  extendComponent: ( context, alreadyExtended = false ) ->
    if Meteor.isClient
      templateInstance = context
      if templateInstance.__component__
        # Extend the templateInstance with the current class context
        self = _.extend templateInstance, @
        self.__component__.rendered = self.rendered
        self.__component__.destroyed = self.destroyed
        # Create a circular reference in the data context to make helpers available in the template
        self.data.self = self
      else throw new Error "Component is not yet instantiated."
    if Meteor.isServer
      # On the server this is just a standard class
      self = @
    unless alreadyExtended
      @log "created", self

  # ##### rendered()
  rendered: ->
    if Meteor.isClient
      @__component__.self = @
      @log "rendered", @
    if Meteor.isServer
      throw new Error "Rendered callback is only available on the client."

  # ##### destroyed()
  destroyed: ->
    if Meteor.isClient
      @log "destroyed", @
    if Meteor.isServer
      throw new Error "Destroyed callback is only available on the client."

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
        console.log "#{ @__name__ }:#{ @id() }:#{ message } ->", object

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
    # extend this with a function accessible by calling @<attr>()
    @[ attr ] = (args...) ->
      # if the accessor is called without and arguments
      if args.length == 0
        # return the data
        @[ propertyAttr ][ attr ]
      # if the accessor is called with arguments
      else if args.length == 1
        # set the data to the first element of args
        @[ propertyAttr ][ attr ] = args[ 0 ]
        @log "#{ propertyAttr }:#{ attr }:set", args[ 0 ]
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
      if key is "events"
        @::events = _.extend @::events, value
      else
        @::[ key ] = value

    obj.included?.apply @
    return @

  # ##### @keywords [ Array ]
  # The little dance around the keywords property is to ensure we have callback support when mixins extend a class.
  @keywords: [ 'extended', 'included' ]

  # ##### collections [ Array ]
  # An array to track the collections initialized by components to prevent duplicate collection errors.
  @collections: []

  # ##### Component.getCollection( String )
  # Checks to see if a colletion already exists and returns the collection
  @getCollection: ( string ) ->
    for id, collection of Component.collections
      if id is string and collection instanceof Meteor.Collection
        return collection
        break
    # if none of the collections match
    return false