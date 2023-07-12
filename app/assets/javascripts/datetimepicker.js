$(document).ready(function () {

    // see https://getdatepicker.com
    var datetimePicker = new tempusDominus.TempusDominus(
        // currently, we only support one datetimepicker on a page
        document.getElementsByClassName('td-picker')[0],
        {
            display: {
                sideBySide: true,
            },
            localization: {
                startOfTheWeek: 1,
                // choose format to be compliant with backend time format
                format: 'yyyy-MM-dd HH:mm',
                hourCycle: 'h23',
            }
        }
    );

    // Catch Tempus Dominus error when user types in invalid date
    // this is rather hacky at the moment, see this discussion:
    // https://github.com/Eonasdan/tempus-dominus/discussions/2656
    datetimePicker.dates.oldParseInput = datetimePicker.dates.parseInput;
    datetimePicker.dates.parseInput = (input) => {
        try {
            return datetimePicker.dates.oldParseInput(input);
        } catch (err) {
            const errorMsg = $('.td-error').data('td-invalid-date');
            $('.td-error').text(errorMsg).show();
            datetimePicker.dates.clear();
        }
    };

    datetimePicker.subscribe(tempusDominus.Namespace.events.change, (e) => {
        // see https://getdatepicker.com/6/namespace/events.html#change
        if (e.isValid && !e.isClear) {
            $('.td-error').empty();
            datetimePicker.hide();
        }
    });

    // Show datetimepicker when user clicks in text field next to button
    // or when input field receives focus
    var isButtonInvokingFocus = false;

    $('.td-input').on('click focusin', (e) => {
        try {
            if (!isButtonInvokingFocus) {
                datetimePicker.show();
            }
        }
        finally {
            isButtonInvokingFocus = false;
        }
    });

    $('.td-picker-button').on('click', () => {
        isButtonInvokingFocus = true;
        $('.td-input').focus();
    });

    // Hide datetimepicker when input field loses focus
    $('.td-input').blur((e) => {
        if (!e.relatedTarget) {
            return;
        }
        datetimePicker.hide();
    });

});