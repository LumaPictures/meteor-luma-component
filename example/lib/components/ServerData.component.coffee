class @ServerDataComponent extends Component
  __name__: "ServerData"
  @extend ComponentMixins.ServerData

  constructor: ( context = {} ) ->
    super
    @prepareServerData()

  rendered: ->
    if Meteor.isClient
      @subscribe @subscriptionCallback

  subscriptionCallback: ( cursor ) ->
    if Meteor.isClient
      Session.set "rows", cursor.fetch()

  rows: -> Session.get "rows"
  start: -> @subscriptionOptions().skip + 1
  end: -> @subscriptionOptions().skip + @subscriptionOptions().limit
  total: -> 100

  tempLog: ( object ) -> console.log "tempLog", object


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