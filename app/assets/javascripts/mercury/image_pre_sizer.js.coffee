@Mercury.presizer = (file, options) ->
  Mercury.presizer.show(file, options)

jQuery.extend Mercury.presizer,

  show: (file, @options = {}) ->
    @file = new Mercury.presizer.File(file)
    return Mercury.uploader(@file) if !!@file.type.match(/image/)

    Mercury.trigger('focus:window')
    @initialize()
    @appear()


  initialize: ->
    return if @initialized
    @build()
    @bindEvents()
    @submitterSetup()
    @initialized = true




  build: ->
    @element = jQuery('<div>', {class: 'mercury-uploader', style: 'display:none'})
    @element.append('<div class="mercury-uploader-preview"><b><img/></b></div>')
    @element.append('<div class="mercury-uploader-details"></div>')
    @element.append('<div class="mercury-presizer-select">
    <div style="font-size:13px">Select Presizing Option:</div>
    <div style="font-style:italic">('presize' represents the max width and height of an image, in order to save server storage space.)</div>
    <input type="radio" name="presizeRadio" value="small"><b>Small</b> (max: 300px)</input>
    <input type="radio" name="presizeRadio" value="medium" checked><b>Medium</b> (max: 700px)</input>
    <input type="radio" name="presizeRadio" value="large"><b>Large</b> (max: 1000px)</input>
    <input type="submit" value="Presize And Upload" name="commit">
    </div>')

    @overlay = jQuery('<div>', {class: 'mercury-uploader-overlay', style: 'display:none'})

    @element.appendTo(jQuery(@options.appendTo).get(0) ? 'body')
    @overlay.appendTo(jQuery(@options.appendTo).get(0) ? 'body')



  submitterSetup: ->
    $j = jQuery
    presizeSubmitter = $j('.mercury-presizer-select').find('input[type=submit]')

    $j ->
      presizeSubmitter.click ->
        temp = $j('.mercury-presizer-select input[name=presizeRadio]:checked').val()
        breakpointer = 0;
        Mercury.uploader(@file);

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
        @upload()
    else
      @upload()







  hide: (delay = 0) ->
    setTimeout =>
      @element.animate {opacity: 0}, 200, 'easeInOutSine', =>
        @overlay.animate {opacity: 0}, 200, 'easeInOutSine', =>
          @overlay.hide()
          @element.hide()
          @reset()
          @visible = false
          Mercury.trigger('focus:frame')
    , delay * 1000


  reset: ->
    @element.find('.mercury-uploader-preview b').html('')





class Mercury.presizer.File

  constructor: (@file) ->
    @fullSize = @size = @file.size || @file.fileSize
    @readableSize = @size.toBytes()
    @name = @file.name || @file.fileName
    @type = @file.type || @file.fileType