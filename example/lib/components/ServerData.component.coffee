class LumaComponent.Kinds.ExamplePortlet extends LumaComponent.Base

  kind: "ExamplePortlet"

  helpers:
    rows: ->
      @get "cursor"

  @extend LumaComponent.Mixins.Portlet

  constructor: ( context ) ->
    component = @getComponentContext context
    @initializePortlet context
    super

  rendered: -> 
    @subscribe @exampleSubscriptionCallback if Meteor.isClient
    super

  exampleSubscriptionCallback: -> @log "exampleCallback", @

  events:
    "click button.previous": ( event, template ) -> template.paginate "previous", template.exampleSubscriptionCallback

    "click button.next": ( event, template ) -> template.paginate "next", template.exampleSubscriptionCallback

    "click button.first": ( event, template ) -> template.paginate "first", template.exampleSubscriptionCallback

    "click button.last": ( event, template ) -> template.paginate "last", template.exampleSubscriptionCallback


if Meteor.isClient
  Template.ServerData.created = -> new LumaComponent.Kinds.ExamplePortlet @

if Meteor.isServer

  Meteor.publish "example", ( _id ) ->

    portlet = new LumaComponent.Kinds.ExamplePortlet
      subscription: "example"
      collection: Rows
      debug: "all"
      query: ( portlet ) -> return {}
      _id: _id
    
    portlet.publish()
    
    @onStop ->
      portlet.stop()