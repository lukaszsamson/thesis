showModal = (header, body) ->
    modal = $ '#modal'
    modal.find('h3').text header
    modal.find('p').text body
    modal.modal()


$ () ->
  $(document).ajaxError (event, jqXHR, ajaxSettings, thrownError) ->
      showModal "#{jqXHR.status}: #{jqXHR.statusText}", jqXHR.responseText
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
