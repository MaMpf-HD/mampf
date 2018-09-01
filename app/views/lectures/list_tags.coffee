$('#lecture-additional-tag-list').empty()
  .append('<%= j render partial: "tags/list",
                          locals: { tags: @additional_tags,
                                    inspection: true } %>')
$('#lecture-disabled-tag-list').empty()
  .append('<%= j render partial: "tags/list",
                          locals: { tags: @disabled_tags,
                                    inspection: true } %>')
