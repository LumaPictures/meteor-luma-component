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

LumaComponent.Mixins.Portlet =

  extended: ->

    @include

      portlet: true

      persist: false

      collection: true if Meteor.isClient

      observers: {} if Meteor.isServer

      portletDefaults:
        limit: 10
        skip: 0
        sort: []
        count:
          total: 0
          filtered: 0
        query: {}
        filter: {}

      persistable:
        _id: true
        kind: true
        data: true
        initialized: true
        debug: true

      initializePortlet: ( context = {} ) ->
        Match.test context, Object
        @kind = "Portlet" if @kind is "Component"
        @setData( @getDataContext context )
        @setSubscription()
        @setPortletDefaults()
        if Meteor.isServer
          @sync()
          @setObservers()
          @setQuery()
          @setFilter()

      setSubscription: ->
        @persistable.subscription = true
        @subscription =
          name: @data.subscription
          ready: false

      setPortletDefaults: ->
        if @subscription.name
          _.defaults @data, @portletDefaults
        else @error "All portlets must have a subscription defined."
        if Meteor.isServer
          @error "All portlet data contexts must have an _id." unless @data._id
          @_id = @data._id
          @error "All portlet data contexts must have a collection." unless @data.collection
          @collection = @data.collection
          @debug = @data.debug
          @query = @data.query
          @filter = @data.filter

      persist: ( simultaion = false ) ->
        if @portlet and @_id
          @setPortlet()
          doc = {}
          for key, value of @persistable
            doc[ key ] = @[ key ] if _.has( @, key ) and value
          persisted = @portlet.upsert _id: doc._id, doc unless simultaion
          @log "persisted", persisted unless simultaion
          @log "persisted:doc", doc
          if Meteor.isServer
            @publication.changed @portlet._name, @_id, doc
          return doc

      obliterate: ->
        if @portlet and @_id
          @setPortlet()
          obliterated = @portlet.remove _id: @_id if @portlet
          @log "obliterated", obliterated

      sync: ->
        instance = @portlet.findOne _id: @_id
        @error "Portlet Instance #{ @_id } not found in portlet collection." unless instance
        _.extend @, instance
        @log "synced", instance

    if Meteor.isServer
      @include
        setObservers: ->
          @observers.main =
            initialized: false
            options:
              limit: @data.limit
              skip: @data.skip
              sort: @data.sort
            handle: null
          @observers.count =
            initialized: false
            options: @observers.main.options
            handle: null
          @log "#{ @subscription.name }:observers", @observers

        setQuery: ->
          if _.isFunction @query
            queryMethod = _.bind @query, @
            query = queryMethod @
          else query = @query
          @query =
            $and: [
              query
              @data.query
            ]
          @log "#{ @subscription.name }:query", query

        setFilter: ->
          @filter =
            $and: [
              @query
              @data.filter
            ] 
          @log "#{ @subscription.name }:filter", @filter

        # ###### updateCount( Object )
        # Update the count values of the client component_count Collection to reflect the current filter state.
        updateCount: ->
          # `initialized` is the initialization state of the subscriptions observe handle. Counts are only published after the observes are initialized.
          if @observers.main.initialized and @observers.count.initialized
            @data.count.total = @collection.find( @query ).count()
            @data.count.filtered = @collection.find( @filter ).count()
            @persist()
            @log "#{ @subscription.name }:#{ portlet._id }:count", @data.count

        startCountObserver: ->
          if @observers.main.options.limit
            # This is an attempt to monitor the last page in the dataset for changes, this is due to datatable on the client
            # breaking when the last page no longer contains any data, or is no longer the last page.
            @observers.count.options.skip = @collection.find( @filter ).count() - @observers.main.options.limit           
            if lastPage > 0
              self = @
              @observers.count.handle = @collection.find( @filter, @observers.count.options ).observe
                addedAt: -> self.updateCount()
                changedAt: -> self.updateCount()
                removedAt: -> self.updateCount()
              @observers.count.initialized = true

        startMainObserver: ( portlet ) ->
          self = @
          component = @_id
          @observers.main.handle = @collection.find( portlet.server.filter, portlet.server.options ).observe
            # ###### addedAt( Object, Number, Number )
            # Updates the count and sends the new doc to the client.
            addedAt: ( doc, index, before ) ->
              self.updateCount()
              self.publication.added component, doc._id, doc
              self.publication.added self.collection, doc._id, doc
              self.log "#{ self.subscription.name }:added", doc._id
            # ###### changedAt( Object, Object, Number )
            # Updates the count and sends the changed properties to the client.
            changedAt: ( newDoc, oldDoc, index ) ->
              self.updateCount()
              self.publication.changed component, newDoc._id, newDoc
              self.publication.changed self.collection, newDoc._id, newDoc
              self.log "#{ self.subscription }:changed", newDoc._id
            # ###### removedAt( Object, Number )
            # Updates the count and removes the document from the client.
            removedAt: ( doc, index ) ->
              self.updateCount()
              self.removed component, doc._id
              self.removed self.collection, doc._id
              self.log "#{ self.subscription }:removed", doc._id
          @observers.main.initialized = true

        stop: ->
          observers.handle.stop() for observer of @observers
          @portlet.remove _id: @_id unless @persist

        # ###### publish()
        # A instance method for creating paginated publications.
        publish: ->
          @startMainObserver()
          @updateCount()
          @publication.ready()
          @startCountObserver()
          @persist()


    if Meteor.isClient
      @include

        helpers:
          subscribed: -> @get "subscription.ready"

          countTotal: ->
            return "..." unless @helpers.subscribed()
            @get "data.count.total"

          countFiltered: ->
            return "..." unless @helpers.subscribed()
            @get "data.count.filtered"

          pageStart: ->
            return "..." unless @helpers.subscribed()
            skip = @get "data.skip"
            start = skip + 1
            if start > 0 and start <= @helpers.pageEnd()
              return start
            else @error "Page start #{ start } is outside the pagination range."

          pageEnd: ->
            return "..." unless @helpers.subscribed()
            skip = @get "data.skip"
            limit = @get "data.limit"
            end = skip + limit
            filtered = @helpers.countFiltered()
            if end < filtered
              return end
            else return filtered

          pageCurrent: ->
            return "..." unless @helpers.subscribed()
            limit = @get "data.limit"
            skip = @get "data.skip"
            filtered = @get "data.count.filtered"
            currentPageNumber = Math.floor( skip / limit ) + 1
            lastPageNumber = Math.floor( filtered / limit ) + 1
            if currentPageNumber > 0 and currentPageNumber <= lastPageNumber
              return currentPageNumber
            else @error "The current page #{ currentPageNumber } is outside the pagination range for this data set."


        # ##### stopSubscription()
        stopSubscription: ->
          if @subscription.handle and @subscription.handle.stop
            @subscription.handle.stop()
          #@subscription.ready = false
          @save()

        subscriptionOnReady: ( callback ) ->
          @subscription.callback = callback if _.isFunction callback
          self = @
          return ->
            options =
              limit: self.get "data.limit"
              sort: self.get "data.sort"
            query =
              $and: [
                self.get "data.query"
                self.get "data.filter"
              ]
            self.cursor = LumaComponent.Collections[ @_id ].find query, options
            self.subscription.callback() if _.isFunction self.subscription.callback
            @subscription.ready = true
            @save()

        # ##### subscribe( Function )
        # Subscribes to the dataset for the current table state and stores the handle for later access.
        subscribe: ( callback = null ) ->
          @error "A subscription must be defined in order to subscribe to data." unless @subscription.name
          if @subscription.name
            @stopSubscription()
            @subscription.handle = Meteor.subscribe @subscription.name, @_id,
              onReady: @subscriptionOnReady callback
              onError: @error
            @log "subscription:ready", @subscription.handle.ready()

        nextPage: ->
          skip = @get "data.skip"
          limit = @get "data.limit"
          nextPage = skip + limit
          unless nextPage >= @helpers.countFiltered()
            @set "data.skip", nextPage
            @log "paginate:next", @helpers.pageCurrent()
            @persist()

        previousPage: ->
          skip = @get "data.skip"
          limit = @get "data.limit"
          previousPage = skip - limit
          unless previousPage < 0
            @set "data.skip", previousPage
            @log "paginate:previous", @helpers.pageCurrent()
            @persist()

        firstPage: ->
          unless @get "skip" is 0
            @set "skip", 0
            @log "paginate:first", @helpers.pageCurrent()
            @persist()

        lastPage: ->
          limit = @get "limit"
          count = @collectionCount "filtered"
          lastPage = count - limit
          unless lastPage is @get "skip"
            @set "data.skip", lastPage
            @log "paginate:last", @helpers.pageCurrent()
            @subscribe callback

        goToPage: ( page ) ->
          if _.isNumber page and _.isFunction callback
            limit = @get "limit"
            pageStart = ( page * limit ) - limit
            if pageStart >= @helpers.countFiltered()
              @set "data.skip", pageStart
              @log "paginate:page", page
              @subscribe callback
            else @error "Page #{ page } is outside the pagination range for this dataset."

        # ##### paginate( String or Number, Function )
        paginate: ( page ) ->
          if _.isFunction callback
            if _.isString page
              switch page
                when "next" then @nextPage()
                when "previous" then @previousPage()
                when "first" then @firstPage()
                when "last" then @lastPage()
                else @error "The paginate method currently only supports 'next' and 'previous' as pagination directions."
            else if _.isNumber page
              @goToPage page
            else @error "The page argument must be a number or string."