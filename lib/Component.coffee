LumaComponent =
  Collections: {}
  Components: new Meteor.Collection null if Meteor.isClient
  Portlets: new Meteor.Collection "portlets"
  Mixins: {}
  Keywords: [ 'extended', 'included' ]

# Component Base Class
class LumaComponent.Base
    kind: "LumaComponent"

    initialized: false

    portlet: false

    data: {}

    helpers: {}

    component: LumaComponent.Components if Meteor.isClient

    persistable:
      _id: true
      kind: true
      data: true
      initialized: true

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
      @persist() if Meteor.isClient

    setID: ->
      unless @_id
        @_id = "#{ @kind }-#{ new Meteor.Collection.ObjectID() }"
        @save()

    applyHelper: ( component, key, helper ) ->
      @error "Helpers can only be applied on the client." if Meteor.isServer
      @error "A helper with key : #{ key } already exists on this component." if component[ key ]
      component[ key ] = _.bind helper, @ unless component[ key ]

    save: ( reactive = true ) ->
      if Meteor.isClient
        if reactive
          saved = @component.upsert _id: @_id, @
        else saved = Deps.nonreactive => @component.upsert _id: @_id, @
        @log "saved", saved

    persist: ( simulation = false ) ->
      doc = {}
      for key, value of @persistable
        doc[ key ] = @[ key ] if @[ key ] and value
      @save()
      persisted = @portlet.upsert _id: doc._id, doc unless simulation
      @log "persisted", persisted
      return doc

    getProperty: ( key = null, object ) ->
      return object unless key
      return object[ key ] if object[ key ]
      path = key.split "."
      while path.length
        do -> object = object[ path.shift() ]
      return object

    get: ( key = null, reactive = true ) ->
      if Meteor.isClient
        if reactive
          instance = @component.findOne _id: @_id
        else instance = Deps.nonreactive => @component.findOne _id: @_id
        @error "Component instance #{ @_id } not found in component collection." unless instance
        return @getProperty key, instance

    fetch: ( key = null, reactive = true ) ->
      if @persist
        if reactive
          instance = @portlet.findOne _id: @_id
        else instance = Deps.nonreactive => @portlet.findOne _id: @_id
        @error "Portlet Instance #{ @_id } not found in portlet collection." unless instance
        return @getProperty key, instance

    destroy: ( persist = true ) ->
      @component.remove _id: @_id
      @initialized = false
      delete LumaComponent.Collections[ @_id ] if LumaComponent.Collections[ @_id ]
      @persist() if persist
      @log "destroyed", @

    delete: ->
      deleted = @persist.remove _id: @_id if @persist
      @log "deleted", deleted

    rendered: -> @log "rendered", @

    destroyed: -> @destroy()

    initialize: ( @data ) ->
      @data.selector ?= @_id
      @initialized ?= true
      @log "initialized", @
      @save()

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