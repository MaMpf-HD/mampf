// see https://getdatepicker.com
console.log('trying to import datetimepicker');
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
