# Component Base Class
class Component
  # ##### constructor()
  constructor: ->
    # Add getter setter methods for everything in the component data context.
    # The resulting object should look something like this :
    ###
      ```javascript
        { data:
          { doors: 2,
            color: 'red',
            options: {
              performance: [Object],
              convertible: [Object]
          }
        },
          doors: [Function],
          color: [Function],
          options: [Function]
        }
      ```
    ###
    @addGetterSetter( 'data', attr ) for attr of @data
    return @

  # ##### addGetterSetter( String, String )
  # Adds Getter Setter methods to all properties of the supplied object
  #   * propertyAttr : the key of the data container object
  #   * attr : the property key currently being added
  addGetterSetter: ( propertyAttr, attr ) ->
    # extend this with a function accessible by calling @.<attr>()
    @[ attr ] = (args...) ->
      # if the accessor is called without and arguments
      if args.length == 0
        # return the data
        @[ propertyAttr ][ attr ]
      # if the accessor is called with arguments
      else if args.length == 1
        # set the data to the first element of args
        @[ propertyAttr ][ attr ] = args[ 0 ]
      else throw new Error "Only one argument is allowed to a setter method."

  # ## Mixins

  # Component provides mixin support through two static functions, @extend() and @include()
  # which we can use for extending the class with static and instance properties respectively.

  # ##### Component.extend( Object )
  @extend: ( obj ) ->
    for key, value of obj when key not in Component.keywords
      @[ key ] = value

    obj.extended?.apply @
    return @

  # ##### Component.include( Object )
  @include: ( obj ) ->
    for key, value of obj when key not in Component.keywords
      # Assign properties to the prototype
      @::[ key ] = value

    obj.included?.apply @
    return @

  # The little dance around the keywords property is to ensure we have callback support when mixins extend a class.
  @keywords: [ 'extended', 'included' ]