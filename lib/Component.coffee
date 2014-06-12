LumaComponent =
  Collections: {}
  Client: new Meteor.Collection null if Meteor.isClient
  Portlet: new Meteor.Collection "portlet"
  Mixins: {}
  Keywords: [ 'extended', 'included' ]

LumaComponent.Client.instance = {} if Meteor.isClient
LumaComponent.Portlet.instance = {}

# Component Base Class
class LumaComponent.Base
    kind: "LumaComponent"

    portlet: false

    data: {}

    helpers: {}

    persistable: [
      "_id"
      "kind"
      "data"
    ]

    constructor: ( context ) ->
      @setID()
      if Meteor.isClient
        component = context.__component__
        @applyHelper component, "initialize", @initialize
        @applyHelper component, "rendered", @rendered
        @applyHelper component, "destroyed", @destroyed
        @applyHelper component, key, helper for key, helper of @helpers
      if Meteor.isServer
        @error "Only portlets can be instantiated on the server." unless @portlet
        @data = context
      @log "id", @_id
      @collection = @getCollection()
      @persist() if Meteor.isClient

    setID: ->
      @_id ?= "#{ @kind }-#{ new Meteor.Collection.ObjectID() }"

    applyHelper: ( component, key, helper ) ->
      @error "Helpers can only be applied on the client." if Meteor.isServer
      @error "A helper with key : #{ key } already exists on this component." if component[ key ]
      component[ key ] = _.bind helper, @ unless component[ key ]

    getCollection: ->
      if Meteor.isClient
        collection = unless @portlet then LumaComponent.Client else LumaComponent.Portlet
      if Meteor.isServer
        collection = if @portlet then LumaComponent.Portlet else @error "Only portlets can be instantiated on the server."
      return collection

    persist: ( db = true ) ->
      doc = {}
      for key in @persistable
        doc[ key ] = @[ key ] if @[ key ]
      @collection.instance[ @_id ] = @
      @persisted = @collection.upsert _id: doc._id, doc if db
      @log "persisted", doc
      return doc

    update: ( _id = null, doc ) ->
      _id ?= @_id
      @collection.update _id: _id, doc
      @log "updated:#{ _id }", doc

    remove: ( _id = null ) ->
      _id ?= @_id
      @collection.remove _id: _id
      @log "removed:#{ _id }"

    set: ( key, value, doc = {} ) ->
      if key and value
        oldValue = Deps.nonreactive =>
          @get key
        oldValue ?= {}
        doc[ key ] = _.extend oldValue, value
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
      @log "rendered", @

    destroyed: ->
      @log "destroyed", @
      @remove()
      delete @collection.instance[ @_id ]
      delete LumaComponent.Collections[ @_id ] if LumaComponent.Collections[ @_id ]

    initialize: ( @data ) ->
      @data.selector = @_id
      @set "data", @data
      @log "initialized", @
      @persist()

    # ##### log( String, Object )
    log: ( message, object ) ->
      if @data.debug
        if @data.debug is "all" or message.indexOf( @data.debug ) isnt -1
          console.log "#{ @kind }:#{ if @_id then @_id else "constructor" }:#{ message } ->", object

    error: ( message ) ->
      throw new Error "#{ if @_id then @_id else "constructor" } -> #{ message }"

    @extend: ( obj ) ->
      @[ key ] = value for key, value of obj when key not in LumaComponent.Keywords
      obj.extended?.apply @

    # ##### include( Object )
    @include: ( obj ) ->
      for key, value of obj when key not in LumaComponent.Keywords
        switch key
          # Assign properties to the prototype
          when "helpers" then _.defaults @::helpers, value if Meteor.isClient
          when "events" then _.defaults @::events, value if Meteor.isClient
          else @::[ key ] = value
      obj.included?.apply @