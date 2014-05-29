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
      Session.set "rows", cursor.fetch().reverse()

  rows: -> Session.get "rows"
  start: -> @subscriptionOptions().skip + 1
  end: -> @subscriptionOptions().skip + @subscriptionOptions().limit
  total: -> 100

  tempLog: ( object ) -> console.log "tempLog", object

  events:
    "click button.previous": ( event, template ) ->
      skip = template.subscriptionOptions().skip
      unless skip is 0
        previousPage = skip - template.subscriptionOptions().limit
        template.subscriptionOptions().skip = previousPage
        template.subscribe template.subscriptionCallback

    "click button.next": ( event, template ) ->
      skip = template.subscriptionOptions().skip
      unless skip is -1
        nextPage = skip + template.subscriptionOptions().limit
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
    debug: "added"
    query: ( component ) -> return {}

  RowsComponent.publish()