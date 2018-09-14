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

  uppy = Uppy.Core(
    id: fileInput.id
    restrictions: allowedFileTypes: [
      '.mp4'
      '.webm'
      '.ogg'
    ])
    .use(Uppy.FileInput,
      target: uploadButton
      locale: strings: chooseFiles: 'Datei auswählen')
    .use(Uppy.Informer, target: informer)
    .use(Uppy.ProgressBar, target: progressBar)

  uppy.use Uppy.XHRUpload,
    endpoint: '/videos/upload'
    fieldName: 'file'
    timeout: 120 * 1000

  uppy.on 'upload', (data) ->
    $('#video-wait').show()
    $('#medium-basics-warning').show()
    return

  uppy.on 'upload-success', (file, data) ->
    $('#video-wait').hide()
    if data.metadata.mime_type in ['video/mp4']
      # show video preview
      videoPreview.src = URL.createObjectURL(file.data)

      # read uploaded file data from the upload endpoint response
      uploadedFileData = JSON.stringify(data)

      # set hidden field value to the uploaded file data so that it is
      # submitted with the form as the attachment
      hiddenInput.value = uploadedFileData
      videoFile = document.getElementById('video-file')
      videoSize = document.getElementById('video-size')
      videoResolution = document.getElementById('video-resolution')
      videoDuration = document.getElementById('video-duration')
      videoFile.innerHTML = data.metadata.filename
      videoSize.innerHTML = formatBytes(data.metadata.size)
      videoResolution.innerHTML = data.metadata.resolution
      videoDuration.innerHTML = fancyTimeFormat(Math.round(data.metadata.duration))
      $(metaData).show()
      $(videoPreviewArea).show()
      $('#medium_detach_video').val('false')
      $('#medium-basics-warning').show()
    else
      uppy.info('Falscher MIME-Typ:' + data.metadata.mime_type, 'error', 5000)
      uppy.reset()
    return

  uppy.on 'upload-error', (file, error) ->
    console.log('error with file:', file.id)
    console.log('error message:', error)
    return
  uppy

manuscriptUpload = (fileInput) ->
  uploadArea = document.getElementById('manuscript-uploadArea')
  uploadButton = document.getElementById('manuscript-uploadButton')
  informer = document.getElementById('manuscript-informer')
  progressBar = document.getElementById('manuscript-progressBar')
  metaData = document.getElementById('manuscript-meta')
  hiddenInput = document.getElementById('upload-manuscript-hidden')

  # uppy will add its own file input
  fileInput.style.display = 'none'

  uppy = Uppy.Core(
    id: fileInput.id
    restrictions: allowedFileTypes: [ '.pdf' ])
    .use(Uppy.FileInput,
      target: uploadButton
      locale: strings: chooseFiles: 'Datei auswählen')
    .use(Uppy.Informer, target: informer)
    .use(Uppy.ProgressBar, target: progressBar)

  uppy.use Uppy.XHRUpload,
    endpoint: '/pdfs/upload'
    fieldName: 'file'

  uppy.on 'complete', (result) ->
    console.log('successful files:', result.successful)
    console.log('failed files:', result.failed)
    return

  uppy.on 'upload-progress', (file, progress) ->
    console.log(file.id, progress.bytesUploaded, progress.bytesTotal)
    return

  uppy.on 'upload-success', (file, data) ->
    if data.metadata.mime_type == 'application/pdf' && data.metadata.pages != null
      # read uploaded file data from the upload endpoint response
      uploadedFileData = JSON.stringify(data)

      # set hidden field value to the uploaded file data so that it is
      # submitted with the form as the attachment
      hiddenInput.value = uploadedFileData
      manuscriptFile = document.getElementById('manuscript-file')
      manuscriptSize = document.getElementById('manuscript-size')
      manuscriptPages = document.getElementById('manuscript-pages')
      manuscriptFile.innerHTML = data.metadata.filename
      manuscriptSize.innerHTML = formatBytes(data.metadata.size)
      manuscriptPages.innerHTML = data.metadata.pages + ' S'
      $('#manuscript-meta').show()
      $('#manuscript-preview').hide()
      $('#medium_detach_manuscript').val('false')
      $('#medium-basics-warning').show()
    else if data.metadata.mime_type != 'application/pdf'
      uppy.info('Falscher MIME-Typ:' + data.metadata.mime_type, 'error', 5000)
      uppy.reset()
    else
      uppy.info('Die Datei ist beschädigt.', 'error', 5000)
      uppy.reset()
    return
  uppy


$(document).on 'turbolinks:load', ->
  video = document.getElementById('upload-video')
  manuscript = document.getElementById('upload-manuscript')

  # make uppy idempotent for turbolinks
  $('.uppy').remove()
  $('.uppy-Root').remove()

  videoUpload video if video?
  manuscriptUpload manuscript if manuscript?

  $('.uppy-FileInput-btn').removeClass('uppy-FileInput-btn')
  .addClass('btn btn-sm btn-outline-secondary')
  return
