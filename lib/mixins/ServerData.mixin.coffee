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
        @extendComponent context, true


      # ##### prepareSubscription()
      prepareSubscription: ->
        if Meteor.isClient and @getData "subscription"
          @setData "subscription", @getData "subscription"
          @prepareSubscriptionReady()
          @prepareLimit()
          @prepareSkip()
          @prepareSort()
          @prepareCounts()

      # ##### prepareQuery()
      prepareQuery: ->
        if @getData "subscription" or Meteor.isServer
          query = if @getData "query" then @getData "query" else {}
          @setData "query", query

      # ##### prepareFilter()
      prepareQuery: ->
        if @getData "subscription" or Meteor.isServer
          filter = if @getData "filter" then @getData "filter" else {}
          @setData "filter", {} unless @getData "filter"

      # ##### prepareCollection()
      prepareCollection: ->
        if @getData "subscription"
          @countCollectionName = "component_count"
          if Meteor.isClient
            id = @getData "id"
            Component.collections[ @countCollectionName ] ?= new Meteor.Collection @countCollectionName
            Component.collections[ id ] ?= new Meteor.Collection id
            @collection = Component.collections[ id ]
            @log "collection:set", @collection
          if Meteor.isServer
            @error "Collection property is not defined" unless @data.collection
            @collection = @data.collection
            delete @data.collection

    if Meteor.isServer
      @include
        # ##### preparePublicationQueries( Object )
        preparePublicationQueries: ( publication ) ->
          query = @getData "query"
          if _.isFunction query
            queryMethod = _.bind query, publication.context
            query = queryMethod @

          publication.query =
            $and: [
              query
              publication.query
            ]

          publication.filter =
            $and: [
              publication.query
              publication.filter
            ]
          return publication

        # ##### preparePublicationOptions( Object )
        preparePublicationOptions: ( publication ) -> return publication

        # ###### preparePublicationArguments( String, Object, Object, Object, Context )
        preparePublicationArguments: ( collectionName, query, filter, options, context ) ->
          Match.test collectionName, String
          Match.test query, Object
          Match.test filter, Object
          Match.test options, Object
          Match.test context, Object
          publication =
            context: context
            initialized: false
            collectionName: collectionName
            query: query
            filter: filter
            options: options
          @log "#{ @getData "subscription" }:publication:raw", _.omit publication, "context"
          publication = @preparePublicationOptions publication
          publication = @preparePublicationQueries publication
          @log "#{ @getData "subscription" }:publication:prepared", _.omit publication, "context"
          return publication

        # ###### createCountHandle( Object )
        createCountHandle: ( publication ) ->
          component = @
          if publication.options.limit
            # This is an attempt to monitor the last page in the dataset for changes, this is due to datatable on the client
            # breaking when the last page no longer contains any data, or is no longer the last page.
            lastPage = component.collection.find( publication.filter ).count() - publication.options.limit
            if lastPage > 0
              countPublication = _.clone publication
              countPublication.initialized = false
              countPublication.options.skip = lastPage
              countHandle = component.collection.find( countPublication.filter, countPublication.options ).observe
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
          if publication.initialized
            total = component.collection.find( publication.query ).count()
            component.log "#{ component.getData "subscription" }:count:total", total
            filtered = component.collection.find( publication.filter ).count()
            component.log "#{ component.getData "subscription" }:count:filtered", filtered
            # `added` is a flag that is set to true on the initial insert into the DaTableCount collection from this subscription.
            if added
              publication.context.added( component.countCollectionName, publication.collectionName, { count: total } )
              publication.context.added( component.countCollectionName, "#{ publication.collectionName }_filtered", { count: filtered } )
            else
              publication.context.changed( component.countCollectionName, publication.collectionName, { count: total } )
              publication.context.changed( component.countCollectionName, "#{ publication.collectionName }_filtered", { count: filtered } )

        # ###### createObserver( Object )
        # The component observes just the filtered and paginated subset of the Collection. This is for performance reasons as
        # observing large datasets entirely is unrealistic. The observe callbacks use `At` due to the sort and limit options
        # passed the the observer.
        createObserver: ( publication ) ->
          component = @
          return component.collection.find( publication.filter, publication.options ).observe

            # ###### addedAt( Object, Number, Number )
            # Updates the count and sends the new doc to the client.
            addedAt: ( doc, index, before ) ->
              component.updateCount publication
              publication.context.added publication.collectionName, doc._id, doc
              publication.context.added component.collection._name, doc._id, doc
              component.log "#{ component.getData "subscription" }:added", doc._id

            # ###### changedAt( Object, Object, Number )
            # Updates the count and sends the changed properties to the client.
            changedAt: ( newDoc, oldDoc, index ) ->
              component.updateCount publication
              publication.context.changed publication.collectionName, newDoc._id, newDoc
              publication.context.changed component.collection._name, newDoc._id, newDoc
              component.log "#{ component.getData "subscription" }:changed", newDoc._id

            # ###### removedAt( Object, Number )
            # Updates the count and removes the document from the client.
            removedAt: ( doc, index ) ->
              component.updateCount publication
              publication.context.removed publication.collectionName, doc._id
              publication.context.removed component.collection._name, doc._id
              component.log "#{ component.getData "subscription" }:removed", doc._id

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
          subscription = component.getData "subscription"
          Meteor.publish subscription, ( collectionName, query, filter, options ) ->
            context = @
            publication = component.preparePublicationArguments collectionName, query, filter, options, context

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
        prepareSubscriptionReady: -> @setData "subscriptionReady", false

        setSubscriptionReady: -> @setData "subscriptionReady", true

        # ##### prepareLimit()
        prepareLimit: ->
          limit = if @getData "limit" then @getData "limit" else 10
          @setData "limit", limit

        # ##### prepareSkip()
        prepareSkip: ->
          skip = if @getData "skip" then @getData "skip" else 0
          @setData "skip", skip

        # ##### prepareSort()
        prepareSort: ->
          sort = if @getData "sort" then @getData "sort" else []
          @setData "sort", sort

        # ##### stopSubscription()
        stopSubscription: ->
          #Session.set "#{ @getData "id" }-subscriptionReady", false
          if @subscriptionHandle and @subscriptionHandle.stop
            @subscriptionHandle.stop()
            @prepareSubscriptionReady()

        subscriptionOnReady: ( callback ) ->
          self = @
          if _.isFunction callback
            @subscriptionCallback = callback
          return ->
            options =
              limit: self.getData "limit"
              sort: self.getData "sort"
            query =
              $and: [
                self.getData "query"
                self.getData "filter"
              ]
            self.cursor = self.collection.find query, options
            self.subscriptionCallback() if _.isFunction self.subscriptionCallback
            self.setSubscriptionReady()

        # ##### subscribe( Function )
        # Subscribes to the dataset for the current table state and stores the handle for later access.
        subscribe: ( callback = null ) ->
          @stopSubscription()
          options =
            skip: @getData "skip"
            limit: @getData "limit"
            sort: @getData "sort"
          subscription = @getData "subscription"
          id = @getData "id"
          query = @getData "query"
          filter = @getData "filter"
          @log "subscription:data", @getData()
          @log "subscription:name", subscription
          @log "subscription:collectionName", id
          @log "subscription:query", query
          @log "subscription:filter", filter
          @log "subscription:options", options
          self = @
          @subscriptionHandle = Meteor.subscribe subscription, id, query, filter, options,
            onReady: @subscriptionOnReady callback
            onError: @error

        prepareCounts: ->
          @setData "totalCount", 0
          @setData "filteredCount", 0
          @setData "currentPageNumber", 0
          @setData "pageStart", 0
          @setData "pageEnd", 0

        setFilteredCount: ->
          ready = @getData "subscriptionReady"
          @deps.subscriptionReady.depend()
          if ready
            @setData @collectionCount "filtered"

        setTotalCount: ->
          ready = @getData "subscriptionReady"
          @deps.subscriptionReady.depend()
          if ready
            @setData @collectionCount()

        # ##### collectionCount( String )
        collectionCount: ( suffix = null ) ->
          if @countCollectionName and @getData "subscriptionReady"
            id = @getData "id"
            _id = if suffix then "#{ id }_#{ suffix }" else id
            total = Component.collections[ @countCollectionName ].findOne( _id )
            count = if total and total.count then total.count
            return count

        # ##### currentPageNumber()
        setCurrentPageNumber: ->
          skip = @getData "skip"
          limit = @getData "limit"
          ready = @getData "subscriptionReady"
          @deps.subscriptionReady.depend()
          @deps.skip.depend()
          @deps.limit.depend()
          if ready
            currentPageNumber = Math.floor( skip / limit ) + 1
            lastPageNumber = Math.floor( @collectionCount "filtered" / limit ) + 1
            if currentPageNumber > 0 and currentPageNumber <= lastPageNumber
              @setData "currentPageNumber", currentPageNumber
            else @error "The current page #{ currentPageNumber } is outside the pagination range for this data set."

        # ##### nextPage( Function )
        nextPage: ( callback ) ->
          skip = @getData "skip"
          limit = @getData "limit"
          nextPage = skip + limit
          unless nextPage >= @collectionCount "filtered"
            @setData "skip", nextPage
            @log "paginate:next", @currentPageNumber()
            @subscribe callback

        # ##### previousPage( Function )
        previousPage: ( callback ) ->
          skip = @getData "skip"
          limit = @getData "limit"
          previousPage = skip - limit
          unless previousPage < 0
            @setData "skip", previousPage
            @log "paginate:previous", @currentPageNumber()
            @subscribe callback

        # ##### firstPage( Function )
        firstPage: ( callback ) ->
          unless @getData "skip" is 0
            @setData "skip", 0
            @log "paginate:first", @currentPageNumber()
            @subscribe callback

        # ##### lastPage( Function )
        lastPage: ( callback ) ->
          limit = @getData "limit"
          count = @collectionCount "filtered"
          lastPage = count - limit
          unless lastPage is @getData "skip"
            @setData "skip", lastPage
            @log "paginate:last", @currentPageNumber()
            @subscribe callback

        # ##### pageStart()
        setPageStart: ->
          skip = @getData "skip"
          ready = @getData "subscriptionReady"
          @deps.skip.depend()
          @deps.subscriptionReady.depend()
          if ready
            pageStart = skip + 1
            if pageStart > 0 and pageStart <= @pageEnd()
              @setData "firstDoc", pageStart

        # ##### pageEnd()
        setPageEnd: ->
          skip = @getData "skip"
          limit = @getData "limit"
          ready = @getData "subscriptionReady"
          @deps.subscriptionReady.depend()
          @deps.skip.depend()
          @deps.limit.depend()
          if ready
            pageEnd = skip + limit
            if pageEnd < @collectionCount "filtered"
              @setData "pageEnd", pageEnd
            else @setData "pageEnd", @collectionCount "filtered"

        # ##### gotToPage( Number, Function )
        goToPage: ( page, callback ) ->
          if _.isNumber page and _.isFunction callback
            limit = @getData "limit"
            pageStart = ( page * limit ) - limit
            if pageStart >= @collectionCount "filtered"
              @setData "skip", pageStart
              @log "paginate:page", page
              @subscribe callback
            else @error "Page #{ page } is outside the pagination range for this dataset."

        # ##### paginate( String or Number, Function )
        paginate: ( page, callback ) ->
          if _.isFunction callback
            if _.isString page
              switch page
                when "next" then @nextPage callback
                when "previous" then @previousPage callback
                when "first" then @firstPage callback
                when "last" then @lastPage callback
                else @error "The paginate method currently only supports 'next' and 'previous' as pagination directions."
            else if _.isNumber page
              @goToPage page, callback
            else @error "The page argument must be a number or string."