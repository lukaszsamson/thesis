
$(function() {
  $(document).ajaxError(function globalAjaxErrorHandler(event, jqXHR, ajaxSettings, thrownError) {
    alert(jqXHR.status + ': ' + jqXHR.statusText + '\n' + jqXHR.responseText);
  });
  $('#getData').click(function() {
    $.ajax({
      url: '/person/getData',
      type: 'POST',
      success: function(data, textStatus, jqXHR) {
        alert('ok');
      }
    });
  });
  $('#countLinks').click(function() {
    $.ajax({
      url: '/person/countLinks',
      type: 'POST',
      success: function(data, textStatus, jqXHR) {
        alert('ok');
      }
    });
  });
});