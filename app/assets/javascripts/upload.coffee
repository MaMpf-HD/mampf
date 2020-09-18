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
    timeout: 120 * 1000

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
      videoResolution = document.getElementById('video-resolution')
      videoDuration = document.getElementById('video-duration')

      # put metadata into place
      videoFile.innerHTML = data.metadata.filename
      videoSize.innerHTML = formatBytes(data.metadata.size)
      videoResolution.innerHTML = data.metadata.resolution
      videoDuration.innerHTML = fancyTimeFormat(Math.round(data.metadata.duration))
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

@userManuscriptUpload = (fileInput) ->
  # set everything up
  uploadButton = document.getElementById('userManuscript-uploadButton')
  informer = document.getElementById('userManuscript-informer')
  statusBar = document.getElementById('userManuscript-statusBar')
  hiddenInput = document.getElementById('upload-userManuscript-hidden')
  userManuscriptMetadata = document.getElementById('userManuscriptMetadata')

  # uppy will add its own file input
  fileInput.style.display = 'none'

  # create uppy instance
  uppy = Uppy.Core(
    id: fileInput.id
    autoProceed: true
    restrictions:
      allowedFileTypes: [ '.pdf' ]
      maxFileSize: 10485760)
    .use(Uppy.FileInput,
      target: uploadButton
      locale: strings: chooseFiles: uploadButton.dataset.choosefiles)
    .use(Uppy.Informer, target: informer)
    .use(Uppy.StatusBar, target: statusBar)

  # target the endpoint for shrine uploader
  uppy.use Uppy.XHRUpload,
    endpoint: '/user_pdfs/upload'
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
      userManuscriptMetadata.innerHTML = data.metadata.filename + ' (' + formatBytes(data.metadata.size) + ')'
      userManuscriptMetadata.style.display = 'inline'

      $('#removeUserManuscript').show()
      $('#submission_detach_user_manuscript').val('false')
      $('#noUserManuscript').hide()
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

$(document).on 'turbolinks:load', ->
  video = document.getElementById('upload-video')
  manuscript = document.getElementById('upload-manuscript')
  geogebra = document.getElementById('upload-geogebra')
  image = document.getElementById('upload-image')

  # make uppy idempotent for turbolinks
  $('.uppy').remove()
  $('.uppy-Root').remove()

  # initialize uppy
  videoUpload video if video?
  manuscriptUpload manuscript if manuscript?
  geogebraUpload geogebra if geogebra?
  imageUpload image if image?

  # make uppy upload buttons look like bootstrap
  $('.uppy-FileInput-btn').removeClass('uppy-FileInput-btn')
  .addClass('btn btn-sm btn-outline-secondary')
  return
