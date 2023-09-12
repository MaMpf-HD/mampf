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

import {
    WidgetInstance
} from "friendly-challenge";
var friendlyChallengeWidgetInstance = WidgetInstance

document.addEventListener("turbolinks:load", function () {
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
            language: $('#captcha-widget').data("lang")
        };
        console.log(options)
        widget = new WidgetInstance(element, options);
        //DO not uncomment, evil
        //    widget.reset();
    }

    // Init Masonry grid system
    // see https://getbootstrap.com/docs/5.0/examples/masonry/
    // and official documentation: https://masonry.desandro.com/
    $('.masonry-grid').masonry({
        percentPosition: true
    });

    checkForNewsPopups();
});

const NEWS_POPUPS_BASE_PATH = '/news_popups/';

function checkForNewsPopups() {
    $.get({
        url: Routes.news_popups_path(),
        type: 'GET',
        dataType: 'json',
        success: (popupNames) => {
            console.log(`Found unread news popups: ${popupNames}`);
            openNewsPopups(popupNames);
        },
        error: (xhr, status) => {
            console.log('ERROR fetching news popups');
            console.log(xhr);
            console.log(status);
        }
    });
}

function openNewsPopups(popupNames) {
    for (const popupName of popupNames) {
        console.log(`Opening news popup: ${popupName}`)
        $.ajax({
            url: NEWS_POPUPS_BASE_PATH + popupName + '.html',
            type: 'GET',
            dataType: 'html',
            success: (html, textStatus, xhr) => {
                console.log(`News popup (${popupName}): ${html}`);
            },
            error: (xhr, status) => {
                console.log(`ERROR getting HTML for news popup: ${popupName}`);
                console.log(xhr);
                console.log(status);
            }
        })
    }
}