# converts a given number a of bytes to a humanreadble form with KB/MB etc.,
# keeping b decimal digits
formatBytes = (a, b) ->
  if 0 == a
    return '0 Bytes'
  c = 1024
  d = b or 2
  e = [
    'Bytes'
    'KB'
    'MB'
    'GB'
    'TB'
    'PB'
    'EB'
    'ZB'
    'YB'
  ]
  f = Math.floor(Math.log(a) / Math.log(c))
  parseFloat((a / c ** f).toFixed(d)) + ' ' + e[f]

# converts a given time in seconds to a string of the form **h**m**s
fancyTimeFormat = (time) ->
  hrs = Math.floor(time / 3600)
  mins = Math.floor(time % 3600 / 60)
  secs = time % 60
  output = ''
  output += '' + hrs + 'h' + (if mins < 10 then '0' else '')
  output += '' + mins + 'm' + (if secs < 10 then '0' else '')
  output += '' + secs + 's'
  output

videoUpload = (fileInput) ->
  # set everything up
  videoPreviewArea = document.getElementById('video-preview-area')
  videoPreview = document.getElementById('video-preview')
  uploadArea = document.getElementById('video-uploadArea')
  uploadButton = document.getElementById('video-uploadButton')
  informer = document.getElementById('video-informer')
  progressBar = document.getElementById('video-progressBar')
  metaData = document.getElementById('video-meta')
  hiddenInput = document.getElementById('upload-video-hidden')

  # uppy will add its own file input
  fileInput.style.display = 'none'

  # create uppy istance
  uppy = Uppy.Core(
    id: fileInput.id
    autoProceed: true
    restrictions: allowedFileTypes: [
      '.mp4'
      '.webm'
      '.ogg'
    ])
  uppy.use(Uppy.FileInput,
           target: uploadButton
           locale: strings: chooseFiles: uploadButton.dataset.choosefiles)
  uppy.use(Uppy.Informer, target: informer)
  uppy.use(Uppy.ProgressBar, target: progressBar)


  # target the endpoint for shrine uploader
  # timeout has been increased from standard value to allow storing of large
  # files
  uppy.use Uppy.XHRUpload,
    endpoint: '/videos/upload'
    fieldName: 'file'
    timeout: 240 * 1000

  # give the user feedback after upload has started
  uppy.on 'upload', (data) ->
    $('#video-wait').show()
    $('#medium-basics-warning').show()
    return

  # add metadata to video card if upload was successful
  uppy.on 'upload-success', (file, response) ->
    $('#video-wait').hide()
    data = response.body
    if data.metadata.mime_type in ['video/mp4']
      # read uploaded file data from the upload endpoint response
      uploadedFileData = JSON.stringify(data)

      # set hidden field value to the uploaded file data so that it is
      # submitted with the form as the attachment
      hiddenInput.value = uploadedFileData

      videoFile = document.getElementById('video-file')
      videoSize = document.getElementById('video-size')

      # put metadata into place
      videoFile.innerHTML = data.metadata.filename
      videoSize.innerHTML = formatBytes(data.metadata.size)
      $(metaData).show()
      $(videoPreviewArea).show()
      $('#medium_detach_video').val('false')
      $('#medium-basics-warning').show()
    else
      # display error message if uppy detects wrong mime type
      uppy.info('Falscher MIME-Typ:' + data.metadata.mime_type, 'error', 5000)
      uppy.reset()
    return

  # display error message on console if an upload error has ocurred
  uppy.on 'upload-error', (file, error) ->
    console.log('error with file:', file.id)
    console.log('error message:', error)
    return

  uppy

manuscriptUpload = (fileInput) ->
  # set everything up
  uploadArea = document.getElementById('manuscript-uploadArea')
  uploadButton = document.getElementById('manuscript-uploadButton')
  informer = document.getElementById('manuscript-informer')
  progressBar = document.getElementById('manuscript-progressBar')
  metaData = document.getElementById('manuscript-meta')
  hiddenInput = document.getElementById('upload-manuscript-hidden')

  # uppy will add its own file input
  fileInput.style.display = 'none'

  # create uppy instance
  uppy = Uppy.Core(
    id: fileInput.id
    autoProceed: true
    restrictions: allowedFileTypes: [ '.pdf' ])
    .use(Uppy.FileInput,
      target: uploadButton
      locale: strings: chooseFiles: uploadButton.dataset.choosefiles)
    .use(Uppy.Informer, target: informer)
    .use(Uppy.ProgressBar, target: progressBar)

  # target the endpoint for shrine uploader
  uppy.use Uppy.XHRUpload,
    endpoint: '/pdfs/upload'
    fieldName: 'file'

  # add metadata to manuscript card if upload was successful
  uppy.on 'upload-success', (file, response) ->
    data = response.body
    if data.metadata.mime_type == 'application/pdf' && data.metadata.pages != null
      # read uploaded file data from the upload endpoint response
      uploadedFileData = JSON.stringify(data)
      # set hidden field value to the uploaded file data so that it is
      # submitted with the form as the attachment
      hiddenInput.value = uploadedFileData

      manuscriptFile = document.getElementById('manuscript-file')
      manuscriptSize = document.getElementById('manuscript-size')
      manuscriptPages = document.getElementById('manuscript-pages')

      # put metadata into place
      manuscriptFile.innerHTML = data.metadata.filename
      manuscriptSize.innerHTML = formatBytes(data.metadata.size)
      manuscriptPages.innerHTML = data.metadata.pages + ' S'
      $('#manuscript-destinations').empty().hide()
      $('#medium-manuscript-destinations').empty().hide()
      $('#manuscript-meta').show()
      $('#manuscript-preview').hide()
      $('#medium_detach_manuscript').val('false')
      $('#medium-basics-warning').show()
    else if data.metadata.mime_type != 'application/pdf'
      # display error message if uppy detects wrong mime type
      uppy.info('Falscher MIME-Typ:' + data.metadata.mime_type, 'error', 5000)
      uppy.reset()
    else
      # display error message if uppy detects some other problem
      uppy.info('Die Datei ist beschädigt.', 'error', 5000)
      uppy.reset()
    return

  # display error message on console if an upload error has ocurred
  uppy.on 'upload-error', (file, error) ->
    console.log('error with file:', file.id)
    console.log('error message:', error)
    return

  uppy

geogebraUpload = (fileInput) ->
  # set everything up
  uploadArea = document.getElementById('geogebra-uploadArea')
  uploadButton = document.getElementById('geogebra-uploadButton')
  informer = document.getElementById('geogebra-informer')
  progressBar = document.getElementById('geogebra-progressBar')
  metaData = document.getElementById('geogebra-meta')
  hiddenInput = document.getElementById('upload-geogebra-hidden')

  # uppy will add its own file input
  fileInput.style.display = 'none'

  # create uppy instance
  uppy = Uppy.Core(
    id: fileInput.id
    autoProceed: true
    restrictions: allowedFileTypes: [ '.ggb' ])
    .use(Uppy.FileInput,
      target: uploadButton
      locale: strings: chooseFiles: uploadButton.dataset.choosefiles)
    .use(Uppy.Informer, target: informer)
    .use(Uppy.ProgressBar, target: progressBar)

  # target the endpoint for shrine uploader
  uppy.use Uppy.XHRUpload,
    endpoint: '/ggbs/upload'
    fieldName: 'file'

  # add metadata to manuscript card if upload was successful
  uppy.on 'upload-success', (file, response) ->
    data = response.body
    if data.metadata.mime_type == 'application/zip'
      # read uploaded file data from the upload endpoint response
      uploadedFileData = JSON.stringify(data)

      # set hidden field value to the uploaded file data so that it is
      # submitted with the form as the attachment
      hiddenInput.value = uploadedFileData

      geogebraFile = document.getElementById('geogebra-file')
      geogebraSize = document.getElementById('geogebra-size')

      # put metadata into place
      geogebraFile.innerHTML = data.metadata.filename
      geogebraSize.innerHTML = formatBytes(data.metadata.size)
      $('#geogebra-meta').show()
      $('#medium_detach_geogebra').val('false')
      $('#medium-basics-warning').show()
    else if data.metadata.mime_type != 'application/zip'
      # display error message if uppy detects wrong mime type
      uppy.info('Falscher MIME-Typ:' + data.metadata.mime_type, 'error', 5000)
      uppy.reset()
    else
      # display error message if uppy detects some other problem
      uppy.info('Die Datei ist beschädigt.', 'error', 5000)
      uppy.reset()
    return

  # display error message on console if an upload error has ocurred
  uppy.on 'upload-error', (file, error) ->
    console.log('error with file:', file.id)
    console.log('error message:', error)
    return

  uppy

imageUpload = (fileInput) ->
  # set everything up
  uploadArea = document.getElementById('image-uploadArea')
  uploadButton = document.getElementById('image-uploadButton')
  informer = document.getElementById('image-informer')
  progressBar = document.getElementById('image-progressBar')
  metaData = document.getElementById('image-meta')
  hiddenInput = document.getElementById('upload-image-hidden')
  imagePreview = document.getElementById('image-preview')

  # uppy will add its own file input
  fileInput.style.display = 'none'

  # create uppy instance
  uppy = Uppy.Core(
    id: fileInput.id
    autoProceed: true
    restrictions: allowedFileTypes: [
      '.png'
      '.jpg'
      '.gif'
    ])
    .use(Uppy.FileInput,
      target: uploadButton
      locale: strings: chooseFiles: uploadButton.dataset.choosefiles)
    .use(Uppy.Informer, target: informer)
    .use(Uppy.ProgressBar, target: progressBar)

  # target the endpoint for shrine uploader
  uppy.use Uppy.XHRUpload,
    endpoint: '/screenshots/upload'
    fieldName: 'file'

  # add metadata to manuscript card if upload was successful
  uppy.on 'upload-success', (file, response) ->
    data = response.body
    if data.metadata.mime_type in ['image/png', 'image/jpeg', 'image/gif']
      # read uploaded file data from the upload endpoint response
      uploadedFileData = JSON.stringify(data)

      # set hidden field value to the uploaded file data so that it is
      # submitted with the form as the attachment
      hiddenInput.value = uploadedFileData

      #show image preview
      imagePreview.src = URL.createObjectURL(file.data)

      imageFile = document.getElementById('image-file')
      imageSize = document.getElementById('image-size')
      imageResolution = document.getElementById('image-resolution')

      # put metadata into place
      imageFile.innerHTML = data.metadata.filename
      imageSize.innerHTML = formatBytes(data.metadata.size)
      imageResolution.innerHTML = data.metadata.width + 'x' + data.metadata.height
      $(metaData).show()
      $(imagePreview).show()
      $('#course_detach_image').val('false')
      $('#course-basics-warning').show()
      $('#image-none').hide()
    else
      # display error message if uppy detects wrong mime type
      uppy.info('Falscher MIME-Typ:' + data.metadata.mime_type, 'error', 5000)
      uppy.reset()
    return

  # display error message on console if an upload error has ocurred
  uppy.on 'upload-error', (file, error) ->
    console.log('error with file:', file.id)
    console.log('error message:', error)
    return

  uppy

@correctionUpload = (fileInput, uploadButton, informer, statusBar, hiddenInput, metaData) ->
  # uppy will add its own file input
  fileInput.style.display = 'none'
  allowedInput = fileInput.dataset.accept

  # create uppy instance
  uppy = Uppy.Core(
    id: fileInput.id
    autoProceed: true
    restrictions:
      maxFileSize: 30*1024*1024)
    .use(Uppy.FileInput,
      target: uploadButton
      locale: strings: chooseFiles: uploadButton.dataset.choosefiles)
    .use(Uppy.Informer, target: informer)
    .use(Uppy.StatusBar, target: statusBar)

  # target the endpoint for shrine uploader
  uppy.use Uppy.XHRUpload,
    endpoint: '/corrections/upload'
    fieldName: 'file'

  # add metadata to manuscript card if upload was successful
  uppy.on 'upload-success', (file, response) ->
    data = response.body
    # read uploaded file data from the upload endpoint response
    uploadedFileData = JSON.stringify(data)

    # set hidden field value to the uploaded file data so that it is
    # submitted with the form as the attachment
    hiddenInput.value = uploadedFileData

    metaData.innerHTML = data.metadata.filename + ' (' + formatBytes(data.metadata.size) + ')'
    metaData.style.display = 'inline'
    return

  # display error message on console if an upload error has ocurred
  uppy.on 'upload-error', (file, error) ->
    console.log('error with file:', file.id)
    console.log('error message:', error)
    return

  uppy

bulkCorrectionUpload = (fileInput) ->

  uploadButton = document.getElementById('upload-bulk-correction-button')
  informer = document.getElementById('upload-bulk-correction-informer')
  statusBar = document.getElementById('upload-bulk-correction-statusBar')
  hiddenInput = document.getElementById('upload-bulk-correction-hidden')
  metaData = document.getElementById('upload-bulk-correction-metadata')
  fileCount = 0

  # uppy will add its own file input
  fileInput.style.display = 'none'

  # create uppy instance
  uppy = Uppy.Core(
    id: fileInput.id
    autoProceed: true
    allowMultipleUploads: false
    restrictions:
      maxFileSize: 30*1024*1024)
    .use(Uppy.FileInput,
      target: uploadButton
      locale: strings: chooseFiles: uploadButton.dataset.choosefiles)
    .use(Uppy.Informer, target: informer)
    .use(Uppy.StatusBar, target: statusBar)

  # target the endpoint for shrine uploader
  uppy.use Uppy.XHRUpload,
    endpoint: '/packages/upload'
    fieldName: 'file'

  # display error message on console if an upload error has ocurred
  uppy.on 'upload-error', (file, error) ->
    console.log('error with file:', file.id)
    console.log('error message:', error)
    return

  uppy.on 'complete', (result) ->
    console.log('successful files:', result.successful)
    console.log('failed files:', result.failed)
    if result.successful.length > 0
      uploaded_files = result.successful.map (file) -> file.response.body
      console.log uploaded_files
      hiddenInput.value = JSON.stringify(uploaded_files)
      $('#upload-bulk-correction-save').prop('disabled', false)
      $(metaData).empty()
        .append(result.successful.length + ' ' +$(metaData).data('tr-uploads'))
      $(uploadButton).hide()
    return

  $('#cancel-bulk-upload').on 'click', ->
    clearBulkUploadArea()
    uppy.reset()
    return

  $('#show-bulk-upload-area').on 'click', ->
    $(this).hide()
    uppy.reset()
    $('#upload-bulk-correction-button').show()
    $('#bulk-upload-area').show()
    return

  uppy


###
@param fileInput: dom element to listen to.
###
@result = undefined
@userManuscriptUpload = (fileInput) ->
  # update helpdesk
  $('[data-toggle="popover"]').popover()
  hiddenInput = document.getElementById('upload-userManuscript-hidden')
  hiddenInput2 = document.getElementById('upload-userManuscript-hidden2')
  fileInput.style.display = 'none'
  result = undefined
  merged = undefined
  newFile = false
  files = []
  filez= []
  progressOptimize = 0
  $('#userManuscript-status').hide()
  uploadButton = $('#userManuscript-uploadButton-btn')
  swapInFiles = (i,j,r) ->
    return () ->
      x = filez[i]
      filez[i] = filez[j]
      filez[j] = x
      r()
  renderMultipleFiles = ->
    i =0
    $("#files-display").empty()
    console.log filez
    for f in filez
      fDisplay = $("<li>"+f.name+"</li>")
      if i!=0
        toggleUp = $("<button class='btn fas fa-sort-up'></button>")
        toggleUp.on 'click', swapInFiles(i-1,i,renderMultipleFiles)
        fDisplay.append(toggleUp)
      if i!= filez.length-1
        toggleDown = $("<button class='btn fas fa-sort-down'></button>")
        toggleDown.on 'click', swapInFiles(i,i+1,renderMultipleFiles)
        fDisplay.append(toggleDown)
      $("#files-display").append(fDisplay)
      console.log(i)
      i++

  renderOptimization = (file) ->
    $('#multiple-files-selected').hide()
    $('#files-merge').hide()
    name= file.name
    if file.name == undefined
      name =[f.name for f in filez].join(".")
    $("#userManuscriptMetadata").text(name+"("+formatBytes(file.size)+")")
    # rerender all
    $("#removeUserManuscript").hide()
    $('#userManuscript-status').show(400)
    $('#file-permission-field').show()
    $('#submission-final-upload-dialogue').show()
    $('#file-size-correct').hide()
    $('#file-size-way-too-big').hide()
    $('#file-size-too-big').hide()
    $('#file-optimize').hide()
    $('#userManuscript-upload-notice').hide()
    $('#userManuscript-uploadButton-call').prop('disabled',true)
    if file.size < 5000000
      $('#userManuscript-uploadButton-call').prop('disabled',false)
      $('#file-size-correct').show()
      $('#userManuscript-uploadCenter').show()
      $('#userManuscript-uploadButton-call')
        .removeClass('btn-outline-secondary')
        .addClass 'btn-primary'
    else if file.type == 'application/pdf'
      if file.size > 20000000
        $('#file-size-way-too-big').show()
      else
        $('#file-size-too-big').show()
        $('#userManuscript-uploadButton-call').prop('disabled',false)
      $('#file-optimize').show()
    else
      $('#file-size-way-too-big').show()
      $('#file-permission-field').hide()
      $('#submission-final-upload-dialogue').hide()

  $('#userManuscript-uploadButton-call').on 'click', (e) ->
    e.preventDefault()
    if merged != undefined && result == undefined
      result = merged
    if result== undefined || newFile
      result =document.getElementById('upload-userManuscript').files[0]
    if $("#file-permission-checkbox").is(":checked")
      #Upload blob
      formData = new FormData()
      name =[f.name for f in filez].join(".")
      formData.append("file", result, name)
      xhr = new XMLHttpRequest()
      xhr.open('POST', '/submissions/upload', true)
      xhr.onload =  () ->
        if (xhr.status == 200)
          hiddenInput.value = xhr.responseText
          $('#upload-userManuscript').val("")
          $('input[type="submit"]').prop('disabled',false)
          $('#userManuscript-upload-notice').show()
          $('#userManuscript-not-upload-notice').hide()
          $('#submission_detach_user_manuscript').val('false')
          $('#userManuscript-uploadButton-call').text(
            $('#userManuscript-uploadButton-call').data 'tr-success'
          )
          $('#userManuscript-uploadButton-call')
              .removeClass('btn-primary')
              .addClass 'btn-outline-secondary'
        else
          alert(
            $('#userManuscript-uploadButton-call').data('tr-failure')
            + xhr.responseText
          )
      xhr.onerror = (e) ->
        alert(
          $('#userManuscript-uploadButton-call').data('tr-failure')
        )
      xhr.upload.onprogress = (e) ->
        percentUpload = Math.floor(100 * e.loaded / e.total)
        $('#userManuscript-uploadButton-call').text(percentUpload+" %")
        return
      xhr.send formData
    else
      alert(
        $('#userManuscript-uploadButton-call').data 'tr-missing-consent'
      )

  $("#log-btn").on 'click',() ->
    $("#userManuscript-optimize-log").toggle()
  $("#log-merge-btn").on 'click',() ->
    $("#userManuscript-merge-log").toggle()
  $('#userManuscript-merge-btn').on 'click',(e) ->
    e.preventDefault()
    newFile = false

    workingText = $('#userManuscript-merge-btn').data('tr-working')
    $('#userManuscript-merge-btn').text(workingText)
    $('#userManuscript-merge-btn').prop("disabled", true)
    $('#userManuscript-merge-btn').removeClass('btn-primary')
    .addClass 'btn-outline-secondary'

    reader = new FileReader()
    readFileIntoFiles = ->
      if @result
        arrayBuffer = @result
        array = new Uint8Array(arrayBuffer)
        console.log files.push(array)
        reader.onload = readFileIntoFiles
        if files.length < filez.length
          reader.readAsArrayBuffer filez[files.length]
        else
          worker = new Worker('/pdfcomprezzor/worker.js')
          worker.addEventListener 'message', ((e) ->
            console.log(e.data)
            if e.data.type == 'log'
              $('#userManuscript-merge-btn').html(
                workingText +
                ".".repeat(progressOptimize + 1) +
                "&nbsp;".repeat(2-progressOptimize)
              )
              progressOptimize = (progressOptimize+1)%3
              $('#userManuscript-merge-log').append(
                $("<div><small>" + e.data.message + "</div></small>")
              )
            if e.data.type == "result"
              merged = new Blob([e.data.result], type: 'application/pdf')
              $('#merging-help-text').hide()
              renderOptimization(merged)
          ), false
          action = if files.length > 1 then 'merge' else 'compress'
          r = worker.postMessage(
            array: files
            action: action)
      return
    reader.onload = readFileIntoFiles
    reader.readAsArrayBuffer(filez[0])

  $('#userManuscript-optimize-btn').on 'click',(e) ->
    e.preventDefault()
    newFile = false
    file = document.getElementById('upload-userManuscript').files[0]
    console.log file
    workingText = $('#userManuscript-optimize-btn').data('tr-working')
    $('#userManuscript-optimize-btn').text(workingText)
    $('#userManuscript-optimize-btn').prop("disabled", true)
    $('#userManuscript-optimize-btn').removeClass('btn-primary')
    .addClass 'btn-outline-secondary'

    reader = new FileReader()
    reader.onload = () ->
      arrayBuffer = this.result
      array = new Uint8Array(arrayBuffer)
      worker = new Worker('/pdfcomprezzor/worker.js')
      worker.addEventListener 'message', ((e) ->
        console.log 'Worker said: ', e
        if e.data.type == 'log'
          $('#userManuscript-optimize-btn').html(
            workingText +
            ".".repeat(progressOptimize + 1) +
            "&nbsp;".repeat(2-progressOptimize)
          )
          progressOptimize = (progressOptimize+1)%3
          $('#userManuscript-optimize-log').append(
            $("<div><small>" + e.data.message + "</div></small>")
          )
        else if e.data.type == 'result'
          $('#userManuscript-optimize-btn').text(
            formatBytes(e.data.result.length)
          )
          result = new Blob([e.data.result], type: 'application/pdf')
          $('#optimization-help-text').hide()
          if e.data.result.length> 20000000
            alert(
              $('#userManuscript-optimize-btn').data 'tr-failed'
            )
          else
            $('#userManuscript-uploadButton-call').prop('disabled',false)
            name =[f.name for f in filez].join(".")
            $("#userManuscriptMetadata").text(
              name + "(" + formatBytes(result.size) + ")"
            )
            $('#userManuscript-uploadButton-call')
              .removeClass('btn-outline-secondary')
              .addClass 'btn-primary'
            $('#file-size-correct').show()
            $('#file-size-way-too-big').hide()
            $('#file-size-too-big').hide()
        return
      ), false
      worker.postMessage
        array: [array]
    if merged
      reader.readAsArrayBuffer(merged)
    else
      reader.readAsArrayBuffer(file)

  $('#upload-userManuscript').change () ->
    $('#userManuscript-uploadButton-call').text $('#userManuscript-uploadButton-call').data('tr-upload')
    newFile = true
    $('#userManuscript-not-upload-notice').show()
    $('input[type="submit"]').prop('disabled',true)
    filez = Array.prototype.slice.call(
        document.getElementById('upload-userManuscript').files
      )
    if this.files.length > 1
      $('#userManuscript-status').show(400)
      $('#multiple-files-selected').show()
      $('#files-merge').show()
      $('#file-size-correct').hide()
      $('#file-size-way-too-big').hide()
      $('#file-size-too-big').hide()
      $('#file-optimize').hide()
      renderMultipleFiles()
    else
      renderOptimization(this.files[0])
      merged = undefined

  uploadButton.on 'click', (e) ->
    e.preventDefault()
    $('#upload-userManuscript').trigger('click')

$(document).on 'turbolinks:load', ->
  video = document.getElementById('upload-video')
  manuscript = document.getElementById('upload-manuscript')
  geogebra = document.getElementById('upload-geogebra')
  image = document.getElementById('upload-image')
  bulkCorrection = document.getElementById('upload-bulk-correction')

  # make uppy idempotent for turbolinks
  $('.uppy').remove()
  $('.uppy-Root').remove()

  # initialize uppy
  videoUpload video if video?
  manuscriptUpload manuscript if manuscript?
  geogebraUpload geogebra if geogebra?
  imageUpload image if image?
  bulkCorrectionUpload bulkCorrection if bulkCorrection?

  # make uppy upload buttons look like bootstrap
  $('.uppy-FileInput-btn').removeClass('uppy-FileInput-btn')
  .addClass('btn btn-sm btn-outline-secondary')
  return
