// Initialize on page load (when js file is dynamically loaded)
$(document).ready(startInitialization);

// On page change (e.g. go back and forth in browser)
$(document).on('turbolinks:before-cache', () => {
    // Remove stale datetimepickers
    $('.tempus-dominus-widget').remove();
});

function startInitialization() {
    const pickerElements = $('.td-picker');
    if (pickerElements.length == 0) {
        console.error('No datetimepicker element found on page, although requested.');
        return;
    }

    pickerElements.each((i, element) => {
        element = $(element);
        const datetimePicker = initDatetimePicker(element);
        registerErrorHandlers(datetimePicker, element);
        registerFocusHandlers(datetimePicker, element);
    });
}

function initDatetimePicker(element) {
    // see https://getdatepicker.com
    return new tempusDominus.TempusDominus(
        element.get(0),
        {
            display: {
                sideBySide: true, // clock to the right of the calendar
            },
            localization: {
                startOfTheWeek: 1,
                // choose format to be compliant with backend time format
                format: 'yyyy-MM-dd HH:mm',
                hourCycle: 'h23',
            }
        }
    );
}

function registerErrorHandlers(datetimePicker, element) {
    // Catch Tempus Dominus error when user types in invalid date
    // this is rather hacky at the moment, see this discussion:
    // https://github.com/Eonasdan/tempus-dominus/discussions/2656
    datetimePicker.dates.oldParseInput = datetimePicker.dates.parseInput;
    datetimePicker.dates.parseInput = (input) => {
        try {
            return datetimePicker.dates.oldParseInput(input);
        } catch (err) {
            const errorMsg = element.find('.td-error').data('td-invalid-date');
            element.find('.td-error').text(errorMsg).show();
            datetimePicker.dates.clear();
        }
    };

    datetimePicker.subscribe(tempusDominus.Namespace.events.change, (e) => {
        // see https://getdatepicker.com/6/namespace/events.html#change

        // Clear error message
        if (e.isValid && !e.isClear) {
            element.find('.td-error').empty();
        }

        // If date was selected, close datetimepicker.
        // However: leave the datetimepicker open if user only changed time
        if (e.oldDate && e.date && !hasUserChangedDate(e.oldDate, e.date)) {
            datetimePicker.hide();
        }
    });
}

function hasUserChangedDate(oldDate, newDate) {
    return oldDate.getHours() != newDate.getHours()
        || oldDate.getMinutes() != newDate.getMinutes();
}

function registerFocusHandlers(datetimePicker, element) {
    // Show datetimepicker when user clicks in text field next to button
    // or when input field receives focus
    var isButtonInvokingFocus = false;

    element.find('.td-input').on('click focusin', (e) => {
        try {
            if (!isButtonInvokingFocus) {
                datetimePicker.show();
            }
        }
        finally {
            isButtonInvokingFocus = false;
        }
    });

    element.find('.td-picker-button').on('click', () => {
        isButtonInvokingFocus = true;
        element.find('.td-input').focus();
    });

    // Hide datetimepicker when input field loses focus
    element.find('.td-input').blur((e) => {
        if (!e.relatedTarget) {
            return;
        }
        datetimePicker.hide();
    });
}
