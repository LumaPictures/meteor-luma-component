Tinytest.add "Luma Component - Attribute Accessor", ( test ) ->

  class Car extends Component

  data =
    doors: 2
    color: 'red'
    options:
      performance:
        tires:
          manufacturer: "Dunlop"
          name: "Star Spec"
      convertible:
        hardTop: true

  if Meteor.isClient
    context =
      data: data
  if Meteor.isServer
    context = data

  sportsCar = new Car context

  test.equal sportsCar.data, data, "Properties should be identical after instantiation."
  test.equal sportsCar.doors(), data.doors, "Attribute accessor should return property value."
  test.equal sportsCar.color(), data.color, "Attribute accessor should return property value."
  test.equal sportsCar.options(), data.options, "Attribute accessor should return property value."
  test.equal sportsCar.options().performance, data.options.performance, "Attribute accessor should return property value."
  test.equal sportsCar.options().performance.tires, data.options.performance.tires, "Attribute accessor should return property value."
  test.equal sportsCar.options().performance.tires.manufacturer, data.options.performance.tires.manufacturer, "Attribute accessor should return property value."
  test.equal sportsCar.options().performance.tires.name, data.options.performance.tires.name, "Attribute accessor should return property value."
  test.equal sportsCar.options().convertible, data.options.convertible, "Attribute accessor should return property value."
  test.equal sportsCar.options().convertible.hardTop, data.options.convertible.hardTop, "Attribute accessor should return property value."

  try
    sportsCar.doesntExist()
  catch error
    if Meteor.isServer
      message = "Object #<Car> has no method 'doesntExist'"
    if Meteor.isClient
      message = "undefined is not a function"
    test.equal error.message, message, "Calling an undefined accessor should result in an error."

  if sportsCar.color
    test.equal true, true, "Accessor methods should serve dual purpose as conditionals."
  else test.equal true, false, "Accessor methods should serve dual purpose as conditionals."

  unless sportsCar.doesntExist
    test.equal true, true, "Accessor methods should serve dual purpose as conditionals."
  else test.equal true, false, "Accessor methods should serve dual purpose as conditionals."

  sportsCar.color "black"
  sportsCar.doors 4

  test.equal sportsCar.color(), "black", "Setting an accessor should set the property."
  test.equal sportsCar.doors(), 4, "Setting an accessor should set the property."

  sportsCar.options {}
  test.equal sportsCar.options(), {}, "Setting an accessor should set the property."

Tinytest.add "Luma Component - Mixin Support", ( test ) ->
  classProperties =
    find: ( id ) -> return id
    create: ( attrs ) -> return attrs

  instanceProperties =
    save: ( id ) -> return id
    destroy: ( id ) -> return true

  class User extends Component
    @extend classProperties
    @include instanceProperties

  attrs =
    name: "Austin Rivas"
    email: "austinrivas@gmail.com"

  user = new User()
  test.equal User.find( 1 ), 1, "Class methods mixed into a class should be present on the class."
  test.equal User.create( attrs ), attrs, "Class methods mixed into a class should be present on the class."
  test.equal user.save( 1 ), 1, "Instance methods mixed into a class should be present on instances of that class."
  test.equal user.destroy( 2 ), true, "Instance methods mixed into a class should be present on instances of that class."

  ORM =
    find: ( id ) -> return id
    create: ( attrs ) -> return attrs
    extended: ->
      @include
        save: ( id ) -> return id
        destroy: ( id ) -> return true

  class Model extends Component
    @extend ORM

  model = new Model()
  test.equal Model.find( 1 ), 1, "Class methods mixed into a class should be present on the class."
  test.equal Model.create( attrs ), attrs, "Class methods mixed into a class should be present on the class."
  test.equal model.save( 1 ), 1, "Instance methods mixed into a class should be present on instances of that class."
  test.equal model.destroy( 2 ), true, "Instance methods mixed into a class should be present on instances of that class."

  data =
    name: "Austin Rivas"
    email: "austinrivas@gmail.com"
    tags: [
      key: "value"
    ]

  if Meteor.isClient
    context =
      data: data
  if Meteor.isServer
    context = data
  user = new Model context

  test.equal user.name(), "Austin Rivas", "Attribute accessors should still function when mixins are present."
  test.equal user.email(), "austinrivas@gmail.com", "Attribute accessors should still function when mixins are present."
  test.equal user.tags()[ 0 ].key, "value", "Attribute accessors should still function when mixins are present."
  test.equal user.save( 3 ), 3, "Instance methods should still function when attribute accessors are created."
  test.equal user.destroy( 2 ), true, "Instance methods should still function when attribute accessors are created."
  test.equal Model.find( 1 ), 1, "Class methods should still function when attribute accessors are created."
  test.equal Model.create( attrs ), attrs, "Class methods should still function when attribute accessors are created."

if Meteor.isClient
  Tinytest.add "Luma Component - Extend Template", ( test ) ->
    data =
      id: "extend-template"
      class: "example"
      name: "Austin Rivas"
      email: "austinrivas@gmail.com"

    ORM =
      currentUser: -> Session.get "user" or false
      extended: ->
        @include
          initialize: ->
            Session.set "created", true
            Session.set "user", @name()
          save: -> Session.set "rendered", true
          unset: -> Session.set "destroyed", true

    class Model extends Component
      @extend ORM
      constructor: ->
        super
        @initialize()

      rendered: ->
        @save()
        super
      destroyed: ->
        @unset()
        super

    Session.setDefault "created", undefined
    Session.setDefault "rendered", undefined
    Session.setDefault "destroyed", undefined

    Template.componentFixture.created = -> new Model @
    Template.componentFixture.rendered = -> @rendered()
    Template.componentFixture.destroyed = -> @destroyed()

    component = UI.renderWithData Template.componentFixture, data
    tI = component.templateInstance

    test.equal Session.get( "created" ), true, "Template created callback can instantiate a Component and call its methods."
    test.equal Model.currentUser(), "Austin Rivas", "Attribute accessors available in component constructor."
    test.equal tI.name(), "Austin Rivas", "Attribute accessors should still function when mixins are present."
    test.equal tI.email(), "austinrivas@gmail.com", "Attribute accessors should still function when mixins are present."

    $DOM = $( '<div id="parentNode"></div>' )
    UI.insert component, $DOM

    test.equal Session.get( "rendered" ), true, "Template rendered callback can call component methods."

    $( "##{ data.id }", $DOM ).remove()

    test.equal Session.get( "destroyed" ), true, "Template destroyed callback can call component methods."

    Session.set "created", undefined
    Session.set "rendered", undefined
    Session.set "destroyed", undefined

if Meteor.isClient
  Tinytest.add "Luma Component - Dynamic Selector", ( test ) ->
    data =
      id: "widget-selector"
      class: "example"
      name: "Austin Rivas"
      email: "austinrivas@gmail.com"

    class Widget extends Component

    Template.componentFixture.created = -> new Widget @

    component = UI.renderWithData Template.componentFixture, data
    tI = component.templateInstance

    test.equal tI.selector(), data.id, "If and id is provided it is set as the selector."

    componentWithoutId = UI.renderWithData Template.componentFixture, _.omit data, "id"
    tI2 = componentWithoutId.templateInstance

    test.equal tI2.selector(), "Widget-#{ tI2.__component__.guid }", "If no id is provided the selector is set to <ClassName>-<guid>"

Tinytest.add "Luma Component - Default Options", ( test ) ->
  data =
    name: "Austin Rivas"
    email: "austinrivas@gmail.com"
    options:
      awesome: true
      lame: false

  defaults =
    cool: "very"
    lame: true

  options = _.clone data.options
  mergedOptions = _.defaults options, defaults

  class Widget extends Component
    defaults: defaults

  if Meteor.isServer
    widget = new Widget data

    test.equal widget.options(), mergedOptions, "If and id is provided it is set as the selector."

  if Meteor.isClient
    Template.componentFixture.created = -> new Widget @
    component = UI.renderWithData Template.componentFixture, data
    tI = component.templateInstance

    test.equal tI.options(), mergedOptions, "If and id is provided it is set as the selector."

if Meteor.isClient
  Tinytest.add "Luma Component - DOM Events", ( test ) ->

    Session.set "instance-event", false
    Session.set "mixin-event", false

    data =
      id: "dom-events"
      class: "example"
      name: "Austin Rivas"
      email: "austinrivas@gmail.com"

    Mixin =
      extended: ->
        @include
          events:
            "click": ( event, target ) -> Session.set "mixin-event", true

    class Widget extends Component
      events:
        "click": ( event, target ) -> Session.set "instance-event", true

    Template.componentFixture.created = -> new Widget @
    component = UI.renderWithData Template.componentFixture, data
    tI = component.templateInstance

    tI.events.click()

    test.equal Session.get( "instance-event" ), true, "Event maps defined as an instance property should fire normally."
    Session.set "instance-event", false

    class Widget extends Component
      @extend Mixin

    Template.componentFixture.created = -> new Widget @
    component = UI.renderWithData Template.componentFixture, data
    tI = component.templateInstance

    tI.events.click()

    test.equal Session.get( "mixin-event" ), true, "Event maps defined as an instance property on a mixin should fire normally."

    Session.set "instance-event", false
    Session.set "mixin-event", false

    class Widget extends Component
      @extend Mixin
      events:
        "click": ( event, target ) -> Session.set "instance-event", true

    Template.componentFixture.created = -> new Widget @
    component = UI.renderWithData Template.componentFixture, data
    tI = component.templateInstance

    tI.events.click()

    test.equal Session.get( "instance-event" ), true, "When events conflict, the event defined last takes precedence."
    test.equal Session.get( "mixin-event" ), false, "When events conflict, the event defined last takes precedence."

    Session.set "instance-event", false
    Session.set "mixin-event", false

    class Widget extends Component
      events:
        "click": ( event, target ) -> Session.set "instance-event", true
      @extend Mixin

    Template.componentFixture.created = -> new Widget @
    component = UI.renderWithData Template.componentFixture, data
    tI = component.templateInstance

    tI.events.click()

    test.equal Session.get( "instance-event" ), false, "When events conflict, the event defined last takes precedence."
    test.equal Session.get( "mixin-event" ), true, "When events conflict, the event defined last takes precedence."

    Session.set "instance-event", undefined
    Session.set "mixin-event", undefined





