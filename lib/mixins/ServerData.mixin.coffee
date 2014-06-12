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

LumaComponent.Mixins.ServerData =
  extended: ->
    @include
      
      portlet: true

      initializeServerData: ( context = {} ) ->
        @setSubscription context
        if @subscription
          if Meteor.isClient
            @setID()
            LumaComponent.Collections[ @_id ] ?= new Meteor.Collection @_id
            @data.limit ?= 10
            @data.skip ?= 0
            @data.sort ?= []
            @data.count ?=
              total: 0
              filtered: 0
            @data.page ?=
              current: 0
              start: 0
              end: 0
          @data.query ?= {}
          @data.filter ?= {}

      setSubscription: ( context = {} ) ->
        @persistable.push "subscription" unless "subscription" in @persistable
        subscription = if Meteor.isClient then context.data.subscription else context.subscription
        @subscription =
          name: subscription
          ready: false

    if Meteor.isServer
      @include

        # ###### initializePortlet( Object, Context )
        initializePortlet: ( portlet, context ) ->
          Match.test portlet, Object
          Match.test context, Object

          portlet.server = 
            context: context
            initialized: false
            options:
              limit: portlet.limit
              skip: portlet.skip
              sort: portlet.sort

          @log "#{ @subscription.name }:portlet:raw", _.omit portlet, "server"
          
          if _.isFunction @data.query
            queryMethod = _.bind @data.query, context
            query = queryMethod @
          else query = @data.query

          portlet.server.query =
            $and: [
              query
              portlet.data.query
            ]

          portlet.server.filter =
            $and: [
              portlet.server.query
              portlet.data.filter
            ] 

          @log "#{ @subscription.name }:portlet:server", _.omit portlet.server, "context"
          return portlet

        # ###### createCountHandle( Object )
        createCountHandle: ( portlet ) ->
          publication = @
          collection = publication.data.collection
          if portlet.server.options.limit
            # This is an attempt to monitor the last page in the dataset for changes, this is due to datatable on the client
            # breaking when the last page no longer contains any data, or is no longer the last page.
            lastPage = collection.find( portlet.server.filter ).count() - portlet.server.options.limit
            
            if lastPage > 0
              countPublication = _.clone portlet
              countPublication.server.initialized = false
              filter = countPublication.server.filter
              options = countPublication.server.options
              options.skip = lastPage
              countHandle = collection.find( filter, options ).observe
                addedAt: -> publication.updateCount countPublication
                changedAt: -> publication.updateCount countPublication
                removedAt: -> publication.updateCount countPublication
              countPublication.initialized = true
              return countHandle

        # ###### updateCount( Object )
        # Update the count values of the client component_count Collection to reflect the current filter state.
        updateCount: ( portlet ) ->
          # `initialized` is the initialization state of the subscriptions observe handle. Counts are only published after the observes are initialized.
          if portlet.initialized
            collection = @data.collection
            total = collection.find( portlet.server.query ).count()
            @log "#{ @subscription.name }:#{ portlet._id }:count:total", total

            filtered = collection.find( portlet.server.filter ).count()
            @log "#{ @subscription.name }:#{ portlet._id }:count:filtered", filtered

            @update portlet._id, count:
              total: total
              filtered: filtered



        # ###### createObserver( Object )
        # The component observes just the filtered and paginated subset of the Collection. This is for performance reasons as
        # observing large datasets entirely is unrealistic. The observe callbacks use `At` due to the sort and limit options
        # passed the the observer.
        createObserver: ( portlet ) ->
          pub = @
          collection = @data.collection
          serverCollection = collection._name
          portletCollection = portlet._id
          subscription = pub.subscription.name
          return collection.find( portlet.server.filter, portlet.server.options ).observe

            # ###### addedAt( Object, Number, Number )
            # Updates the count and sends the new doc to the client.
            addedAt: ( doc, index, before ) ->
              pub.updateCount publication
              portlet.server.context.added portletCollection, doc._id, doc
              portlet.server.context.added serverCollection, doc._id, doc
              pub.log "#{ subscription }:added", doc._id

            # ###### changedAt( Object, Object, Number )
            # Updates the count and sends the changed properties to the client.
            changedAt: ( newDoc, oldDoc, index ) ->
              pub.updateCount portlet
              portlet.server.context.changed portletCollection, newDoc._id, newDoc
              portlet.server.context.changed serverCollection, newDoc._id, newDoc
              pub.log "#{ subscription }:changed", newDoc._id

            # ###### removedAt( Object, Number )
            # Updates the count and removes the document from the client.
            removedAt: ( doc, index ) ->
              pub.updateCount portlet
              portlet.server.context.removed portletCollection, doc._id
              portlet.server.context.removed serverCollection, doc._id
              pub.log "#{ subscription }:removed", doc._id

        # ###### publish()
        # A instance method for creating paginated publications.
        publish: ->
          # ###### Meteor.publish
          # The publication this method provides is a paginated and filtered subset of the baseQuery defined during component instantiation on the server.
          # ###### Parameters
          #   + portlet_id: ( String ) The client collection these documents are being added to.
          #   + queries: ( Object ) the client queries on the dataset. Usually includes a base and filtered query.
          #   + options : ( Object ) sort and pagination options supplied by the client's current state.
          pub = @
          subscription = @subscription.name
          Meteor.publish subscription, ( portlet ) ->
            console.log "tits"
            context = @
            portlet = pub.initializePortlet portlet, context

            # After the observer is initialized the `initialized` flag is set to true, the initial count is published,
            # and the publication is marked as `ready()`
            handle = pub.createObserver portlet
            portlet.initialized = true
            pub.updateCount portlet, true
            context.ready()

            countHandle = pub.createCountHandle portlet

            context.changed LumaComponent.Portlet._name, portlet._id

            # When the publication is terminated the observers are stopped to prevent memory leaks.
            context.onStop ->
              handle.stop() if handle and handle.stop
              countHandle.stop() if countHandle and countHandle.stop


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
            return "Loading..." unless @helpers.subscribed()
            limit = @get "data.limit"
            skip = @get "data.skip"
            filtered = @get "data.count.filtered"
            currentPageNumber = ( skip // limit ) + 1
            lastPageNumber = ( filtered // limit ) + 1
            if currentPageNumber > 0 and currentPageNumber <= lastPageNumber
              return currentPageNumber
            else @error "The current page #{ currentPageNumber } is outside the pagination range for this data set."


        # ##### stopSubscription()
        stopSubscription: ->
          #Session.set "#{ @getData "id" }-subscriptionReady", false
          if @subscription.handle and @subscription.handle.stop
            @subscription.handle.stop()
            @set "subscription.ready", false

        subscriptionOnReady: ( callback ) ->
          if _.isFunction callback
            @subscription.callback = callback
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
            @set "subscription.ready", true

        # ##### subscribe( Function )
        # Subscribes to the dataset for the current table state and stores the handle for later access.
        subscribe: ( callback = null ) ->
          @error "A subscription must be defined in order to subscribe to data." unless @subscription.name
          if @persisted and @subscription.name
            @stopSubscription()
            portlet = @persist( false )
            @subscription.handle = Meteor.subscribe @subscription.name, @persist( false ),
              onReady: @subscriptionOnReady callback
              onError: @error
            @log "subscribe:portlet", portlet

        # ##### nextPage( Function )
        nextPage: ( callback ) ->
          skip = @get "data.skip"
          limit = @get "data.limit"
          nextPage = skip + limit
          unless nextPage >= @helpers.countFiltered()
            @set "data.skip", nextPage
            @log "paginate:next", @helpers.pageCurrent()
            @subscribe callback

        # ##### previousPage( Function )
        previousPage: ( callback ) ->
          skip = @get "data.skip"
          limit = @get "data.limit"
          previousPage = skip - limit
          unless previousPage < 0
            @set "data.skip", previousPage
            @log "paginate:previous", @helpers.pageCurrent()
            @subscribe callback

        # ##### firstPage( Function )
        firstPage: ( callback ) ->
          unless @get "skip" is 0
            @set "skip", 0
            @log "paginate:first", @helpers.pageCurrent()
            @subscribe callback

        # ##### lastPage( Function )
        lastPage: ( callback ) ->
          limit = @get "limit"
          count = @collectionCount "filtered"
          lastPage = count - limit
          unless lastPage is @get "skip"
            @set "data.skip", lastPage
            @log "paginate:last", @helpers.pageCurrent()
            @subscribe callback

        # ##### gotToPage( Number, Function )
        goToPage: ( page, callback ) ->
          if _.isNumber page and _.isFunction callback
            limit = @get "limit"
            pageStart = ( page * limit ) - limit
            if pageStart >= @helpers.countFiltered()
              @set "data.skip", pageStart
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