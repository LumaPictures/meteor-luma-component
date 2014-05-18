@ExampleComponentMixins =
  Events:
    extended: ->
      @include
        events:
          "click": ( event, template ) ->
            template.log "event:click", event

class @ExampleComponent extends Component
  if Meteor.isClient
    @extend ComponentMixins.ChooseTemplate
    @extend ExampleComponentMixins.Events