Template.home.created = ->
  components = [ "Rectangle", "Circle" ]

  for component in components
    Session.set "#{ component }_background", "none"
    Session.set "#{ component }_border", "red"
    Session.set "#{ component }_fill", "yellow"
    Session.set "#{ component }_stroke", "blue"

Template.home.helpers
  rectangleOptions: -> return {
    width: "100%"
    height: "200px"
    viewbox: "0 0 1200 400"
    background: Session.get "Rectangle_background"
    border: Session.get "Rectangle_border"
    fill: Session.get "Rectangle_fill"
    stroke: Session.get "Rectangle_stroke"
  }

  circleOptions: -> return {
    width: "100%"
    height: "200px"
    viewbox: "0 0 1200 400"
    background: Session.get "Circle_background"
    border: Session.get "Circle_border"
    fill: Session.get "Circle_fill"
    stroke: Session.get "Circle_stroke"
  }

  selected: -> return {
    rectangle:
      background: Session.get "Rectangle_background"
      border: Session.get "Rectangle_border"
      fill: Session.get "Rectangle_fill"
      stroke: Session.get "Rectangle_stroke"
    circle:
      background: Session.get "Circle_background"
      border: Session.get "Circle_border"
      fill: Session.get "Circle_fill"
      stroke: Session.get "Circle_stroke"
  }

Template.home.events
	"change #Rectangle .background select": ( event, template ) -> Session.set "Rectangle_background", event.val
	"change #Rectangle .border select": ( event, template ) -> Session.set "Rectangle_border", event.val
	"change #Rectangle .fill select": ( event, template ) -> Session.set "Rectangle_fill", event.val
	"change #Rectangle .stroke select": ( event, template ) -> Session.set "Rectangle_stroke", event.val

	"change #Circle .background select": ( event, template ) -> Session.set "Circle_background", event.val
	"change #Circle .border select": ( event, template ) -> Session.set "Circle_border", event.val
	"change #Circle .fill select": ( event, template ) -> Session.set "Circle_fill", event.val
	"change #Circle .stroke select": ( event, template ) -> Session.set "Circle_stroke", event.val
