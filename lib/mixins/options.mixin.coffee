# # Component Options
# #### `options` Object ( optional )
# `options` are additional options you would like merged with the defaults `_.defaults options, defaultOptions`.
ComponentMixins.Options =
  # ##### setOptions()
  setOptions: ( options ) ->
    Match.test options, Object
    @setData 'options', options

  # ##### getOptions()
  getOptions: ->
    return @getData().options or false

  # ##### prepareOptions()
  # Prepares the datatable options object by merging the options passed in with the defaults.
  prepareOptions: ->
    options = @getOptions() or {}
    options.component = @
    @setOptions _.defaults( options, @defaultOptions )