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
  if Meteor.isClient
    @extend ComponentMixins.ChooseTemplate
    @extend ExampleComponentMixins.Events

if Meteor.isClient
  Template.example.created = -> new ExampleComponent @