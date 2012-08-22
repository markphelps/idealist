$(function() {
	$("#idea-textarea").live('keydown', function(e) {
	  var code = (e.keyCode ? e.keyCode : e.which);
	  // if enter is pressed, not shift + enter
	  if(!e.shiftKey && code == 13) {
	    $("#idea-form").submit();
	    return true;
	  }
	});
});