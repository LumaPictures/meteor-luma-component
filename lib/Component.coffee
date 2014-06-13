# Component Namespace
LumaComponent =
  Collections: {}
  Kinds: {}
  Components: new Meteor.Collection null if Meteor.isClient
  Portlets: new Meteor.Collection "portlets"
  Mixins: {}
  Keywords: [ 'extended', 'included' ]

# Component Base Class
class LumaComponent.Base

    kind: "Component"

    initialized: false if Meteor.isClient

    data: {}

    helpers: {}

    observers: {}

    component: true

    collection: false

    debug: false

    constructor: ( context ) ->
      @setID()
      @kind = @kind
      data = @getDataContext context
      @setData data
      @setDebug()
      if Meteor.isClient
        component = @getComponentContext context
        @setCollection()
        @applyHelper component, "initialize", @initialize
        @applyHelper component, "rendered", @rendered
        @applyHelper component, "destroyed", @destroyed
        @bindHelpers()
        @applyHelper component, key, helper for key, helper of @helpers
        @initialized = @initialized
        @save()
        self = @
        @observers.component =
          handle: self.component.find( _id: self._id ).observeChanges
            changed: ( _id, fields ) -> 
              self.update fields, "component"
              self.log "component:changed", fields
      if Meteor.isServer
        @error "Only portlets can be instantiated on the server." unless @portlet
      @log "created", @

    setComponent: ->
      if @component and _.isBoolean @component and Meteor.isClient
        @component = LumaComponent.Components

    setCollection: ->
      if @collection and _.isBoolean @component and Meteor.isClient
        unless LumaComponent.Collections[ @_id ]
          LumaComponent.Collections[ @_id ] ?= new Meteor.Collection @_id
          @collection = LumaComponent.Collections[ @_id ]
          @log "collection", @collection

    getComponentContext: ( context ) -> return context.__component__ if Meteor.isClient

    getDataContext: ( context ) -> if Meteor.isClient then context.data else context

    setID: -> @_id = "#{ @kind }-#{ new Meteor.Collection.ObjectID() }" unless @_id

    setDebug: -> @debug = @data.debug or false

    setSelector: -> @data.selector ?= @_id

    setData: ( data, oldData = null ) ->
      @data ?= {}
      oldData ?= @data
      @data = _.extend oldData, data

    bindHelpers: ->
      @error "Helpers can only be bound on the client." if Meteor.isServer
      for key, helper of @helpers
        @helpers[ key ] = _.bind helper, @

    applyHelper: ( component, key, helper ) ->
      @error "Helpers can only be applied on the client." if Meteor.isServer
      unless _.has component, key
        boundHelper = _.bind helper, @
        component[ key ] = boundHelper
      else @error "A helper with key : #{ key } already exists on this component."

    save: ->
      if Meteor.isClient and @_id
        @setComponent()
        doc = _.omit @, [ 'collection', 'component', 'portlet', 'observers' ]
        doc.component = if @component then true else false
        doc.collection = if @collection then true else false
        doc.portlet = if @portlet then true else false
        saved = @component.upsert _id: @_id, doc
        @log "saved", saved
        @log "saved:doc", doc

    getProperty: ( key = null, object ) ->
      if _.isObject object
        return object unless key
        return object[ key ] if object[ key ]
        path = key.split "."
        while path.length
          do -> object = object[ path.shift() ]
        return object

    get: ( key = null, reactive = true ) ->
      if Meteor.isClient and @_id
        @setComponent()
        if reactive
          instance = @component.findOne _id: @_id
        else instance = Deps.nonreactive => @component.findOne _id: @_id
        @error "Component instance #{ @_id } not found in component collection." unless instance
        return @getProperty key, instance

    destroy: ->
      if Meteor.isClient and @_id
        @setComponent()
        @stop()
        @component.remove _id: @_id
        @initialized = false
        delete LumaComponent.Collections[ @_id ] if LumaComponent.Collections[ @_id ]
        @persist() if persist and @portlet
        @log "destroyed", @

    rendered: -> @log "rendered", @

    destroyed: -> @destroy()

    update: ( data, source = "template" ) ->
      Deps.nonreactive =>
        initialized = @initialized
        @setID()
        _.extend @, @get()
        if source is "template"
          @setData data, @data
        else
          _.extend @, data
        @setDebug()
        @setSelector()
        @initialized = initialized
        @save() unless source is "component"
        if @portlet
          @persist() unless source is "portlet"
        @log "updated", @

    initialize: ( data ) ->
      @initilized = true
      @update data
      return null

    # ##### log( String, Object )
    log: ( message, object ) ->
      if @debug
        if @debug is "all" or message.indexOf( @debug ) isnt -1
          console.log "#{ @kind }:#{ if @_id then @_id else "constructor" }:#{ message } ->", object

    error: ( message ) ->
      throw new Error "#{ if @_id then @_id else "constructor" } -> #{ message }"

    @merge: ( key, object ) -> _.defaults @::[ key ], object if _.has @::, key

    @extend: ( obj ) ->
      @[ key ] = value for key, value of obj when key not in LumaComponent.Keywords
      obj.extended?.apply @

    # ##### include( Object )
    @include: ( obj ) ->
      for key, value of obj when key not in LumaComponent.Keywords
        switch key
          # Assign properties to the prototype
          when "helpers" then @merge "helpers", value if Meteor.isClient
          when "events" then @merge "events", value if Meteor.isClient
          else @::[ key ] = value
      obj.included?.apply @