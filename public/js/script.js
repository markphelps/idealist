$('#new-idea').live('keydown', (function(e) {
  var code = (e.keyCode ? e.keyCode : e.which);
  if(code == 13) { //Enter keycode
    $("#create-form").submit();
  }
}));
