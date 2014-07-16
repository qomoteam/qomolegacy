window.plumb = {}

hightest_zIndex = 50
toolbox_offset = 0


init_cache = ->
  if not localStorage.boxes
    localStorage.boxes = JSON.stringify {}
  if not localStorage.connections
    localStorage.connections = JSON.stringify []


cached_boxes = ->
  JSON.parse localStorage.boxes


cached_connections = ->
  JSON.parse localStorage.connections


restore_workspace = ->
  if _load
    localStorage.boxes = _boxes
    localStorage.connections = _connections

  boxes = cached_boxes()

  add_toolboxes boxes, ->
    connections = cached_connections()
    for connection in connections
      add_connection connection



add_connection = (connection)->
  sourceEp = eps[connection.sourceId][connection.sourceParamName]
  targetEp = eps[connection.targetId][connection.targetParamName]
  plumb.connect
    drawEndpoints: false
    source: sourceEp
    target: targetEp


save_cached_boxes = (boxes)->
  localStorage.boxes = JSON.stringify boxes


save_cached_connections = (connections)->
  localStorage.connections = JSON.stringify connections


cache_box = (bid, tid)->
  box = {}
  box.id = bid
  box.tid = tid
  box.values = {}
  boxes = cached_boxes()
  boxes[bid] = box
  save_cached_boxes boxes


update_zIndex = ($box, zIndex) ->
  hightest_zIndex += 2
  $box.css 'z-index', hightest_zIndex
  for ep in plumb.getEndpoints $box.attr('id')
    $(ep.canvas).css 'z-index', hightest_zIndex + 1


update_position = (bid, position) ->
  boxes = cached_boxes()
  boxes[bid].position = position
  save_cached_boxes boxes


cache_connection = (sourceId, sourceParamName, targetId, targetParamName)->
  connections = cached_connections()
  connections.push
    sourceId: sourceId
    sourceParamName: sourceParamName
    targetId: targetId
    targetParamName: targetParamName

  save_cached_connections connections


delete_connection = (sourceId, sourceParamName, targetId, targetParamName)->
  connections = cached_connections()
  for connection, i in connections
    if connection.sourceId == sourceId and
       connection.sourceParamName == sourceParamName and
       connection.targetId == targetId and
       connection.targetParamName == targetParamName

      connections.splice i, 1
      save_cached_connections(connections)
      break


window.eps = {}

add_toolboxes = (boxes, hook)->
  return if cached_boxes().length == 0

  url = '/tools/boxes?'
  for i of boxes
    box = boxes[i]
    url += "box[][id]=#{box.id}"
    url += "&box[][tid]=#{box.tid}&"

  boxes = cached_boxes()
  $.get url, (boxes_html) ->
    $(boxes_html).each ->
      box = boxes[this.id]
      init_box this, box.id, box.position
    hook()


add_toolbox = (bid, tid, position)->
  $.get "/tools/#{tid}/box/#{bid}", (box)->
    init_box box, bid, position


init_box = (box_html, bid, position)->
  $box = $(box_html)

  if position
    $box.css
      top: position.top
      left: position.left
  else
    $box.offset
      top: toolbox_offset
      left: toolbox_offset
    toolbox_offset += 30
    if toolbox_offset > 400
      toolbox_offset = 5
    update_position bid, $box.position()

  $('#canvas').append $box

  $box.find('select').chosen()

  plumb.draggable $box,
    stop: ->
      update_position bid, $box.position()

  divHeight = $box.outerHeight()
  tdHeight = $box.find('td').outerHeight()
  titleHeight = $box.find('.titlebar').outerHeight()

  teps = {}

  for param, i in $box.find('.params .param')
    $param = $(param)

    $param.find('.value').each ->
      boxes = cached_boxes()
      paramName = $param.data('paramname')

      value = boxes[bid].values[paramName]
      if value
        if $(this).is(':checkbox')
          this.checked = value
        else if $(this).is('select')
          App.setSelectValues this, value
          $(this).trigger 'chosen:updated'
        else
          $(this).val value

      $(this).change ->
        boxes = cached_boxes()
        value = $(this).val()
        if $(this).is(':checkbox')
          value = $(this).is(':checked')

        boxes[bid].values[paramName] = value
        save_cached_boxes(boxes)


    is_input = false
    if $param.hasClass 'input'
      is_input = true
    else if $param.hasClass 'output'
      is_input = false
    else
      continue

    y = (titleHeight+tdHeight*i + 20) / divHeight

    color =  unless is_input then "#558822" else "#225588"

    ep = plumb.addEndpoint bid,
      endpoint: 'Rectangle'
      anchor: [1, y, 1, 0]
      paintStyle:
        fillStyle: color
        width: 15
        height: 15
      isSource: not is_input
      isTarget: is_input
      maxConnections: 50

    ep.paramName = $param.find('input').attr 'name'

    teps[$param.find('input').attr('name')] = ep

  eps[bid] = teps

  update_zIndex $box
  $box.mousedown ->
    if ($box.css 'z-index') < hightest_zIndex
      update_zIndex $box

  $box.find('.close-toolbox').click ->
    remove_toolbox($box)


remove_toolbox = ($box)->
  bid = $box.attr 'id'
  boxes = cached_boxes()
  delete boxes[bid]

  save_cached_boxes(boxes)

  connections = cached_connections()
  for connection, i in connections
    if bid in [connection.sourceId, connection.targetId]
      connections.splice i, 1
  save_cached_connections(connections)

  for ep in plumb.getEndpoints bid
    plumb.deleteEndpoint ep

  $box.remove()


within 'workspace', ->
  $('#main').layout
    'west__size': .15
    'east__size': .15
    'stateManagement__enabled': true
    'stateManagement__autoLoad': true
    'stateManagement__autoSave': true

  init_cache()

  $('.center .save').click ->
    $.get this.href, (data)->
      dia = dialog
        title: 'Save pipeline'
        content: data
        width: 700
        okValue: 'Save'
        ok: ->
          $form = $('#form-pipeline')
          $form.find('#pipeline_boxes').val localStorage.boxes
          $form.find('#pipeline_connections').val localStorage.connections
          $form.ajaxSubmit()
          return true
        cancelValue: 'Cancel'
        cancel: ->

      dia.showModal()

    return false


  $('.tool-groups h5').click ->
    $this = $(this)
    $ul = $(this).next('ul')
    $i = $(this).find('i')
    if $ul.is(':visible')
      $i.removeClass('fa-folder-open').addClass('fa-folder')
      $ul.slideUp 200, ->
        $this.css 'border-bottom-width', '0'
    else
      $i.removeClass('fa-folder').addClass('fa-folder-open')
      $this.css 'border-bottom-width', '1px'
      $ul.slideDown 200


  jsPlumb.ready ->

    window.plumb = jsPlumb.getInstance
      DragOptions:
        cursor: 'pointer'
        zIndex: 2000
      ConnectionOverlays: [
        [
          "Arrow",
          location: 0.5,
          length: 20
        ]
      ]
      PaintStyle:
        strokeStyle: '#456'
        lineWidth: 6


    plumb.bind 'click', (c)->
      delete_connection c.sourceId, c.endpoints[0].paramName, c.targetId, c.endpoints[1].paramName

      plumb.detach c
      return true


    plumb.bind 'beforeDrop', (info)->
      sourceParamName = info.connection.endpoints[0].paramName
      targetParamName = info.dropEndpoint.paramName
      cache_connection info.sourceId, sourceParamName, info.targetId, targetParamName
      return true


    restore_workspace()


    $('.tool-groups a.tool-link').click ->
      $.get this.href, (box) ->
        cache_box $(box).attr('id'), $(box).data 'tid'
        add_toolbox $(box).attr('id'), $(box).data 'tid'

      return false
