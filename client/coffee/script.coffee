window.showModal = showModal = (header, body) ->
    modal = $ '#modal'
    modal.find('h3').text header
    modal.find('p').text body
    modal.modal()


$ () ->
  $(document).ajaxError (event, jqXHR, ajaxSettings, thrownError) ->
      showModal "#{jqXHR.status}: #{jqXHR.statusText}", jqXHR.responseText
  socket = io.connect document.location.origin
  socket.on('jobCompleted', (data) -> showModal data.header, data.body)
  $('#getData').click () ->
    $.ajax
      url: '/person/getData'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
        showModal data.header, data.body

  $('#countLinks').click () ->
    $.ajax
      url: '/person/countLinks'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
          showModal 'Data requested', 'Your data will be ready soon.'

  $('#countLikesByName').click () ->
    $.ajax
      url: '/person/countLikes/byName'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
          showModal 'Data requested', 'Your data will be ready soon.'

  $('#countLikesByCategory').click () ->
    $.ajax
      url: '/person/countLikes/byCategory'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
          showModal 'Data requested', 'Your data will be ready soon.'
  $('#logisticRegressionOnLinks').click () ->
    $.ajax
      url: '/person/logisticRegressionOnLinks'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
        showModal 'Data requested', 'Your data will be ready soon.'
  $('#linksHistogram').click () ->
    $.ajax
      url: '/person/mapReduce/linksHistogram/request'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
        showModal 'Data requested', 'Your data will be ready soon.'

  $('#friendsConnections').click () ->
    $.ajax
      url: '/person/mapReduce/friendsConnections/request'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
        showModal data.header, data.body


  $('#linksFlow').click () ->
    $.ajax
      url: '/person/mapReduce/linksFlow/request'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
        showModal data.header, data.body

  $('#likesHistogram').click () ->
    $.ajax
      url: '/person/mapReduce/likesHistogram/request'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
        showModal 'Data requested', 'Your data will be ready soon.'

  $('#likesFlow').click () ->
    $.ajax
      url: '/person/mapReduce/likesFlow/request'
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
        showModal data.header, data.body