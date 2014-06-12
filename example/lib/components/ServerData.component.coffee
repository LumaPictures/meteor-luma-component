class @ServerDataComponent extends LumaComponent.Base
  kind: "ServerData"
  @extend LumaComponent.Mixins.Portlet

  helpers:
    rows: -> @get "cursor"

  constructor: ( context ) ->
    @initializeServerData context
    super

  initialize: ( @data ) ->
    @subscribe @exampleSubscriptionCallback if Meteor.isClient
    super

  exampleSubscriptionCallback: -> @log "exampleCallback", @

  events:
    "click button.previous": ( event, template ) -> template.paginate "previous", template.exampleSubscriptionCallback

    "click button.next": ( event, template ) -> template.paginate "next", template.exampleSubscriptionCallback

    "click button.first": ( event, template ) -> template.paginate "first", template.exampleSubscriptionCallback

    "click button.last": ( event, template ) -> template.paginate "last", template.exampleSubscriptionCallback


if Meteor.isClient
  Template.ServerData.created = -> new ServerDataComponent @

if Meteor.isServer
  # Reactive Data Source
  # ====================
  RowsComponent = new ServerDataComponent
    subscription: "example"
    collection: Rows
    debug: "all"
    query: ( portlet ) -> return {}

  RowsComponent.publish()