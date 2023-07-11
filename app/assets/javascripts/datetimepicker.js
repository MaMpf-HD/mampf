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
});

$('#assignment-picker-input').on('click', () => {
    $('#assignment-picker-button').click();
});
