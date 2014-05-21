Template.home.created = ->
  components = [ "Rectangle", "Circle" ]

  for component in components
    Session.set "#{ component }_background", "none"
    Session.set "#{ component }_border", "red"
    Session.set "#{ component }_fill", "yellow"
    Session.set "#{ component }_stroke", "blue"

Template.home.helpers
  rectangleBackground: -> Session.get "Rectangle_background"
  rectangleBorder: -> Session.get "Rectangle_border"
  rectangleFill: -> Session.get "Rectangle_fill"
  rectangleStroke: -> Session.get "Rectangle_stroke"

  circleBackground: -> Session.get "Circle_background"
  circleBorder: -> Session.get "Circle_border"
  circleFill: -> Session.get "Circle_fill"
  circleStroke: -> Session.get "Circle_stroke"