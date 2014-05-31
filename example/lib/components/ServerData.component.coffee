class @ServerDataComponent extends Component
  __name__: "ServerData"
  @extend ComponentMixins.ServerData

  initialize: ( context ) ->
    super
    @prepareServerData context

  rendered: ->
    @subscribe @exampleSubscriptionCallback if Meteor.isClient
    super

  exampleSubscriptionCallback: -> @setData "rows", @cursor if Meteor.isClient

  events:
    "click button.previous": ( event, t ) -> t.__component__.paginate "previous", t.__component__.exampleSubscriptionCallback

    "click button.next": ( event, t ) -> t.__component__.paginate "next", t.__component__.exampleSubscriptionCallback

    "click button.first": ( event, t ) -> t.__component__.paginate "first", t.__component__.exampleSubscriptionCallback

    "click button.last": ( event, t ) -> t.__component__.paginate "last", t.__component__.exampleSubscriptionCallback


new ServerDataComponent Template.ServerData if Meteor.isClient

if Meteor.isClient
  Template.ServerData.tempLog = ( object ) -> console.log "temp", object

if Meteor.isServer
  # Reactive Data Source
  # ====================
  RowsComponent = new ServerDataComponent
    subscription: "example"
    collection: Rows
    debug: "all"
    query: ( component ) -> return {}

  RowsComponent.publish()