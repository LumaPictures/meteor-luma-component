# Component Base Class
class Component
    kind: "Component"

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
      @_id = "#{ @kind }-#{ Meteor.Collection.ObjectID() }" if Meteor.isServer
      @log "id", @_id
      @log "created", @
      @create()

    applyHelper: ( component, key, helper ) ->
      @error "Helpers can only be applied on the client." if Meteor.isServer
      @error "A helper with key : #{ key } already exists on this component." if component[ key ]
      component[ key ] = _.bind helper, @ unless component[ key ]

    create: ->
      Collections.Components.store[ @_id ] = @
      Collections.Components.insert
        _id: @_id
        kind: @kind
        data: @data

    set: ( key, value ) ->
      if key and value
        doc = {}
        doc[ key ] = value
        Collections.Components.update { _id: @_id }, { $set: doc }

    getProperty: ( key = null, object ) ->
      return object unless key
      return object[ key ] if object[ key ]
      path = key.split "."
      while path.length
        do ->
          object = object[ path.shift() ]
      return object

    get: ( key = null ) ->
      instance = Collections.Components.findOne _id: @_id
      @error "Context #{ @_id } not found in component collection." unless instance
      return @getProperty key, instance

    rendered: ->
      @log "rendered:context", @

    destroyed: ->
      @log "destroyed:context", @
      Collections.Components.remove _id: @_id
      delete Collections.Components.store[ @_id ]

    initialize: ( @data ) ->
      @data.selector = @_id
      @set "data", @data
      @log "initialize:context", @
      @log "initialize:data", @data

    # ##### log( String, Object )
    log: ( message, object ) ->
      debug = @get "data.debug"
      if debug
        if debug is "all" or message.indexOf( debug ) isnt -1
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