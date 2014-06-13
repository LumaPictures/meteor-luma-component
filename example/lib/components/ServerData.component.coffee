class LumaComponent.Kinds.ExamplePortlet extends LumaComponent.Base

  kind: "ExamplePortlet"

  helpers:
    rows: -> @get "cursor"

  @extend LumaComponent.Mixins.Portlet

  constructor: ( context ) ->
    @initializePortlet context
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
    subscription = @

    handle = LumaComponent.Portlets.find( _id: _id ).observeChanges
      added: ( _id, doc ) ->
        console.log "added:#{ _id }", doc
        portlet = new LumaComponent.Kinds.ExamplePortlet
          subscription: 
            name: doc.data.subscription
            handle: subscription
          collection: Rows
          debug: doc.data.debug
          query: ( portlet ) -> return {}
          _id: _id
        portlet.publish()
        subscription.onStop ->
          portlet.stop()
          console.log "portlet:stopped" 

      changed: ( _id, fields ) ->
        console.log "changed:#{ _id }", fields

      removed: ( _id ) ->
        console.log "removed", _id
    
    subscription.onStop ->
      console.log "handle:stop" 
      handle.stop()