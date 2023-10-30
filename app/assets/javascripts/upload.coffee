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

  fileInput.style.display = 'none'
  @directUpload(
    "upload-video"
    "#video-uploadButton-button-actual"
    '#video-uploadButton-button'
    "#video-uploadButton-button-actual"   
    null
    '/videos/upload'
    "#video-uploadButton-button-actual"
    (data)->
      data = JSON.parse data.response
      $('#video-wait').hide()
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
        # display error message if  detects wrong mime type
        alert('Falscher MIME-Typ:' + data.metadata.mime_type)
        $("#video-uploadButton-button-actual").text "Falscher MIME-Typ:" + data.metadata.mime_type
      return
    null
    'upload-video-hidden'
    true
  )

manuscriptUpload = (fileInput) ->
  # set everything up
  uploadArea = ('manuscript-uploadArea')
  uploadButton = ('#manuscript-uploadButton-button')
  informer = ('manuscript-informer')
  progressBar = ('manuscript-progressBar')
  metaData = ('manuscript-meta')
  hiddenInput = ('upload-manuscript-hidden')
  return if document.getElementById(fileInput) == null
  @directUpload(
    fileInput
    "#manuscript-uploadButton-button-actual"
    '#manuscript-uploadButton-button'
    "#manuscript-uploadButton-button-actual"   
    null
    '/pdfs/upload'
    "#manuscript-uploadButton-button-actual"
    (data)->
      console.log data
      data = JSON.parse data.response
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
        # display error message if  detects wrong mime type
        alert('Falscher MIME-Typ:' + data.metadata.mime_type, 'error', 5000)
        $("#manuscript-uploadButton-button-actual").text "Falscher MIME-Typ:" + data.metadata.mime_type
      else
        # display error message if  detects some other problem
        alert('Die Datei ist beschädigt.', 'error', 5000)
        $("#manuscript-uploadButton-button-actual").text "Datei beschädigt."
      return
    null
    hiddenInput
    true
  )


geogebraUpload = (fileInput) ->
  # set everything up
  uploadArea = document.getElementById('geogebra-uploadArea')
  uploadButton = document.getElementById('geogebra-uploadButton')
  informer = document.getElementById('geogebra-informer')
  progressBar = document.getElementById('geogebra-progressBar')
  metaData = document.getElementById('geogebra-meta')
  hiddenInput = document.getElementById('upload-geogebra-hidden')
  @directUpload(
    "upload-geogebra"
    "#geogebra-uploadButton-button-actual"
    '#geogebra-uploadButton-button'
    "#geogebra-uploadButton-button-actual"   
    null
    '/ggbs/upload'
    "#geogebra-uploadButton-button-actual"
    (data)->
      console.log data
      data = JSON.parse data.response
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
        alert('Falscher MIME-Typ:' + data.metadata.mime_type, 'error', 5000)
        $("#geogebra-uploadButton-button-actual").text "Falscher MIME-Typ:" + data.metadata.mime_type
      else
        alert('Die Datei ist beschädigt.', 'error', 5000)
      return
    null
    'upload-geogebra-hidden'
    true
  )

imageUpload = (fileInput,endpoint='/screenshots/upload', classname="course") ->
  # set everything up
  uploadArea = document.getElementById('image-uploadArea')
  uploadButton = document.getElementById('image-uploadButton')
  informer = document.getElementById('image-informer')
  progressBar = document.getElementById('image-progressBar')
  metaData = document.getElementById('image-meta')
  hiddenInput = document.getElementById('upload-image-hidden')
  imagePreview = document.getElementById('image-preview')

  fileInput.style.display = 'none'
  actualButton = '#image-uploadButton-button-actual'
  uploadButton = '#image-uploadButton-button'
  directUpload(
    'upload-image'
    actualButton
    uploadButton
    actualButton
    null
    endpoint
    actualButton
    (xhr) =>
      file = fileInput.files[0]
      console.log(file)
      data = JSON.parse xhr.response
      if data.metadata.mime_type in ['image/png', 'image/jpeg', 'image/gif']
        # read uploaded file data from the upload endpoint response
        uploadedFileData = JSON.stringify(data)

        # set hidden field value to the uploaded file data so that it is
        # submitted with the form as the attachment
        hiddenInput.value = uploadedFileData

        #show image preview
        imagePreview.src = URL.createObjectURL(file)

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
        $('#'+classname+'-basics-warning').show()
        $('#image-none').hide()
      else
        alert('Falscher MIME-Typ:' + data.metadata.mime_type)
        $("#image-uploadButton-button-actual").text "Falscher MIME-Typ:" + data.metadata.mime_type
        
    null
    'upload-image-hidden'
    true
    )

@correctionUpload = (fileInput, uploadButton, informer, statusBar, hiddenInput, metaData,actualButton) ->
  $("#"+fileInput).hide()
  directUpload(
    fileInput
    actualButton
    uploadButton
    actualButton
    null
    '/corrections/upload'
    actualButton
    (data) =>
      data = JSON.parse data.response
        # read uploaded file data from the upload endpoint response
      uploadedFileData = JSON.stringify(data[0])

      # set hidden field value to the uploaded file data so that it is
      # submitted with the form as the attachment (done by directUpload), using single option =  true

      metaData.innerHTML = data.metadata.filename + ' (' + formatBytes(data.metadata.size) + ')'
      metaData.style.display = 'inline'

      # Disable upload if empty files were uploaded
      # Temporary fix for ":type option required" error in the
      # app/controllers/submissions_controller.rb -> show_correction
      if data.metadata.size == 0
        console.log('empty file encountered')
        $(actualButton).hide()
        $('#submit-correction-btn').addClass('disabled')
        alert($(actualButton).data('tr-failure-empty-file'))
      else
        $(uploadButton).hide()
        $(actualButton).show()
        $(actualButton).addClass('disabled')
        $('#submit-correction-btn').removeClass('disabled')
      
    null
    hiddenInput
    true
    )

bulkCorrectionUpload = (fileInput) ->

  uploadButton = document.getElementById('upload-bulk-correction-button')
  informer = document.getElementById('upload-bulk-correction-informer')
  statusBar = document.getElementById('upload-bulk-correction-statusBar')
  hiddenInput = document.getElementById('upload-bulk-correction-hidden')
  metaData = document.getElementById('upload-bulk-correction-metadata')
  fileCount = 0

  fileInput.style.display = 'none'
  directUpload(
      'upload-bulk-correction'
      '#bulk-uploadButton-button-actual'
      '#bulk-uploadButton-button'
      '#bulk-uploadButton-button-actual'
      null
      '/corrections/upload'
      '#bulk-uploadButton-button-actual'
      (_, dataAll) =>
        console.log(dataAll)

        if dataAll.length == 0
          console.error('No files uploaded, fatal error')
          return

        # Disable upload if uploaded (zip)-file is empty
        # Temporary fix for ":type option required" error in the
        # app/controllers/submissions_controller.rb -> show_correction
        fileSizes = dataAll.map((data) => data.metadata.size)
        if fileSizes.includes(0)
          console.log('empty file encountered during bulk upload')
          alert($('#bulk-uploadButton-button-actual').data('tr-failure-empty-file'))
          $('#bulk-uploadButton-button-actual').hide()
          $(metaData).empty()
          return

        # Successfully uploaded
        console.log('bulk upload successful')
        $('#upload-bulk-correction-save').prop('disabled', false)
        $(metaData).empty()
          .append(fileInput.files.length+ ' ' +$(metaData).data('tr-uploads'))
        $(uploadButton).hide()
      null
      'upload-bulk-correction-hidden'
      false
      )
  $('#show-bulk-upload-area').on 'click', ->
    $(this).hide()
    $('#upload-bulk-correction-button').show()
    $('#bulk-upload-area').show()
    return


###
directUpload provides an interface to upload (multiple) files to an endpoint

@param fileInputElement name of the file element that is hidden and this all is 
       based on.
@param uploadStatusElement name of the element were the upload status is posted
@param uploadButtonElement name of the button were the upload is triggered
@param actualUploadButtonElement name of the button that triggers the upload
@param permissionElement checkbox to be confirmed (optional,  null for skip)
@param endpoint place to put the files '/submissions/upload'
@param progressBarElement element to write percentage in.
       requires data attribute tr-success,tr-failure, tr-missing-consent
@param successCallback will be called, if request was sucessful (optional)
@param fileChangeCallBack will be called, if selected files have changed
@param single true if only one file is uploaded
###
@directUpload = (
  fileInputElement
  uploadStatusElement
  uploadButtonElement
  actualUploadButtonElement
  permissionElement
  endpoint
  progressBarElement
  successCallback
  fileChangeCallBack
  hiddenInputElement
  single
  ) ->
    initBootstrapPopovers()
    hiddenInput = document.getElementById(hiddenInputElement)
    hiddenInput2 = document.getElementById('upload-userManuscript-hidden2')
    fileInput =document.getElementById(fileInputElement)
    fI = $("#"+fileInputElement)
    fileInput.style.display = 'none'
    
    $(uploadStatusElement).hide()
    uploadButton = $(uploadButtonElement)
    $(actualUploadButtonElement).on 'click', (e) ->
      # Reset variables
      result = undefined
      merged = undefined
      files = []
      filez= []
      uploadedFiles = []
      progressOptimize = 0
      hiddenInput.value = ''

      e.preventDefault()
      if permissionElement == null || $(permissionElement).is(":checked")
        #Upload blob
        i=0
        xhr = new XMLHttpRequest()
        onerror = (e) ->
          console.log(e)
          alert(
            $(progressBarElement).data('tr-failure')
          )
        onprogress = (e) ->
            percentUpload = Math.floor(100/fileInput.files.length * e.loaded / e.total+100*(i)/fileInput.files.length)
            $(progressBarElement).text(percentUpload+" %")
            $(progressBarElement).text($(progressBarElement).data('tr-post-processing')||"Processing...") if percentUpload == 100
            return
        onload = (xhr) -> () ->
          console.log xhr.status
          if (xhr.status == 200)
            i++
            uploadedFiles.push JSON.parse(xhr.responseText)
            if  i == (fileInput.files.length)
              uploadedFiles2 = uploadedFiles
              if single
                [..., uploadedFiles2] = uploadedFiles
              $(progressBarElement).text(
                $(progressBarElement).data 'tr-success'
              )
              if successCallback != undefined
                # The second argument is currently only used by the
                # bulk upload to get all uploaded files and not just
                # the last one.
                successCallback(xhr, uploadedFiles2)
              hiddenInput.value = JSON.stringify uploadedFiles2
              fileInput.value = null
              $(progressBarElement)
                  .removeClass('btn-primary')
                  .addClass 'btn-outline-secondary'
            else
              f = fileInput.files[i]
              formData = new FormData()
              formData.append("file", f, f.name)
              xhr2 = new XMLHttpRequest()
              xhr2.onload= onload(xhr2)
              xhr2.onerror =onerror
              xhr.upload.onprogress = onprogress
              xhr2.open('POST', endpoint, true)
              xhr2.send(formData)
          else
            console.log(xhr)
            alert(
              $(progressBarElement).data('tr-failure') + xhr.response
            )
        xhr.onload = onload(xhr)

        xhr.onerror = onerror
        xhr.upload.onprogress = onprogress
        f = fileInput.files[0]
        formData = new FormData()
        formData.append("file", f, f.name)
        xhr.open('POST', endpoint, true)
        xhr.send formData
      else
        alert(
          $(progressBarElement).data 'tr-missing-consent'
        )
    

    fI.change () ->
      if fileChangeCallBack != null
        fileChangeCallBack(fI.files)
      $(uploadStatusElement).text("Upload")
      $(actualUploadButtonElement)
        .show()
        .removeClass('btn-outline-secondary')
        .addClass 'btn-primary'

    uploadButton.on 'click', (e) ->
      e.preventDefault()
      fI.trigger('click')

###
@param fileInput: dom element to listen to.
###
@result = undefined
@userManuscriptUpload = (fileInput) ->
  initBootstrapPopovers()
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
    if file.size < 5000000 || (file.type != 'application/pdf' && file.size < 20000000)
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
  manuscript = 'upload-manuscript'
  geogebra = document.getElementById('upload-geogebra')
  image = document.getElementById('upload-image')
  image2 = document.getElementById('upload-image2')
  bulkCorrection = document.getElementById('upload-bulk-correction')


  # initialize directUploads
  videoUpload video if video?
  manuscriptUpload manuscript if manuscript?
  geogebraUpload geogebra if geogebra?
  uploadPath = "/screenshots/upload"
  uploadPath = "/profile_image/upload" if image2?
  imageUpload image2, uploadPath, "user" if image2?
  imageUpload image, uploadPath, "course" if image?
  bulkCorrectionUpload bulkCorrection if bulkCorrection?

  return
