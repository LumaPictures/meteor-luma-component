# luma-component [![Build Status](https://travis-ci.org/LumaPictures/meteor-luma-component.svg?branch=master)](https://travis-ci.org/LumaPictures/meteor-luma-component)
### Blaze component mixins and base class

`luma-component` allows you to write modular UI components that support mixins to extend their functionality and share methods with other components.

The reason this package was developed was in order to share common features between UI components, like dynamic templating and subscription logic.

Creating your own component is straightforward :

```coffeescript
class MyComponent extends Component
    __name__: "MyComponent"

Template.MyComponent.created = -> new MyComponent @
```

Now whenever you use the `MyComponent` helper in one of you templates it will be extended with the methods you defined on your component.

For additional examples and more in depth documentation see the Usage section below.

## Usage

### Declaration

The simplest your component can get is to just extend the `Component` class and set the `__name__` instance property to a unique name ( to avoid minification clobbering class names )

```coffeescript
class MyComponent extends Component
    __name__: "MyComponent"
```

Note that if you are declaring the component in your application instead of a package ( recommended ) use the `@` context to make your component globally accessible.

```coffeescript
class @MyComponent extends Component
    __name__: "MyComponent"
```

To actually instantiate the component you extend a template instance ( can be any template, not necessarily MyComponent ) via the created callback.

```coffeescript
Template.MyComponent.created = -> new MyComponent @
```

This will automatically bind any `rendered` or `destroyed` methods and `events` in your class to the corresponding template. Calling super will ensure that the parent callback method is also called.

```coffeescript
class MyComponent extends Component
    __name__: "MyComponent"

    someInstanceMethod: -> @log "I do nothing"

    @someClassMethod: -> @log "I also do nothing"

    rendered: ->
        @someInstanceMethod()
        super

    destroyed: ->
        MyComponent.someClassMethod()
        super
```

### Getter Setter Methods

The `Component` class also creates getter setter methods for all of your data properties so that you can access them easily in your instance methods.

Assuming a template with the following data context

```html
{{> MyComponent salutations="Hola!" }}
```

```coffeescript
class MyComponent extends Component
    __name__: "MyComponent"

    rendered: ->
        @log "Greetings", @salutations()
        super

    destroyed: ->
        @salutations "Goodbye!"
        @log "Farewell", @salutations()
        super

Template.MyComponent.created = -> new MyComponent @
```

This is done by default on all data properties passed in through the block helper.

Call the `@addGetterSetter( ContainerObjectKey, PropertyKey )` to add additional getter setter methods after the component has been instantiated, in response to a reactive computation for instance.

```coffeescript
class MyComponent extends Component
    __name__: "MyComponent"

    setCurrentSelection: ->
        if Session.get "selected"
            unless @selected
                @data.selected = selected
                @addGetterSetter "data", "selected"
            @selected Session.get "selected"

    doSomethingWithSelected: -> @log "selected", @selected()
```

### Logs

All components that extend the `Component` class have access to the `@log` method, which allows you to specify distinct logging and debugging levels like so:

```html
{{> MyComponent debug="all" }}
```

Setting `debug` to "all" will log every `@log` call to console, all other debug values will log any `@log` methods whos message contains the debug string.

Some useful settings may be :

```html
{{> MyComponent debug="created" }}
```

```html
{{> MyComponent debug="rendered" }}
```

```html
{{> MyComponent debug="destroyed" }}
```

```html
{{> MyComponent debug="event" }}
```

```html
{{> MyComponent debug="selected" }}
```

The log behavior can be overriden by defining your own log method. A simple example that logs all messages to a collection can be useful for automated error reporting.

```coffeescript
class MyComponent extends Component
    __name__: "MyComponent"

    log: ( message, object ) ->
        Logs.insert
            message: message
            object: object
```

### Mixins

By far the most powerful and useful feature of this package is how it provides mixin support for Blaze components.

Mixins are a powerful pattern that allow you to create reusable objects that provide a distinct set of functionality.

All component mixins follow the pattern outlined in the [ Little Book on Coffeescript ](http://arcturo.github.io/library/coffeescript/03_classes.html), allowing you to add both instance and class methods to the server or client component.

An example mixin looks like this :

```coffeescript
ORM =
  someClassMethod: ->
  someClassProperty: "Hola!"
  extended: ->
    @include
      someInstanceProperty: "Hi!"
      someInstanceMethod: ->
    if Meteor.isClient
        @include:
            someClientInstanceMethod: ->
    if Meteor.isServer
        @include:
            someServerInstanceMethod: ->

class MyComponent extends Component
  @extend ORM
```

If you choose you can only include a mixin on the client or server like this :

```coffeescript
class MyComponent extends Component
    if Meteor.isServer
        @extend ORM
```

All instance methods and properties are available as template helpers through the `self` namespace in your component template.

```html
<template name="MyComponent">
    <h1> {{ self.someInstanceProperty }} </h1>
</template>
```

For a more robust example see the `Component.ChooseTemplate` mixin below.

#### Included Mixins

All included mixins can be found under the `ComponentMixins` namespace that is exported by this package along with the `Component` class.

* Component.ChooseTemplate - Dynamically render a template or the default `Template.<__name__>Default`

    ```coffeescript
    class MyComponent extends Component
        if Meteor.isClient
            @extend Component.ChooseTemplate
    ```

    ```html
    <template name="MyComponentDefault">
        <h1> {{salutations}} </h1>
    </template>

    <template name="MyComponentRude">
        <h1> Go Away! </h1>
    </template>

    <template name="MyComponent">
        {{#with self.chooseTemplate template }}
          {{#with .. }}     {{! original arguments to MyComponent }}
              {{> .. }}     {{! return value from chooseTemplate( template ) }}
          {{/with}}
        {{/with}}
    </template>

    <template name="home">
        {{> MyComponent template="MyComponentRude" }}
    </template>
    ```
### Events

There are several ways you can bind events to a component, the simplest and least flexible is simply setting the event map as an instance property of your class.

```coffeescript
class MyComponent extends Component
    __name__: "MyComponent"

    someInstanceMethod: -> @log "I do nothing"

    events:
        "click": ( event, template ) -> template.someInstanceMethod()
```

However I prefer to define my events in mixins so that I can easily reuse them in several components.

```coffeescript
LogClick =
  extended: ->
    if Meteor.isClient
        @include:
            someClientInstanceMethod: -> @log "I do nothing"
            events:
                "click": ( event, template ) -> template.someClientInstanceMethod()

LogDoubleClick =
  extended: ->
    if Meteor.isClient
        @include:
            someOtherClientInstanceMethod: -> @log "I do nothing"
            events:
                "dblclick": ( event, template ) -> template.someOtherClientInstanceMethod()

class MyComponent extends Component
    @extend LogClick

class MyOtherComponent extends Component
    @extend LogClick
    @extend LogDoubleClick
```

Be aware that mixins will override other mixins events if their triggers conflict in the order they are added to the class.

Defining an event map on the class will override *ALL* events provided by mixins. I am still unsure as to whether or not this is the desired behavior.

### Luma Component in the Wild

* [ jquery-datatables ](https://github.com/LumaPictures/meteor-jquery-datatables/blob/master/lib/DataTables.component.coffee)
* [ jquery-select2 ](https://github.com/LumaPictures/meteor-jquery-select2/blob/master/lib/Select2.component.coffee)


## Example
```
$ git clone https://github.com/LumaPictures/meteor-luma-component
$ cd LumaPictures/meteor-luma-component
$ mrt install && meteor
```

## Tests
```
$ git clone https://github.com/LumaPictures/meteor-luma-component
$ cd LumaPictures/meteor-luma-component
$ mrt install && meteor test-packages luma-component
```

## Contributing

* [ Meteor-Talk Announcement ]()