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


  $('a[data-operation]').click () ->
    $.ajax
      url: "/person/mapReduce/#{$(@).data('operation')}/request"
      type: 'POST'
      success: (data, textStatus, jqXHR) ->
        showModal data.header, data.body