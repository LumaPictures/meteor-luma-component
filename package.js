Package.describe({
  summary: "Blaze component mixins and base class"
});

Package.on_use(function (api, where) {
  api.use([
    'coffeescript',
    'underscore'
  ],[ 'client', 'server' ]);

  /* Component */
  api.export([
    'Component'
    /* ADD Component Exports here */
  ], [ 'client', 'server' ]);

  api.add_files([
    'lib/component.coffee'
  ], [ 'client', 'server']);
  /* END Component */
});

Package.on_test(function (api) {
  api.use([
    'coffeescript',
    'underscore',
    'luma-component',
    'tinytest',
    'test-helpers'
  ], ['client', 'server']);

  api.use([
    'jquery',
    'ui',
    'templating',
    'spacebars'
  ], [ 'client' ]);

  api.add_files([
    'tests/fixtures.html'
  ], [ 'client' ]);

  api.add_files([
    'tests/component.tests.coffee'
  ], ['client', 'server']);
});