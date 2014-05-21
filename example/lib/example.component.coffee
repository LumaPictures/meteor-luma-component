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
          backgroundHelper: ( background ) ->
            unless background is @options().background
              options = @options()
              options.background = background
              @options options
            @log "backgroundHelper", @options().background

class @ExampleComponent extends Component
  __name__: "ExampleComponent"
  @extend ComponentMixins.ChooseTemplate
  @extend ExampleComponentMixins.Events
  @extend ExampleComponentMixins.Background

if Meteor.isClient
  Template.example.created = -> new ExampleComponent @