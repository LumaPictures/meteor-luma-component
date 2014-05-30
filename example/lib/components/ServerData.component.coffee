class @ServerDataComponent extends Component
  __name__: "ServerData"
  @extend ComponentMixins.ServerData

  constructor: ( context = {} ) ->
    super
    @prepareServerData context

  rendered: ->
    if Meteor.isClient
      @subscribe @exampleSubscriptionCallback
    super

  exampleSubscriptionCallback: ( cursor ) =>
    if Meteor.isClient
      rows = cursor.fetch().reverse()
      Session.set "rows", rows
      @log "subscription:callback:rows", rows

  rows: -> Session.get "rows"

  events:
    "click button.previous": ( event, template ) -> template.paginate "previous", template.exampleSubscriptionCallback

    "click button.next": ( event, template ) -> template.paginate "next", template.exampleSubscriptionCallback

    "click button.first": ( event, template ) -> template.paginate "first", template.exampleSubscriptionCallback

    "click button.last": ( event, template ) -> template.paginate "last", template.exampleSubscriptionCallback


if Meteor.isClient
  Template.ServerData.created = -> new ServerDataComponent @
  Template.ServerData.log = -> console.log @

if Meteor.isServer
  # Reactive Data Source
  # ====================
  RowsComponent = new ServerDataComponent
    subscription: "example"
    collection: Rows
    debug: "all"
    query: ( component ) -> return {}

  RowsComponent.publish()