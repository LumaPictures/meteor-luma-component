rowCount = 1000

# * Collection defined on server and client
@Rows = new Meteor.Collection 'rows'

# * for the purposes of this example all changes to `Rows` are allowed
Rows.allow
  insert: -> true
  update: -> true
  remove: -> true

@insertRow = ->
  if Meteor.isServer
    navigator =
      platform: "NodeJS"
      language: "en-us"
  if Meteor.isClient
    navigator = _.pick window.navigator, "cookieEnabled", "language", "onLine", "platform", 'userAgent', "systemLanguage"
    console.log "Row Added", navigator
  Rows.insert _.extend navigator, createdAt: new Date()

@insertRows = ( howManyRows ) ->
  insertRow i for i in [ 1..howManyRows ]
  console.log "#{ howManyRows } rows inserted"

if Meteor.isServer
  # * initialize Rows collection
  # * Calling `_ensureIndex` is necessary in order to sort and filter collections.
  #   * [see mongod docs for more info](http://docs.mongodb.org/manual/reference/method/db.collection.ensureIndex/)
  Meteor.startup ->
    Rows._ensureIndex { _id: 1 }, { unique: 1 }
    Rows._ensureIndex 'cookieEnabled': 1
    Rows._ensureIndex 'language': 1
    Rows._ensureIndex 'onLine': 1
    Rows._ensureIndex 'platform': 1
    Rows._ensureIndex 'userAgent': 1
    Rows._ensureIndex 'systemLanguage': 1
    Rows._ensureIndex createdAt: 1
    if Rows.find().count() is 0
      console.log "Initializing #{ rowCount } rows"
      insertRows rowCount