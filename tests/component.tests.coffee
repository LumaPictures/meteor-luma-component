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

Tinytest.add "Luma Component - Mixins", ( test ) ->
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
      id: 1234
      class: "example"
      name: "Austin Rivas"
      email: "austinrivas@gmail.com"

    ORM =
      find: ( name ) -> return Session.get name or false
      extended: ->
        @include
          save: -> Session.set @name, @email
          destroy: -> Session.set @name, undefined

    class Model extends Component
      @extend ORM

    Template.componentFixture.created = -> new Model @
    Template.componentFixture.rendered = -> @save()
    Template.componentFixture.destroyed = -> @destroyed()

    component = UI.renderWithData Template.componentFixture, data
    tI = component.templateInstance

    test.equal tI.name(), "Austin Rivas", "Attribute accessors should still function when mixins are present."
    test.equal tI.email(), "austinrivas@gmail.com", "Attribute accessors should still function when mixins are present."

    UI.insert component, $( '<div></div>' )

    test.equal Session.get( "Austin Rivas" ), tI.find( "Austin Rivas" ), "Component methods are first class methods of the template instance."