# render new lesson form
$('#statistics-modal-content').empty()
  .append('<%= j render partial: "media/statistics",
                        locals: { medium: @medium,
                                  video_downloads: @video_downloads,
                                  video_thyme: @video_thyme,
                                  manuscript_access: @manuscript_access,
                                  quiz_access: @quiz_access,
                                  global_success: @global_success,
                                  question_count: @question_count,
                                  local_success: @local_success } %>').show()

# activate popovers
$('[data-toggle="popover"]').popover()

<% if @medium.sort == 'Quiz' %>
Chart.platform.disableCSSInjection = true;
Chart.defaults.global.elements.rectangle.backgroundColor = 'rgba(255, 99, 132, 0.2)'
Chart.defaults.global.elements.rectangle.borderColor =  'rgba(255, 99, 132, 1)'

ctx = $('#successChart')
myChart = new Chart(ctx,
  type: 'bar'
  data:
    labels: <%= Array(0..@question_count) %>
    datasets: [ {
      label: '<%= t("statistics.number_of_users") %>'
      data: <%= Array(0..@question_count).map { |i| @global_success_details[i].to_i } %>
      borderWidth: 1
      maxBarThickness: 50
    } ]
  options:
    responsive: true
    maintainAspectRatio: false
    scales:
      xAxes:
        [scaleLabel:
          labelString: '<%= t("statistics.number_of_correct_answers") %>'
          display: true]
      yAxes:
        [ticks:
          beginAtZero: true
          precision: 0] )
<% end %>

$('#statisticsModal').modal('show')