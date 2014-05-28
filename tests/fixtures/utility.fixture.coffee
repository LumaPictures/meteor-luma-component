@instantiateComponent = ( Component, data ) ->
  if Meteor.isClient
    Template.componentFixture.created = -> new Component @
    component = UI.renderWithData Template.componentFixture, data
    return component.templateInstance
  if Meteor.isServer
    return new Component _.extend data, subscription: "example_subscription"