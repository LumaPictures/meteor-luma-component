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

Template.home.events
	"change #Rectangle .background select": ( event, template ) -> Session.set "Rectangle_background", event.val
	"change #Rectangle .border select": ( event, template ) -> Session.set "Rectangle_border", event.val
	"change #Rectangle .fill select": ( event, template ) -> Session.set "Rectangle_fill", event.val
	"change #Rectangle .stroke select": ( event, template ) -> Session.set "Rectangle_stroke", event.val

	"change #Circle .background select": ( event, template ) -> Session.set "Circle_background", event.val
	"change #Circle .border select": ( event, template ) -> Session.set "Circle_border", event.val
	"change #Circle .fill select": ( event, template ) -> Session.set "Circle_fill", event.val
	"change #Circle .stroke select": ( event, template ) -> Session.set "Circle_stroke", event.val
