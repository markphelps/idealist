$('#idea-textarea').live('keydown', (function(e) {
  var code = (e.keyCode ? e.keyCode : e.which);
  if(code == 13) { //Enter keycode
    $("#idea-form").submit();
  }
}));
