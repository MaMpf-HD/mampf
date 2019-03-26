# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# update quizzable text for default target selector for remarks

$(document).on 'change', '[id^="default_target_select_"]', ->
  $.ajax Routes.update_vertex_default_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      quiz_id: $(this).data('quizid')
      id: $('#' + this.id + ' option:selected').val()
      vertex_id: $(this).data('vertexid')
    }
    error: (jqXHR, textStatus, errorThrown) ->
      console.log("AJAX Error: #{textStatus}")

# update quizzable text for branching selectors for questions

$(document).on 'change', '[id^="branching_select-"]', ->
    $.ajax Routes.update_branching_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        quiz_id: $(this).data('quizid')
        vertex_id: $(this).val()
        id: this.id
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")

# update quizzable list after quizzable type is selected in new vertex import

$(document).on 'change', '#new_vertex_type_select', ->
  $.ajax Routes.new_vertex_quizzables_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      type: $("#new_vertex_type_select option:selected").val()
    }
    error: (jqXHR, textStatus, errorThrown) ->
      console.log("AJAX Error: #{textStatus}")

# update quizzable text after quizzable is selected in new vertex creation

$(document).on 'change', '#new_vertex_quizzable_select', ->
  $.ajax Routes.new_vertex_quizzable_text_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      type: $("#new_vertex_type_select option:selected").val()
      id: $("#new_vertex_quizzable_select option:selected").val()
    }
    error: (jqXHR, textStatus, errorThrown) ->
      console.log("AJAX Error: #{textStatus}")

# change button 'Ziele ändern' to 'verwerfen' after vertex body is revealed

$(document).on 'shown.bs.collapse', '[id^="collapse-vertex-"]', ->
  $('#targets-vertex-' + $(this).data('vertex')).empty().append('verwerfen')

# change button 'verwerfen' back to 'Ziele ändern' and rerender vertex body
# after vertex body is hidden

$(document).on 'hidden.bs.collapse', '[id^="collapse-vertex-"]', ->
  $.ajax Routes.update_vertex_body_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      vertex_id: $(this).data('vertex')
      quiz_id: $(this).data('quiz')
    }
    error: (jqXHR, textStatus, errorThrown) ->
      console.log("AJAX Error: #{textStatus}")

# render quizzable modal after 'bearbeiten' is clicked in vertex header

$(document).on 'click', '[id^="edit-vertex-content-"]', ->
  $.ajax Routes.fill_quizzable_modal_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      id: $(this).data('id')
      type: $(this).data('type')
    }
    error: (jqXHR, textStatus, errorThrown) ->
      console.log("AJAX Error: #{textStatus}")

# reload current page after quizzable edit modal is closed

$(document).on 'hidden.bs.modal', '#quizzableModal', ->
  location.reload()

# render modal for quizzable duplication dialogue

$(document).on 'click', '#button-reassign', ->
  $.ajax Routes.fill_reassign_modal_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      id: $(this).data('id')
      type: $(this).data('type')
      in_quiz: $('#quiz_id_js').length == 1
      quiz_id: $('#quiz_id_js').attr('value')
    }
    error: (jqXHR, textStatus, errorThrown) ->
      console.log("AJAX Error: #{textStatus}")

# highlight neighbouring vertices rows on mouseenter von neighbour span

$(document).on 'mouseenter', '[id^="neighbours-"]', ->
  neighbours = $(this).data('neighbours')
  id =  $(this).data('id')
  for n in neighbours
    vertex = if n[0] == -1 then id else n[0]
    header = $('#vertex-heading-' + vertex)
    color = $(header).data('color')
    if n[0] == -1
      $(header).removeClass(color).addClass('bg-orange')
    else
      if n[1]
        $(header).removeClass(color).addClass('bg-green-lighten-2')
      else
        $(header).removeClass(color).addClass('bg-red-lighten-2')

# remove highlighting of neighbouring vertices rows on mouseleave of neighbour
# span

$(document).on 'mouseleave', '[id^="neighbours-"]', ->
  neighbours = $(this).data('neighbours')
  id =  $(this).data('id')
  for n in neighbours
    vertex = if n[0] == -1 then id else n[0]
    header = $('#vertex-heading-' + vertex)
    color = $(header).data('color')
    if n[0] == -1
      $(header).removeClass('bg-orange').addClass(color)
    else
      if n[1]
        $(header).removeClass('bg-green-lighten-2').addClass(color)
      else
        $(header).removeClass('bg-red-lighten-2').addClass(color)
