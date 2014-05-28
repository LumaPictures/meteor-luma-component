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

class @ChooseTemplateComponent extends Component
  __name__: "ChooseTemplate"
  @extend ComponentMixins.ChooseTemplate
  @extend ExampleComponentMixins.Events
  @extend ExampleComponentMixins.Background

if Meteor.isClient
  Template.ChooseTemplate.created = -> new ChooseTemplateComponent @