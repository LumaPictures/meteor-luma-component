# # ServerDataView

# ##### ServerDataView.created()
Template.ServerDataView.created = ->
  Session.set "limit", 10
  Session.set "skip", 0
  sort = []
  sort.push [ 'createdAt', -1 ]
  Session.set "sort", sort
  Session.set "query", {}
  Session.set "filter", { platform: "Linux x86_64"}

# ##### ServerDataView.helpers()
Template.ServerDataView.helpers
  query: -> return Session.get "query"
  filter: -> return Session.get "filter"
  limit: -> return Session.get "limit"
  sort: -> return Session.get "sort"

# ##### ServerDataView.events()
Template.ServerDataView.events
  "click .add-row": _.throttle( insertRow, 1000 )

  "change #subscription-limit": ( event, template ) -> Session.set "limit", parseInt event.val

  "keyup #subscription-filter": _.debounce ( event, template ) ->
    filter =
      userAgent:
        $regex: event.target.value
        $options: 'i'
    console.log "filter", filter
    Session.set "filter", filter
  , 500