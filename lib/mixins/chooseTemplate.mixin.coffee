# # Choose Template Mixin
# The choose template mixin provides you with a default template property ( default to "<className>Default" )
# and the ability to switch template from within your component template.

# ### Notice
# The choose template mixin expects you to have a default template defined that follows the "<className>Default" convention.

# An example usage would be :
###
  ```html
    <template name="DataTable">
      <div id="{{selector}}" class="dataTable-container">
          {{#if UI.contentBlock }}
              {{> UI.contentBlock }}
          {{else}}
              {{#with self.chooseTemplate template }}
                  {{#with .. }}     {{! original arguments to DataTable }}
                      {{> .. }}     {{! return value from chooseTemplate( template ) }}
                  {{/with}}
              {{/with}}
          {{/if}}
      </div>
    </template>

    <template name="DataTableDefault">
        <table class="table display {{../../styles}}" cellspacing="0" width="100%"></table>
    </template>
  ```
###
ComponentMixins.ChooseTemplate =
  extended: ->
    @include
      # ##### defaultTemplate()
      defaultTemplate: -> return "#{ @constructor.name }Default"

      # ##### chooseTemplate ( String )
      # Return the template specified in the component parameters
      chooseTemplate: ( template = null ) ->
        # Set template to default if no template name is passed in
        template ?= @defaultTemplate()
        # If the template is defined return it
        if Template[ template ]
          template = Template[ template ]
          # Otherwise return the default template
        else if Template[ @defaultTemplate() ]
          template = Template[ @defaultTemplate() ]
        else throw new Error "#{ @defaultTemplate() } is not defined."
        @log "chooseTemplate", template
        return template