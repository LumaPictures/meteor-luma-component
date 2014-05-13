# # Example Component
if Meteor.isClient
  # Theses mixins are included, extend the component by creating your own mixins and merging them in here.
  @ExampleComponent = _.extend {},
    ComponentMixins.Base,
    ComponentMixins.Initialize,
    ComponentMixins.Destroy,
    ComponentMixins.Options,
    ComponentMixins.Selector,
    ComponentMixins.Utility,
    ComponentMixins.Debug
    # Add additional client mixin namespaces here
  
  @ExampleComponent.defaultOptions = {}

# Components are client only by default, but if you need to have a presence on the server you can define server mixins.
else if Meteor.isServer
  # `ExampleComponent = _.extend {}, ExampleMixins.Debug`
  @ExampleComponent = _.extend {},
    ComponentMixins.Base,
    ComponentMixins.Debug
    # Add additional server mixin namespaces here

  @ExampleComponent.defaultOptions = {}