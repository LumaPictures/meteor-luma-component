Tinytest.add "Luma Component - Chained Attribute Accessor", ( test ) ->

  class Car extends Component
    constructor: ( @data ) -> super

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


  sportsCar = new Car data

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

  sportsCar.color "black"
  sportsCar.doors 4

  test.equal sportsCar.color(), "black", "Setting an accessor should set the property."
  test.equal sportsCar.doors(), 4, "Setting an accessor should set the property."

  sportsCar.options {}
  test.equal sportsCar.options(), {}, "Setting an accessor should set the property."