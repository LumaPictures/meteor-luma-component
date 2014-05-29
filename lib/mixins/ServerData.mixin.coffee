# # ServerData Mixin

# Include this mixin in your class like so :

###
  ```coffeescript
    class Whatever extends Component
      @extend ComponentMixins.ServerData
  ```
###

# Getter setter methods will be created for you instance properties if you add them to the data context in your constructor.

###
  ```coffeescript
    class Whatever extends Component
      @extend ComponentMixins.ServerData
      constructor: ( context = {} ) ->
        @data.instanceProperty = @instanceProperty
        super
  ```
###

ComponentMixins.ServerData =
  extended: ->
    @include
      prepareServerData: ( context = {} ) ->
        @prepareSubscription()
        @prepareQuery()
        @prepareCollection()
        if Meteor.isClient
          @prepareCursor()
        if Meteor.isServer
          @preparePublishCount()
        @extendComponent context, true


      # ##### prepareSubscription()
      prepareSubscription: ->
        if Meteor.isClient and @subscription
          @prepareSubscriptionOptions()

      # ##### prepareQuery()
      prepareQuery: ->
        if @subscription or Meteor.isServer
          unless @query
            @data.query = {}
            @addGetterSetter "data", "query"
          if Meteor.isClient
            @prepareFilterQuery()

      # ##### prepareCollection()
      prepareCollection: ->
        if @subscription
          @data.countCollection = "component_count"
          @addGetterSetter "data", "countCollection"
          if Meteor.isClient
            Component.collections[ @countCollection() ] ?= new Meteor.Collection @countCollection()
            collection = Component.getCollection @id()
            if collection instanceof Meteor.Collection
              @data.collection = collection
              @log "collection:exists", collection
            else
              @data.collection = new Meteor.Collection @id()
              Component.collections[ @id() ] = @data.collection
              @log "collection:created", @data.collection
            @addGetterSetter "data", "collection"
          if Meteor.isServer
            throw new Error "Collection property is not defined" unless @data.collection
            @addGetterSetter "data", "collection"

    if Meteor.isServer
      @include
        # ##### preparePublicationQueries( Object )
        preparePublicationQueries: ( publication ) ->
          if _.isFunction @query()
            queryMethod = _.bind @query(), publication.context
            query = queryMethod @
          else query = @query()

          # The baseQuery is an and of the client and server queries, to prevent the client from accessing the entire collection
          publication.queries.base =
            $and: [
              query
              publication.queries.base
            ]
          publication.queries.filtered =
            $and: [
              query
              publication.queries.filtered
            ]
          return publication

        # ##### preparePublicationOptions( Object )
        preparePublicationOptions: ( publication ) -> return publication

        # ###### publishCount()
        preparePublishCount: ->
          unless @publishCount
            @data.publishCount = true
            @addGetterSetter "data", "publishCount"

        # ###### preparePublicationArguments( String, Object, Object, Context )
        preparePublicationArguments: ( collectionName, queries, options, context ) ->
          Match.test collectionName, String
          Match.test queries, Object
          Match.test options, Object
          Match.test context, Object
          publication =
            context: context
            initialized: false
            collectionName: collectionName
            queries: queries
            options: options
          @log "#{ @subscription() }:publication:raw", _.omit publication, "publicationContext"
          publication = @preparePublicationOptions publication
          publication = @preparePublicationQueries publication
          @log "#{ @subscription() }:publication:prepared", _.omit publication, "publicationContext"
          return publication

        # ###### createCountHandle( Object )
        createCountHandle: ( publication ) ->
          component = @
          if publication.options.limit and component.publishCount()
            # This is an attempt to monitor the last page in the dataset for changes, this is due to datatable on the client
            # breaking when the last page no longer contains any data, or is no longer the last page.
            lastPage = component.collection().find( publication.queries.filtered ).count() - publication.options.limit
            if lastPage > 0
              countPublication = _.clone publication
              countPublication.initialized = false
              countPublication.options.skip = lastPage
              countHandle = component.collection().find( countPublication.queries.filtered, countPublication.options ).observe
                addedAt: -> component.updateCount countPublication
                changedAt: -> component.updateCount countPublication
                removedAt: -> component.updateCount countPublication
              countPublication.initialized = true
              return countHandle

        # ###### updateCount( Object, Boolean )
        # Update the count values of the client component_count Collection to reflect the current filter state.
        updateCount: ( publication, added = false ) ->
          component = @
          # `initialized` is the initialization state of the subscriptions observe handle. Counts are only published after the observes are initialized.
          if publication.initialized and component.publishCount()
            total = component.collection().find( component.query() ).count()
            component.log "#{ component.subscription() }:count:total", total
            filtered = component.collection().find( publication.queries.filtered ).count()
            component.log "#{ component.subscription() }:count:filtered", filtered
            # `added` is a flag that is set to true on the initial insert into the DaTableCount collection from this subscription.
            if added
              publication.context.added( component.countCollection(), publication.collectionName, { count: total } )
              publication.context.added( component.countCollection(), "#{ publication.collectionName }_filtered", { count: filtered } )
            else
              publication.context.changed( component.countCollection(), publication.collectionName, { count: total } )
              publication.context.changed( component.countCollection(), "#{ publication.collectionName }_filtered", { count: filtered } )

        # ###### createObserver( Object )
        # The component observes just the filtered and paginated subset of the Collection. This is for performance reasons as
        # observing large datasets entirely is unrealistic. The observe callbacks use `At` due to the sort and limit options
        # passed the the observer.
        createObserver: ( publication ) ->
          component = @
          return component.collection().find( publication.queries.filtered, publication.options ).observe

            # ###### addedAt( Object, Number, Number )
            # Updates the count and sends the new doc to the client.
            addedAt: ( doc, index, before ) ->
              component.updateCount publication
              publication.context.added publication.collectionName, doc._id, doc
              publication.context.added component.collection()._name, doc._id, doc
              component.log "#{ component.subscription() }:added", doc._id

            # ###### changedAt( Object, Object, Number )
            # Updates the count and sends the changed properties to the client.
            changedAt: ( newDoc, oldDoc, index ) ->
              component.updateCount publication
              publication.context.changed publication.collectionName, newDoc._id, newDoc
              publication.context.changed component.collection()._name, newDoc._id, newDoc
              component.log "#{ component.subscription() }:changed", newDoc._id

            # ###### removedAt( Object, Number )
            # Updates the count and removes the document from the client.
            removedAt: ( doc, index ) ->
              component.updateCount publication
              publication.context.removed publication.collectionName, doc._id
              publication.context.removed component.collection()._name, doc._id
              component.log "#{ component.subscription() }:removed", doc._id

        # ###### publish()
        # A instance method for creating paginated publications.
        publish: ->
          # ###### Meteor.publish
          # The publication this method provides is a paginated and filtered subset of the baseQuery defined during component instantiation on the server.
          # ###### Parameters
          #   + collectionName: ( String ) The client collection these documents are being added to.
          #   + queries: ( Object ) the client queries on the dataset. Usually includes a base and filtered query.
          #   + options : ( Object ) sort and pagination options supplied by the client's current state.
          component = @
          Meteor.publish component.subscription(), ( collectionName, queries, options ) ->
            context = @
            publication = component.preparePublicationArguments collectionName, queries, options, context

            # After the observer is initialized the `initialized` flag is set to true, the initial count is published,
            # and the publication is marked as `ready()`
            handle = component.createObserver publication
            publication.initialized = true
            component.updateCount publication, true
            context.ready()

            countHandle = component.createCountHandle publication

            # When the publication is terminated the observers are stopped to prevent memory leaks.
            context.onStop ->
              handle.stop() if handle and handle.stop
              countHandle.stop() if countHandle and countHandle.stop


    if Meteor.isClient
      @include
        prepareFilterQuery: ->
          unless @filterQuery
            @data.filterQuery = {}
            @addGetterSetter "data", "filterQuery"

        # ##### prepareCursor()
        prepareCursor: ->
          unless @cursor
            @data.cursor = false
            @addGetterSetter "data", "cursor"

        prepareSubscriptionOptions: ->
          unless @subscriptionOptions
            @data.subscriptionOptions =
              limit: 10
              skip: 0
              sort: []
            @addGetterSetter "data", "subscriptionOptions"

        prepareSubscriptionHandle: ->
          Session.set "#{ @id() }-subscriptionReady", false
          if @subscriptionHandle and @subscriptionHandle().stop
            @subscriptionHandle().stop()
          else
            @data.subscriptionHandle = false
            @addGetterSetter "data", "subscriptionHandle"

        prepareSubscriptionAutorun: ->
          if @subscriptionAutorun and @subscriptionAutorun().stop
            @subscriptionAutorun().stop()
          else
            @data.subscriptionAutorun = undefined
            @addGetterSetter "data", "subscriptionAutorun"

        # ##### subscribe()
        # Subscribes to the dataset for the current table state and stores the handle for later access.
        subscribe: _.throttle ( callback = null ) ->
          @prepareSubscriptionHandle()
          queries =
            base: @query()
            filtered: @filterQuery()
          handle = Meteor.subscribe @subscription(), @collection()._name, queries, @subscriptionOptions()
          @subscriptionHandle handle
          @log "subscription:handle", @subscriptionHandle()
          @setSubscriptionCallback callback
        , 500

        isSubscriptionReady: ->
          if @subscriptionHandle and @subscriptionHandle().ready
            Session.set "#{ @id() }-subscriptionReady", @subscriptionHandle().ready()
          else
            Session.set "#{ @id() }-subscriptionReady", false
          @log 'subscription:handle:ready', Session.get "#{ @id() }-subscriptionReady"
          return Session.get "#{ @id() }-subscriptionReady"

        # ##### setSubscriptionAutorun()
        # Creates a reactive computation that runs when the subscription is `ready()` and sets up local cursor.
        setSubscriptionCallback: ( callback ) ->
          if _.isFunction callback
            @prepareSubscriptionAutorun()
            @subscriptionAutorun Deps.autorun =>
              if @isSubscriptionReady()
                @prepareCursor()
                @cursor @collection().find @filterQuery(), _.omit @subscriptionOptions(), "skip"
                callback @cursor()
            @log "subscriptionAutorun", @subscriptionAutorun()
          else throw new Error "Subscription callback must the a function."

        # ##### collectionCount( String )
        collectionCount: ( suffix = null ) ->
          id = if suffix then "#{ @id() }_#{ suffix }" else @id()
          total = Component.collections[ @countCollection() ].findOne( id )
          count = if total and total.count then total.count
          return count

        # ##### currentPageNumber()
        currentPageNumber: ->
          if @isSubscriptionReady()
            currentPageNumber = Math.floor( @subscriptionOptions().skip / @subscriptionOptions().limit ) + 1
            lastPageNumber = Math.floor( @collectionCount "filtered" / @subscriptionOptions().limit ) + 1
            if currentPageNumber > 0 and currentPageNumber <= lastPageNumber
              return currentPageNumber
            else throw new Error "The current page #{ currentPageNumber } is outside the pagination range for this data set."

        # ##### nextPage( Function )
        nextPage: ( callback ) ->
          if @isSubscriptionReady()
            skip = @subscriptionOptions().skip
            nextPage = skip + @subscriptionOptions().limit
            unless nextPage >= @collectionCount "filtered"
              @subscriptionOptions().skip = nextPage
              @log "paginate:next", @currentPageNumber()
              @subscribe callback

        # ##### previousPage( Function )
        previousPage: ( callback ) ->
          if @isSubscriptionReady()
            skip = @subscriptionOptions().skip
            previousPage = skip - @subscriptionOptions().limit
            unless previousPage < 0
              @subscriptionOptions().skip = previousPage
              @log "paginate:previous", @currentPageNumber()
              @subscribe callback

        # ##### firstPage( Function )
        firstPage: ( callback ) ->
          if @isSubscriptionReady()
            unless @subscriptionOptions().skip is 0
              @subscriptionOptions().skip = 0
              @log "paginate:first", @currentPageNumber()
              @subscribe callback

        # ##### lastPage( Function )
        lastPage: ( callback ) ->
          if @isSubscriptionReady()
            count = @collectionCount( "filtered" )
            lastPage = count - @subscriptionOptions().limit
            unless lastPage is @subscriptionOptions().skip
              @subscriptionOptions().skip = lastPage
              @log "paginate:last", @currentPageNumber()
              @subscribe callback

        # ##### pageStart()
        pageStart: ->
          if @isSubscriptionReady()
            nextPage = @subscriptionOptions().skip + 1
            if nextPage > 0 and nextPage <= @pageEnd()
              return nextPage

        # ##### pageEnd()
        pageEnd: ->
          if @isSubscriptionReady()
            end = @subscriptionOptions().skip + @subscriptionOptions().limit
            if end < @collectionCount "filtered"
              return end
            else return @collectionCount "filtered"

        goToPage: ( page, callback ) ->
          if @isSubscriptionReady()
            if _.isNumber page and _.isFunction callback
              limit = @subscriptionOptions().limit
              pageStart = ( page * limit ) - limit
              if pageStart >= @collectionCount "filtered"
                @subscriptionOptions().skip = pageStart
                @log "paginate:page", page
                @subscribe callback
              else throw new Error "Page #{ page } is outside the pagination range for this dataset."

        # ##### paginate( String or Number, Function )
        paginate: ( page, callback ) ->
          if @isSubscriptionReady()
            if _.isFunction callback
              if _.isString page
                switch page
                  when "next" then @nextPage callback
                  when "previous" then @previousPage callback
                  when "first" then @firstPage callback
                  when "last" then @lastPage callback
                  else throw new Error "The paginate method currently only supports 'next' and 'previous' as pagination directions."
              else if _.isNumber page
                @goToPage page, callback
              else throw new Error "The page argument must be a number or string."
