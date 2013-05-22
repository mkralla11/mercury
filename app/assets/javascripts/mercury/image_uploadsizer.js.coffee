@Mercury.uploadsizer = (file, options) ->
  Mercury.uploadsizer.show(file, options) if Mercury.config.uploading.enabled
  return Mercury.uploadsizer

jQuery.extend Mercury.uploadsizer,

  show: (file, @options = {}) ->
    @file = new Mercury.uploadsizer.File(file)
    return Mercury.uploader(file) if @file.type == "undefined"
    return Mercury.uploader(file) if !@file.type.match(/image/)

    Mercury.trigger('focus:window')
    @initialize(file)
    @appear()


  initialize: (file) ->
    if @initialized
      @submitterSetup(file)
      return

    @build()
    @bindEvents()
    @submitterSetup(file)
    @initialized = true

  supported: ->
    xhr = new XMLHttpRequest

    if window.Uint8Array && window.ArrayBuffer && !XMLHttpRequest.prototype.sendAsBinary
      XMLHttpRequest::sendAsBinary = (datastr) ->
        ui8a = new Uint8Array(datastr.length)
        ui8a[index] = (datastr.charCodeAt(index) & 0xff) for data, index in datastr
        @send(ui8a.buffer)

    return !!(xhr.upload && xhr.sendAsBinary && (Mercury.uploader.fileReaderSupported() || Mercury.uploader.formDataSupported()))

  fileReaderSupported: ->
    !!(window.FileReader)
  
  formDataSupported: ->
    !!(window.FormData)


  build: ->
    @element = jQuery('<div>', {class: 'mercury-uploader', style: 'display:none'})
    @element.append('<div class="mercury-uploader-preview"><b><img/></b></div>')
    @element.append('<div class="mercury-uploader-details"></div>')
    @element.append('<br/><div class="mercury-uploadsizer-select"><div style="font-size:13px"><b>Select Presizing Option:</b></div><div style="font-style:italic;float:right;max-width: 140px;">("presize" represents the max width and height of an image, in order to save server storage space.)</div><br/><input type="radio" name="presizeRadio" value="small" checked> <b>Small</b> (max: 300px)</input><br/><input type="radio" name="presizeRadio" value="medium"> <b>Medium</b> (max: 700px)</input><br/><input type="radio" name="presizeRadio" value="large"> <b>Large</b> (max: 1000px)</input><br/><br/><input type="submit" value="Presize And Upload" name="commit"><br/></div>')

    @overlay = jQuery('<div>', {class: 'mercury-uploader-overlay', style: 'display:none'})

    @element.appendTo(jQuery(@options.appendTo).get(0) ? 'body')
    @overlay.appendTo(jQuery(@options.appendTo).get(0) ? 'body')



  submitterSetup: (file) ->
    curFile = file
    $j = jQuery
    presizeSubmitter = $j('.mercury-uploadsizer-select').find('input[type=submit]')
    presizeSubmitter.unbind()


    $j ->
      presizeSubmitter.click ->
        size = $j('.mercury-uploadsizer-select input[name=presizeRadio]:checked').val()
        curFile.maxDimension = size;
        element = $j(".mercury-uploader");
        element.hide().find('.mercury-uploader-preview b').html('');
        $j(".mercury-uploader-overlay").hide();
        Mercury.uploader(curFile);

  bindEvents: ->
    Mercury.on 'resize', => @position()


  appear: ->
    @fillDisplay()
    @position()

    @overlay.show()
    @overlay.animate {opacity: 1}, 200, 'easeInOutSine', =>
      @element.show()
      @element.animate {opacity: 1}, 200, 'easeInOutSine', =>
        @visible = true
        @loadImage()


  position: ->
    width = @element.outerWidth()
    height = @element.outerHeight()

    @element.css {
      top: (Mercury.displayRect.height - height) / 2
      left: (Mercury.displayRect.width - width) / 2
    }


  fillDisplay: ->
    details = [
      Mercury.I18n('Name: %s', @file.name),
      Mercury.I18n('Size: %s', @file.readableSize),
      Mercury.I18n('Type: %s', @file.type)
    ]
    @element.find('.mercury-uploader-details').html(details.join('<br/>'))


  loadImage: ->
    if Mercury.uploader.fileReaderSupported()
      @file.readAsDataURL (result) =>
        @element.find('.mercury-uploader-preview b').html(jQuery('<img>', {src: result}))








  hide: (delay = 0) ->
    @element.animate {opacity: 0}, 100, 'easeInOutSine', =>
      @overlay.animate {opacity: 0}, 100, 'easeInOutSine', =>
        @overlay.hide()
        @element.hide()
        @reset()
        @visible = false
        Mercury.trigger('focus:window')


  reset: ->
    @element.find('.mercury-uploader-preview b').html('')





class Mercury.uploadsizer.File

  constructor: (@file) ->
    @fullSize = @size = @file.size || @file.fileSize
    @readableSize = @size.toBytes()
    @name = @file.name || @file.fileName
    @type = @file.type || @file.fileType

  readAsDataURL: (callback = null) ->
    reader = new FileReader()
    reader.readAsDataURL(@file)
    reader.onload = => callback(reader.result) if callback