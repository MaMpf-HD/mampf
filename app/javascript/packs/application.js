/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

//import * from 'jquery-datetimepicker'
import css from 'jquery-datetimepicker/build/jquery.datetimepicker.min.css'
//require('./../../../node_modules/jquery-datetimepicker/build/jquery.datetimepicker.min.css')
import myLib from 'imports-loader?imports=default%20jquery%20$!./../../../node_modules/jquery-datetimepicker/build/jquery.datetimepicker.full.min.js'
import {
    WidgetInstance
} from "friendly-challenge";
var friendlyChallengeWidgetInstance = WidgetInstance
require(["jquery-datetimepicker"], function (es) {
    $.datetimepicker.setLocale('de');
})


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
            startMode: "auto",
            language:$('#captcha-widget').data("lang")
        };
        console.log(options)
        widget = new WidgetInstance(element, options);
        //DO not uncomment, evil
        //    widget.reset();
    }
})