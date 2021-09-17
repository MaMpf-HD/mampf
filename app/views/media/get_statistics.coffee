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
<% if @medium.video.present? %>

ctx = $('#videoStats')
data2=  <%= raw @video_thyme %> || []
$('#videoCount').text(data2.length || 0)
data4=  <%= raw @video_downloads %> || []
$('#downloadCount').text(data4.length || 0)
data3 = data2.map((d)-> {x:new Date(d.x),y:d.y})
data = 
  labels: data2.map((d)-> return d.x)
  datasets: [
    {
      label: 'Thyme'
      backgroundColor: '#4dc9f6'
      borderColor: '#4dc9f6'
      fill: false
      data: data3
    }
    {
      label: 'Downloads'
      backgroundColor: '#990000'
      borderColor: '#990000'
      fill: false
      data: data4
    }
  ]
myChart = new Chart(ctx,
  type: 'line'
  data: data
  options:
    plugins: title:
      text: 'Video'
      display: true
    responsive: true
    maintainAspectRatio: false
    scales:
      x:
        type: 'time'
        time: 
          unit: 'month'
          tooltipFormat: 'DD.MM.'
        title:
          display: true
          text: 'Date'
      y: 
        ticks:
          precision: 0
        title:
          display: true
          text: 'count' )
<% end %>
<% if @medium.manuscript.present? %>

ctx = $('#manuscriptStats')
data21=  <%= raw @manuscript_access %>
$('#manuscriptCount').text(data21.length || 0)
data31 = data21.map((d)-> {x:new Date(d.x),y:d.y})
data = 
  labels: data21.map((d)-> return d.x)
  datasets: [
    {
      label: 'Downloads'
      backgroundColor: '#4dc9f6'
      borderColor: '#4dc9f6'
      fill: false
      data: data31
    }
  ]
myChart = new Chart(ctx,
  type: 'line'
  data: data
  options:
    plugins: title:
      text: 'Manuscript'
      display: true
    responsive: true
    maintainAspectRatio: false
    scales:
      x:
        type: 'time'
        time: 
          unit: 'month'
          tooltipFormat: 'DD.MM.'
        title:
          display: true
          text: 'Date'
      y: 
        ticks:
          precision: 0
        title:
          display: true
          text: 'count' )
<% end %>
$('#statisticsModal').modal('show')