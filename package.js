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
    'LumaComponent'
    /* ADD Component Exports here */
  ], [ 'client', 'server' ]);

  api.add_files([
    'lib/Component.coffee'
  ], [ 'client', 'server']);

  api.add_files([
    'lib/mixins/ServerData.mixin.coffee'
  ], [ 'client', 'server' ]);
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
    'tests/fixtures/utility.fixture.coffee'
  ], [ 'client', 'server' ]);

  api.add_files([
    'tests/fixtures/ComponentFixture.html'
  ], [ 'client' ]);

  api.add_files([
    'tests/Component.test.coffee',
    'tests/mixins/ChooseTemplate.mixin.test.coffee'
  ], ['client', 'server']);
});