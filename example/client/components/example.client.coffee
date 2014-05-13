# # Example Client
# ##### Extending the Template
# `Template.example` is extended with `ExampleComponent`'s methods so that the template callbacks can execute
# `ExampleComponent` instance methods. In truth `Template.example` is the actual `ExampleComponent`.
Template.example = _.extend Template.example, ExampleComponent

# ##### created()
# This is the component constructor.
Template.example.created = ->
  templateInstance = @
  instantiatedComponent = templateInstance.__component__
  instantiatedComponent.prepareSelector()
  instantiatedComponent.prepareOptions()
  instantiatedComponent.log "created", @

# ##### rendered()
# When the component is first rendered the component is initialized  and `templateInstance.__component__` is the `this` context
Template.example.rendered = ->
  templateInstance = @
  instantiatedComponent = templateInstance.__component__
  instantiatedComponent.log "rendered", @
  instantiatedComponent.initialize()

# ##### destroyed()
# The `ExampleComponent.destroy()` method is a convenient place to do teardown and cleanup.
Template.example.destroyed = ->
  templateInstance = @
  instantiatedComponent = templateInstance.__component__
  instantiatedComponent.destroy()
  instantiatedComponent.log "destroyed", @

# ##### events()
Template.example.events = {}

# ##### helpers()
Template.example.helpers = {}