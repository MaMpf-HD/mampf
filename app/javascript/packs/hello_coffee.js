//Run this example by adding  to the head of your layout file,
// like app/views/layouts/application.html.erb.

console.log('Hello world from coffeescript');

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

require("./coffee/bootstrap_modal_turbolinks_fix");
import 'bootstrap';
//import 'selectize/dist/js/selectize.min.js'; // # scroll to node folder (1) get that path
import 'selectize/dist/css/selectize.css';
require("selectize");
require("./coffee/_selectize_turbolinks_fix.coffee");
require("select2");
require("popper.js");
require("script-loader!trix");

require("./coffee/administration.coffee");
require("./coffee/announcements");
require("./coffee/answers");
require("./coffee/chapters");
require("./coffee/clickers");
require("./coffee/courses");
require("./coffee/erdbeere");
require("./coffee/file_upload");
require("./coffee/items");
require("./coffee/katex");
require("./coffee/lectures");
require("./coffee/lessons");
require("./coffee/main");
require("./coffee/media");
require("./coffee/notifications");
require("./coffee/profile");
require("./coffee/questions");
require("./coffee/quizzes");
require("./coffee/referrals");
require("./coffee/registration");
require("./coffee/remarks");
require("./coffee/sections");
require("./coffee/submissions");
require("./coffee/tutorials");
require("./coffee/tags");
require("./coffee/terms");
require("./coffee/tex_preview");
require("./coffee/thyme");
require("./coffee/thyme_editor");
require("./coffee/upload");
require("./coffee/users");
require("./coffee/vertices");
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