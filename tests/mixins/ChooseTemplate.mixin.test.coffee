if Meteor.isClient
  Tinytest.add "Luma Component Mixins - Choose Template", ( test ) ->

    class Widget extends Component
      __name__: "Widget"
      @extend ComponentMixins.ChooseTemplate

    Template.componentFixture.created = -> new Widget @
    component = UI.render Template.componentFixture
    tI = component.templateInstance

    test.notEqual tI.chooseTemplate, undefined, "Choose template method should be defined after the component created callback is fired."
    test.equal tI.defaultTemplate(), "WidgetDefault", "defaultTemplate should be defined as `<className>Default`."

    try
      tI.chooseTemplate()
    catch error

    test.equal error.message, "WidgetDefault is not defined.", "If the default template is not defined chooseTemplate should throw an error."

    # Stub the default template being defined
    Template[ tI.defaultTemplate() ] = true

    test.equal tI.chooseTemplate(), true, "Calling chooseTemplate with no args should return the default template."

    Template[ tI.defaultTemplate() ] = undefined

    test.equal tI.chooseTemplate( "componentFixture" ), Template.componentFixture, "Calling chooseTemplate with a valid template should return the template."