// see https://getdatepicker.com
var datetimePicker = new tempusDominus.TempusDominus(
    document.getElementById('assignment-picker'),
    {
        display: {
            sideBySide: true,
        },
        localization: {
            startOfTheWeek: 1,
            format: 'yyyy-MM-dd HH:mm',
            hourCycle: 'h23',
        }
    }
);

// Catch Tempus Dominus error when user types in invalid date
// see this discussion: https://github.com/Eonasdan/tempus-dominus/discussions/2656
datetimePicker.dates.oldParseInput = datetimePicker.dates.parseInput;
datetimePicker.dates.parseInput = (input) => {
    try {
        return datetimePicker.dates.oldParseInput(input);
    } catch (err) {
        datetimePicker.dates.clear();
    }
};

var isButtonInvokingFocus = false;

// Show datetimepicker when user clicks in text field next to button
// or when input field receives focus
$('#assignment-picker-input').on('click focusin', (e) => {
    try {
        if (!isButtonInvokingFocus) {
            datetimePicker.show();
        }
    }
    finally {
        isButtonInvokingFocus = false;
    }
});

$('#assignment-picker-button').on('click', () => {
    isButtonInvokingFocus = true;
    $('#assignment-picker-input').focus();
});

// Hide datetimepicker when input field loses focus
$('#assignment-picker-input').blur((e) => {
    if (!e.relatedTarget) {
        return;
    }
    datetimePicker.hide();
});
