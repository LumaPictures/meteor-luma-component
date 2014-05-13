Package.describe({
  summary: "Blaze component mixins and base class"
});

Package.on_use(function (api, where) {
  api.use([
    'coffeescript',
    'underscore'
  ],[ 'client', 'server' ]);

  // for helpers
  api.use([
    'jquery',
    'ui',
    'templating',
    'spacebars'
  ], [ 'client' ]);

  /* Component */
  api.export([
    'ComponentMixins',
    'Component'
    /* ADD Component Exports here */
  ], [ 'client', 'server' ]);

  api.add_files([
    'lib/mixins/base.mixin.coffee',
    'lib/mixins/debug.mixin.coffee'
  ], [ 'client', 'server']);

  api.add_files([
    'lib/mixins/initialize.mixin.coffee',
    'lib/mixins/destroy.mixin.coffee',
    'lib/mixins/options.mixin.coffee',
    'lib/mixins/selector.mixin.coffee',
    'lib/mixins/utility.mixin.coffee'
    /* ADD ComponentComponent Mixins here */
  ], [ 'client' ]);

  api.add_files([
    'lib/component.coffee'
  ], [ 'client', 'server']);
  /* END ComponentComponent */
});

Package.on_test(function (api) {
  api.use([
    'coffeescript',
    'luma-component',
    'tinytest',
    'test-helpers'
  ], ['client', 'server']);

  api.add_files([
    'tests/component.tests.coffee'
  ], ['client', 'server']);
});