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
  start: -> @subscriptionOptions().skip + 1
  end: -> @subscriptionOptions().skip + @subscriptionOptions().limit
  total: ->
    total = Component.collections[ @countCollection() ].findOne( @id() )
    return total.count if total.count

  tempLog: ( object ) -> console.log "tempLog", object

  events:
    "click button.previous": ( event, template ) ->
      skip = template.subscriptionOptions().skip
      previousPage = skip - template.subscriptionOptions().limit
      unless previousPage < 0
        template.subscriptionOptions().skip = previousPage
        template.subscribe template.subscriptionCallback

    "click button.next": ( event, template ) ->
      skip = template.subscriptionOptions().skip
      nextPage = skip + template.subscriptionOptions().limit
      unless nextPage > template.total()
        template.subscriptionOptions().skip = nextPage
        template.subscribe template.subscriptionCallback


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