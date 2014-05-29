class @ServerDataComponent extends Component
  __name__: "ServerData"
  @extend ComponentMixins.ServerData

  constructor: ( context = {} ) ->
    super
    @prepareServerData context

  rendered: ->
    @subscribe @subscriptionCallback if Meteor.isClient

  subscriptionCallback: ( cursor ) ->
    if Meteor.isClient
      Session.set "rows", cursor.fetch().reverse()

  rows: -> Session.get "rows"

  tempLog: ( object ) -> console.log "tempLog", object

  events:
    "click button.previous": ( event, template ) -> template.paginate "previous", template.subscriptionCallback

    "click button.next": ( event, template ) -> template.paginate "next", template.subscriptionCallback

    "click button.first": ( event, template ) -> template.paginate "first", template.subscriptionCallback

    "click button.last": ( event, template ) -> template.paginate "last", template.subscriptionCallback


if Meteor.isClient
  Template.ServerData.created = -> new ServerDataComponent @

if Meteor.isServer
  # Reactive Data Source
  # ====================
  RowsComponent = new ServerDataComponent
    subscription: "example"
    collection: Rows
    debug: "all"
    query: ( component ) -> return {}

  RowsComponent.publish()