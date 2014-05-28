class @ServerDataComponent extends Component
  __name__: "ServerData"
  @extend ComponentMixins.ServerData

  constructor: ( context = {} ) ->
    super
    if Meteor.isClient
      @prepareSubscription()
      @prepareQuery()
      @prepareCollection()
      @prepareCursor()
      @prepareCursorOptions()
      @setSubscriptionHandle()
      @setSubscriptionAutorun ( data ) =>
        console.log data
        Session.set "rows", data
    if Meteor.isServer
      @preparePublishCount()

  rows: -> Session.get "rows"

  tempLog: ( object ) ->
    console.log "tempLog", object


if Meteor.isClient
  Template.ServerData.created = -> new ServerDataComponent @

if Meteor.isServer
  # Reactive Data Source
  # ====================
  RowsComponent = new ServerDataComponent
    subscription: "example"
    collection: Rows
    debug: "added"
    query: ( component ) -> return {}

  RowsComponent.publish()