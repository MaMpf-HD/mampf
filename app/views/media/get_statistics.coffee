# render new lesson form
$('#calls-stats').empty()
  .append('<%= j render partial: "media/statistics",
                        locals: { medium: @medium,
                                  video_downloads: @video_downloads,
                                  video_thyme: @video_thyme,
                                  manuscript_access: @manuscript_access,
                                  quiz_plays: @quiz_plays,
                                  quiz_plays_count: @quiz_plays_count,
                                  quiz_finished_count: @quiz_finished_count,
                                  global_success: @global_success,
                                  question_count: @question_count,
                                  local_success: @local_success } %>')
  .show().removeAttr('style')

# activate popovers
$('[data-toggle="popover"]').popover()

<% if @medium.sort == 'Quiz' %>

  # render new lesson form
  $('#success-stats').empty()
    .append('<%= j render partial: "media/quiz_success_statistics",
                          locals: { medium: @medium,
                                    quiz_finished_count: @quiz_finished_count,
                                    quiz_plays: @quiz_plays,
                                    quiz_plays_count: @quiz_plays_count,
                                    quiz_finished_count: @quiz_finished_count,
                                    global_success: @global_success,
                                    question_count: @question_count,
                                    local_success: @local_success } %>').show().removeAttr('style')

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
        x:
          title:
            display: true
            text: '<%= t("statistics.number_of_correct_answers") %>'
          ticks:
            precision: 0
        y:
          title:
            display: true
            text: '<%= t("statistics.count") %>'
          ticks:
            precision: 0 )

  ctx = $('#quizStats')
  data2=  <%= raw @quiz_plays %> || []
  data3 = data2.map((d)-> {x:new Date(d.x),y:d.y})
  data = 
    labels: data2.map((d)-> return d.x)
    datasets: [
      {
        label: '<%= t("statistics.plays") %>'
        backgroundColor: '#990000'
        borderColor: '#990000'
        fill: false
        data: data3
        showLine: false
      }
    ]
  myChart = new Chart(ctx,
    type: 'line'
    data: data
    options:
      plugins: title:
        text: 'Quiz'
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
            text: '<%= t("statistics.date") %>'
        y: 
          ticks:
            precision: 0
          title:
            display: true
            text: '<%= t("statistics.count") %>' )

<% end %>
<% if @medium.video.present? %>

  ctx = $('#videoStats')
  data2=  <%= raw @video_thyme %> || []
  data4=  <%= raw @video_downloads %> || []
  data3 = data2.map((d)-> {x:new Date(d.x),y:d.y})
  data = 
    labels: data2.map((d)-> return d.x)
    datasets: [
      {
        label: 'Thyme'
        backgroundColor: '#990000'
        borderColor: '#990000'
        fill: false
        data: data3
        showLine: false
      }
      {
        label: 'Downloads'
        backgroundColor: '#4dc9f6'
        borderColor: '#4dc9f6'
        fill: false
        data: data4
        showLine: false
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
        showLine: false
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