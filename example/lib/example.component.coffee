@ExampleComponentMixins =
  Events:
    extended: ->
      if Meteor.isClient
        @include
          events:
            "click": ( event, template ) ->
              template.log "event:click", event

  Background:
    extended: ->
      if Meteor.isClient
        @include
          backgroundHelper: ( data ) ->
            @options().background = data
            @log "backgroundCallback", @options().background




class @ExampleComponent extends Component
  __name__: "ExampleComponent"
  @extend ComponentMixins.ChooseTemplate
  @extend ComponentMixins.Reactive
  @extend ExampleComponentMixins.Events
  @extend ExampleComponentMixins.Background

  rendered: ->
    if Meteor.isClient
      @createHelper "backgroundHelper", @backgroundHelper.bind( @ )
      super

  destroyed: ->
    super


if Meteor.isClient
  Template.example.created = -> new ExampleComponent @