//Run this example by adding  to the head of your layout file,
// like app/views/layouts/application.html.erb.

console.log('Hello world from coffeescript');
window.Routes = require('./routes.js.erb');
require("@rails/ujs").start();
require("turbolinks").start();
require("jquery");
import JQuery from 'jquery';
var $, jQuery;
window.$ = window.JQuery = jQuery = window.jQuery = $ = JQuery;
require("jquery-ui/ui/widgets/sortable");
require("jquery-ui/ui/widgets/draggable");
import('!raw-loader!./../../../node_modules/jquery-datetimepicker/build/jquery.datetimepicker.full.min.js').then(rawModule => eval.call(null, rawModule.default))
require(["jquery-datetimepicker"], function (es) {
    $.datetimepicker.setLocale('de');
})

console.log();

require("./coffee/bootstrap_modal_turbolinks_fix.coffee");
import 'bootstrap';
//import 'selectize/dist/js/selectize.min.js'; // # scroll to node folder (1) get that path

require("selectize");
require("./coffee/_selectize_turbolinks_fix.coffee");
require("select2");
require("popper.js");
require("script-loader!trix");

require("./coffee/administration.coffee");
require("./coffee/announcements.coffee");
require("./coffee/answers.coffee");
require("./coffee/chapters.coffee");
require("./coffee/clickers.coffee");
require("./coffee/courses.coffee");
require("./coffee/erdbeere.coffee");
require("./coffee/file_upload.coffee");
require("./coffee/items.coffee");
require("./coffee/katex.coffee");
require("./coffee/lectures.coffee");
require("./coffee/lessons.coffee");
require("./coffee/main.coffee");
require("./coffee/media.coffee");
require("./coffee/notifications.coffee");
require("./coffee/profile.coffee");
require("./coffee/questions.coffee");
require("./coffee/quizzes.coffee");
require("./coffee/referrals.coffee");
require("./coffee/registration.coffee");
require("./coffee/remarks.coffee");
require("./coffee/sections.coffee");
require("./coffee/submissions.coffee");
require("./coffee/tutorials.coffee");
require("./coffee/tags.coffee");
require("./coffee/terms.coffee");
require("./coffee/tex_preview.coffee");
require("./coffee/thyme.coffee");
require("./coffee/thyme_editor.coffee");
require("./coffee/upload.coffee");
require("./coffee/users.coffee");
require("./coffee/vertices.coffee");
import css from 'jquery-datetimepicker/build/jquery.datetimepicker.min.css'

//require('./../../../node_modules/jquery-datetimepicker/build/jquery.datetimepicker.min.css')
import {
    WidgetInstance
} from "friendly-challenge";
import('./styles/application.scss');

var friendlyChallengeWidgetInstance = WidgetInstance
document.addEventListener("turbolinks:load", function () {
    // ...

    var doneCallback, element, options, widget;

    doneCallback = function (solution) {
        console.log(solution);
        document.querySelector("#register-user").disabled = false;
    };
    const errorCallback = (err) => {
        console.log('There was an error when trying to solve the Captcha.');
        console.log(err);
    }
    element = document.querySelector('#captcha-widget');
    if (element != null) {
        options = {
            doneCallback: doneCallback,
            errorCallback,
            puzzleEndpoint: $('#captcha-widget').data("captcha-url"),
            startMode: "auto"
        };

        widget = new WidgetInstance(element, options);
        //DO not uncomment, evil
        //    widget.reset();
    }
})