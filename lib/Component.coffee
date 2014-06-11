LumaComponent =
  Collections: {}
  Client: new Meteor.Collection null if Meteor.isClient
  Portlet: new Meteor.Collection "portlet"
  Mixins: {}

LumaComponent.Client.instance = {} if Meteor.isClient
LumaComponent.Portlet.instance = {}

# Component Base Class
class LumaComponent.Base
    kind: "LumaComponent"

    portlet: false

    data: {}

    helpers: {}

    constructor: ( context ) ->
      if Meteor.isClient
        component = context.__component__
        @_id = "#{ @kind }-#{ component.guid }"
        @applyHelper component, "initialize", @initialize
        @applyHelper component, "rendered", @rendered
        @applyHelper component, "destroyed", @destroyed
        @applyHelper component, key, helper for key, helper of @helpers
      if Meteor.isServer
        @_id = "#{ @kind }-#{ Meteor.Collection.ObjectID() }"
        @error "Only portlets can be instantiated on the server." unless @portlet
      @log "id", @_id
      @collection = @getCollection()
      @create()
      @log "created", @

    applyHelper: ( component, key, helper ) ->
      @error "Helpers can only be applied on the client." if Meteor.isServer
      @error "A helper with key : #{ key } already exists on this component." if component[ key ]
      component[ key ] = _.bind helper, @ unless component[ key ]

    getCollection: ->
      if Meteor.isClient
        collection = unless @portlet then LumaComponent.Client else LumaComponent.Portlet
      if Meteor.isServer
        collection = if @portlet LumaComponent.Portlet else @error "Only portlets can be instantiated on the server."
      return collection

    create: ->
      @collection.instance[ @_id ] = @
      @collection.insert
        _id: @_id
        kind: @kind
        data: @data

    set: ( key, value ) ->
      if key and value
        doc = {}
        doc[ key ] = value
        @collection.update { _id: @_id }, { $set: doc }

    getProperty: ( key = null, object ) ->
      return object unless key
      return object[ key ] if object[ key ]
      path = key.split "."
      while path.length
        do ->
          object = object[ path.shift() ]
      return object

    get: ( key = null ) ->
      instance = @collection.findOne _id: @_id
      @error "Context #{ @_id } not found in component collection." unless instance
      return @getProperty key, instance

    rendered: ->
      @log "rendered:context", @

    destroyed: ->
      @log "destroyed:context", @
      @collection.remove _id: @_id
      delete @collection.instance[ @_id ]

    initialize: ( @data ) ->
      @data.selector = @_id
      @debug = @data.debug if @data.debug
      @set "data", @data
      @log "initialize:context", @
      @log "initialize:data", @data

    # ##### log( String, Object )
    log: ( message, object ) ->
      if @debug
        if @debug is "all" or message.indexOf( @debug ) isnt -1
          console.log "#{ @kind }:#{ if @_id then @_id else "constructor" }:#{ message } ->", object

    error: ( message ) ->
      throw new Error "#{ if @_id then @_id else "constructor" } -> #{ message }"

    @extend: ( obj ) ->
      @[ key ] = value for key, value of obj when key not in Component.keywords
      obj.extended?.apply @

    # ##### include( Object )
    @include: ( obj ) ->
      for key, value of obj when key not in Component.keywords
        switch key
          # Assign properties to the prototype
          when "helpers" then _.defaults @::helpers, value if Meteor.isClient
          when "events" then _.defaults @::events, value if Meteor.isClient
          else @::[ key ] = value
      obj.included?.apply @

    # ##### @keywords [ Array ]
    # The little dance around the keywords property is to ensure we have callback support when mixins extend a class.
    @keywords: [ 'extended', 'included' ]