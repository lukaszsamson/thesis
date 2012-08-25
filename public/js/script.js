showModal = function showModal(header, body) {
    var modal = $('#modal');
    modal.find('h3').text(header);
    modal.find('p').text(body);
    $('#modal').modal();
}

$(function() {
  $(document).ajaxError(function globalAjaxErrorHandler(event, jqXHR, ajaxSettings, thrownError) {
      showModal(jqXHR.status + ': ' + jqXHR.statusText, jqXHR.responseText);
  });
  $('#getData').click(function() {
    $.ajax({
      url: '/person/getData',
      type: 'POST',
      success: function(data, textStatus, jqXHR) {
        showModal('Data requested', 'Your data will be ready soon.');
      }
    });
  });
  $('#countLinks').click(function() {
    $.ajax({
      url: '/person/countLinks',
      type: 'POST',
      success: function(data, textStatus, jqXHR) {
          showModal('Data requested', 'Your data will be ready soon.');
      }
    });
  });
  $('#countLikesByName').click(function() {
    $.ajax({
      url: '/person/countLikes/byName',
      type: 'POST',
      success: function(data, textStatus, jqXHR) {
          showModal('Data requested', 'Your data will be ready soon.');
      }
    });
  });
  $('#countLikesByCategory').click(function() {
    $.ajax({
      url: '/person/countLikes/byCategory',
      type: 'POST',
      success: function(data, textStatus, jqXHR) {
          showModal('Data requested', 'Your data will be ready soon.');
      }
    });
  });
});