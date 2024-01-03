// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `rails generate channel` command.
//
// disable eslint
/* eslint-disable */
//= require action_cable
//= require_self
//= require_tree ./channels
/* eslint-enable */

(function() {
  this.App || (this.App = {});

  App.cable = ActionCable.createConsumer();

}).call(this);
