# # ServerDataView

# ##### ServerDataView.created()
Template.ServerDataView.created = ->
  Session.set "limit", 10
  Session.set "skip", 0
  sort = []
  sort.push [ 'createdAt', -1 ]
  Session.set "sort", sort
  Session.set "query", {}
  Session.set "filterQuery", {}

# ##### ServerDataView.helpers()
Template.ServerDataView.helpers
  query: -> return Session.get "query"
  filterQuery: -> return Session.get "filterQuery"
  limit: -> return Session.get "limit"
  subscriptionOptions: -> return {
    limit: Session.get "limit"
    skip: Session.get "skip"
    sort: Session.get "sort"
  }

# ##### ServerDataView.events()
Template.ServerDataView.events
  "click .add-row": ( event, template ) -> insertRow()

  "change #subscription-limit": ( event, template ) -> Session.set "limit", parseInt event.val

  "keyup #subscription-filter": _.debounce ( event, template ) ->
    filter =
      userAgent:
        $regex: event.target.value
        $options: 'i'
    Session.set "filterQuery", filter
  , 300