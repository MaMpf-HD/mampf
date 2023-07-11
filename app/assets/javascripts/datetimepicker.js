// see https://getdatepicker.com
$('#assignment-picker').tempusDominus({
    display: {
        sideBySide: true
    },
    localization: {
        startOfTheWeek: 1,
        format: 'yyyy-MM-dd HH:mm',
        hourCycle: 'h23'
    }
});

$('#assignment-picker-input').on('click', () => {
    $('#assignment-picker-button').click();
});
