#= require 'fine-uploader'

within 'tools', ->
  $('.save-tool').click ->
    $form = $('#form-tool')
    $form.submit()


  endpoint = $('#uploader').data 'endpoint'
  $('#uploader').fineUploader
    request:
      inputName: 'file'
      filenameParam: 'filename'
      endpoint: endpoint
      params:
        authenticity_token: App.token()


  $(document).on 'click', '.params .edit-options', ->
    $options = $(this).parents('tr').find('.options')


    offset = $(this).position()
    width = $(this).outerWidth()
    height = $(this).outerHeight()
    popupWidth   = $options.width()

    $options.css
      top    : offset.top + height + 1
      left   : offset.left + (width / 2) - (popupWidth / 2) + 1
      bottom : 'auto'
      right  : 'auto'

    $options.show()


  $(document).on 'click', '.params .options button.ok', ->
    $(this).parents('.options').hide()
    return false


  $(document).on 'change', 'select[name="tool[params][][type]"]', ->
    $(this).parents('td').next().html $("#tpl_param_#{this.value}").text()

