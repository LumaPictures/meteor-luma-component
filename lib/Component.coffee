# Component Base Class
class Component

  # ## __name__ [ String ]
  # A dance around minification of class names in @constructor.name
  __name__: undefined

  events: {}

  deps: {}

  # ##### constructor( Object or Null )
  constructor: ( context = {} ) ->
    @error "All components must have defined a unique __name__ instance property" if @__name__ is undefined
    if Meteor.isClient
      @extendComponent context
    if Meteor.isServer
      @initialize context

  initialize: ( context ) ->
    @createDataAccessors context
    @setId context
    @prepareOptions context
    @setData "self", _.omit @, "templateInstance"
    @log "initialized", @

  # ##### createDataAccessors( Object )
  createDataAccessors: ( context ) ->
    # If a new component is instantiated on the server the context is just the data
    @data = context if Meteor.isServer
    ###  # Add getter setter methods for everything in the templateInstance data context.
      @addGetterSetter attr for attr of @data if @data
    if Meteor.isClient
      templateInstance = context
      # Add getter setter methods for everything in the templateInstance data context.
      @addGetterSetter attr for attr of templateInstance.data if templateInstance.data#########

  # ##### setId( Object )
  setId: ( context ) ->
    if Meteor.isClient
      templateInstance = context
      if templateInstance.__component__
        # Dynamically generate an id if none was provided
        unless @getData "id"
          id = "#{ @__name__ }-#{ templateInstance.__component__.guid }"
          @setData "id", id
        # Create a unique selector from the id property
        @setData "selector", "##{ id }"
      else @error "Component is not yet instantiated."

    if Meteor.isServer
      subscription = @getData "subscription"
      if _.isString subscription
        @setData "id", subscription
      else @error "All server side components require a subscription, which is used as the id."

  # ##### prepareOptions( Object )
  prepareOptions: ( context ) ->
    # If default options are present merge them in with the options property
    options = @getData "options"
    if options and @defaults
      options _.defaults options, @defaults
      @setData "options", options

  # ##### extendComponent( Object )
  extendComponent: ( component ) ->
    if Meteor.isClient
      if component
        # Extend the component with the current class context
        _.extend component, @
      else @error "Component is not yet instantiated."

  created: ->
    if Meteor.isClient
      @__component__.initialize @ if Meteor.isClient
      @__component__.log "created", @
    @__component__.error "Rendered callback is only available on the client." if Meteor.isServer

  # ##### rendered()
  rendered: ->
    if Meteor.isClient
      @__component__.log "rendered", @
    @__component__.error "Rendered callback is only available on the client." if Meteor.isServer

  # ##### destroyed()
  destroyed: ->
    if Meteor.isClient
      @__component__.log "destroyed", @
    @__component__.error "Destroyed callback is only available on the client." if Meteor.isServer

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
    debug = @getData "debug"
    if debug then return debug else return false

  # ##### log( String, Object )
  log: ( message, object ) ->
    if @isDebug()
      if @isDebug() is "all" or message.indexOf( @isDebug() ) isnt -1
        id = @getData "id"
        console.log "#{ @__name__ }:#{ if id then id else "constructor" }:#{ message } ->", object

  error: ( message ) ->
    id = @getData "id"
    throw new Error "#{ if id then id else "constructor" } -> #{ message }"

  # ##### setData( String, Object )
  setData: ( key, value ) ->
    # set the data to the first element of args
    if Meteor.isServer
      @data[ key ] = value
      @log "data:#{ key }:set", value
    if Meteor.isClient and @templateInstance and @templateInstance.data
      @templateInstance.data[ key ] = value
      unless @deps[ key ]
        @deps[ key ] = new Deps.Dependency
      else @deps[ key ].changed()
      @log "templateInstance:data:#{ key }:set", value
    #@addGetterSetter key unless _.isFunction @[ key ]

  # ##### getData( String )
  getData: ( key = null ) ->
    if Meteor.isServer
      return @data[ key ] if @data[ key ]
    if Meteor.isClient
      if @templateInstance and @templateInstance.data
        if key is null then return @templateInstance.data
        if @templateInstance.data[ key ] then return @templateInstance.data[ key ]
      else if @[ key ]
        return @[ key ]
      else return undefined

  # ##### addGetterSetter( String )
  ###addGetterSetter: ( attr ) ->
    # extend this with a function accessible by calling @<attr>()
    @error "Property #{ attr } already defined, accessor method not created." if @[ attr ]
    @[ attr ] = (args...) =>
      # if the accessor is called without and arguments
      if args.length == 0
        # return the data
        @getData attr
      # if the accessor is called with arguments
      else if args.length < 3
        @setData attr, args[ 0 ]
      else @error "Only two arguments ( value, optional template hash ) are allowed to a setter method."###

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