# # ServerDataView

# ##### ServerDataView.created()
Template.ServerDataView.created = -> return

# ##### ServerDataView.rendered()
Template.ServerDataView.rendered = -> return

# ##### ServerDataView.destroyed()
Template.ServerDataView.destroyed = -> return

# ##### ServerDataView.helpers()
Template.ServerDataView.helpers
  query: -> return {}
  filterQuery: -> return {}
  subscriptionOptions: -> return {
    limit: 20
    skip: 0
  }

# ##### ServerDataView.events()
Template .ServerDataView.events {}