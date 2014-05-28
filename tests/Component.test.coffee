Tinytest.add "Luma Component - Instantiation", ( test ) ->
  class Whatever extends Component

  try
    duh = new Whatever {}
  catch error
    test.equal error.message, "All components must have defined a unique __name__ instance property", "An error is thrown if __name__ instance property is not defined."

  if Meteor.isServer
    class Ummm extends Component
      __name__: "Umm"

    umm = new Ummm
      subscription: "umm"

    try
      umm.rendered()
    catch error
      test.equal error.message, "Rendered callback is only available on the client.", "Calling the rendered method on the server should throw an error."

    try
      umm.destroyed()
    catch error
      test.equal error.message, "Destroyed callback is only available on the client.", "Calling the rendered method on the server should throw an error."



Tinytest.add "Luma Component - Getter Setters", ( test ) ->

  class Car extends Component
    __name__: "Car"

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

  sportsCar = instantiateComponent Car, data

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
    __name__: "User"
    @extend classProperties
    @include instanceProperties

  attrs =
    name: "Austin Rivas"
    email: "austinrivas@gmail.com"

  user = instantiateComponent User, {}

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
    __name__: "Model"
    @extend ORM

  model = instantiateComponent Model, {}

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

  user = instantiateComponent Model, data

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
      extended: ->
        if Meteor.isClient
          @include

            prepareUser: ->
              @data.user =
                name: @name()
                email: @email()
              @addGetterSetter "data", "user"
              @data.saved = undefined
              @addGetterSetter "data", "saved"
              @log "user:created", @user()

            save: ->
              @saved true
              @log "user:saved", @saved()

            unset: ->
              @saved false
              @log "user:destroyed", @saved()

    class Model extends Component
      __name__: "Model"
      @extend ORM

      rendered: ->
        @prepareUser()
        @save()
        super

      destroyed: ->
        @unset()
        super

    Template.componentFixture.created = -> new Model @
    component = UI.renderWithData Template.componentFixture, data

    test.notEqual component.templateInstance.save, undefined, "Mixin methods should be defined after the created callback is fired."
    test.notEqual component.templateInstance.unset, undefined, "Mixin methods should be defined after the created callback is fired."
    test.notEqual component.templateInstance.prepareUser, undefined, "Mixin methods should be defined after the created callback is fired."

    tI = component.templateInstance

    # Manually call the rendered callback to avoid writing an async test
    tI.rendered()

    test.notEqual tI.user, undefined, "Mixin methods should be defined after the created callback is fired."
    test.notEqual tI.saved, undefined, "Mixin methods should be defined after the created callback is fired."
    test.equal tI.user(), { name: data.name, email: data.email }, "Template rendered callback can call component methods."
    test.equal tI.saved(), true, "Template rendered callback can call component methods."
    test.equal tI.name(), "Austin Rivas", "Attribute accessors should still function when mixins are present."
    test.equal tI.email(), "austinrivas@gmail.com", "Attribute accessors should still function when mixins are present."

    # TODO : Test destroyed callback

if Meteor.isClient
  Tinytest.add "Luma Component - Dynamic Selector", ( test ) ->
    data =
      id: "widget-selector"
      class: "example"
      name: "Austin Rivas"
      email: "austinrivas@gmail.com"

    class Widget extends Component
      __name__: "Widget"

    tI = instantiateComponent Widget, data

    test.equal tI.selector(), "##{ data.id }", "If and id is provided it is set as the selector."

    tI2 = instantiateComponent Widget, _.omit data, "id"

    test.equal tI2.id(), "Widget-#{ tI2.__component__.guid }", "If no id is provided the id is set to <ClassName>-<guid>"
    test.equal tI2.selector(), "#Widget-#{ tI2.__component__.guid }", "If no id is provided the selector is set to #<ClassName>-<guid>"

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
    __name__: "Widget"
    defaults: defaults

  tI = instantiateComponent Widget, data

  test.equal tI.options(), mergedOptions, "Default options are merged with options property if defined."

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

    OtherMixin =
      extended: ->
        @include
          events:
            "clack": ( event, target ) -> Session.set "otherMixin-event", true

    class Widget extends Component
      __name__: "Widget"
      events:
        "click": ( event, target ) -> Session.set "instance-event", true

    tI = instantiateComponent Widget, data

    tI.events.click()

    test.equal Session.get( "instance-event" ), true, "Event maps defined as an instance property should fire normally."
    Session.set "instance-event", false

    class Widget extends Component
      __name__: "Widget"
      @extend Mixin

    tI = instantiateComponent Widget, data

    tI.events.click()

    test.equal Session.get( "mixin-event" ), true, "Event maps defined as an instance property on a mixin should fire normally."

    Session.set "instance-event", false
    Session.set "mixin-event", false

    class Widget extends Component
      __name__: "Widget"
      @extend Mixin
      events:
        "click": ( event, target ) -> Session.set "instance-event", true

    tI = instantiateComponent Widget, data

    tI.events.click()

    test.equal Session.get( "instance-event" ), true, "When events conflict, the event defined last takes precedence."
    test.equal Session.get( "mixin-event" ), false, "When events conflict, the event defined last takes precedence."

    Session.set "instance-event", false
    Session.set "mixin-event", false

    class Widget extends Component
      __name__: "Widget"
      events:
        "click": ( event, target ) -> Session.set "instance-event", true
      @extend Mixin

    tI = instantiateComponent Widget, data

    tI.events.click()

    test.equal Session.get( "instance-event" ), false, "When events conflict, the event defined last takes precedence."
    test.equal Session.get( "mixin-event" ), true, "When events conflict, the event defined last takes precedence."

    Session.set "instance-event", undefined
    Session.set "mixin-event", undefined

    Session.set "mixin-event", false
    Session.set "otherMixin-event", false

    class Widget extends Component
      __name__: "Widget"
      @extend Mixin
      @extend OtherMixin

    tI = instantiateComponent Widget, data

    tI.events.click()
    tI.events.clack()

    test.equal Session.get( "mixin-event" ), true, "Mixin events extend instead of override the event map."
    test.equal Session.get( "otherMixin-event" ), true, "Mixin events extend instead of override the event map."

    Session.set "mixin-event", undefined
    Session.set "otherMixin-event", undefined

    class Widget extends Component
      __name__: "Widget"
      @extend Mixin
      @extend OtherMixin
      events:
        "clock": ( event, target ) -> Session.set "instance-event", true

    tI = instantiateComponent Widget, data

    tI.events.clock()

    test.equal tI.events.click, undefined, "Setting instance events overrides all mixin events."
    test.equal tI.events.clack, undefined, "Setting instance events overrides all mixin events."
    test.equal Session.get( "instance-event" ), true, "Setting instance events overrides all mixin events."

    Session.set "instance-event", undefined





