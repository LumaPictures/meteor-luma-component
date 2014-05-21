@ExampleComponentMixins =
  Events:
    extended: ->
      if Meteor.isClient
        @include
          events:
            "click": ( event, template ) ->
              template.log "event:click", event



class @ExampleComponent extends Component
  __name__: "ExampleComponent"
  @extend ComponentMixins.ChooseTemplate
  @extend ComponentMixins.Reactive
  @extend ExampleComponentMixins.Events

  rendered: ->
    if Meteor.isClient

      backgroundCallback = ( data ) ->
        @options().background = data
        @log "backgroundCallback", @options().background

      @createReactiveCallback "backgroundCallback", backgroundCallback.bind( @ )

      super

  destroyed: ->
    super


if Meteor.isClient
  Template.example.created = -> new ExampleComponent @