$('.correction-column[data-id="<%= @submission.id %>"]').empty()
  .append('<%= j render partial: "submissions/correction_upload",
                        locals: { submission: @submission } %>')
fileInput = ('upload-correction-<%= @submission.id %>')
uploadButton = ('#correction-uploadButton-button-<%= @submission.id %>')
informer = ('upload-correction-informer-<%= @submission.id %>')
statusBar = ('upload-correction-statusBar-<%= @submission.id %>')
hiddenInput = 'upload-correction-hidden-<%= @submission.id %>'
metaData = document.getElementById('upload-correction-metadata-<%= @submission.id %>')
actualButton = "#correction-uploadButton-button-actual-<%= @submission.id%>"
correctionUpload(fileInput, uploadButton, informer, statusBar, hiddenInput, metaData,actualButton)