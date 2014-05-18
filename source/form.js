
GIGO.form_submit = function(e) {
  server=    $('#server').val();
  var a = [];
  a.push(escape("server") + "=" + escape(server));
  location.hash = a.join("&");
  
  $('#server').blur();
              $('#submitbutton').css("opacity", ".25").css("filter", "alpha(opacity=25)");
  GIGO.start_audit_string(server);
  return 0;
};


GIGO.parseGetVars = function() {
    var getVars, returnVars, i, newVar;
    getVars = location.search.substring(1).split("&");
    returnVars = [];
    i = 0;
    for (i = 0; i < getVars.length; i = i + 1) {
        newVar = getVars[i].split("=");
        returnVars[unescape(newVar[0])] = unescape(newVar[1]);
    }
    getVars = location.hash.substring(1).split("&");
    for (i = 0; i < getVars.length; i = i + 1) {
        newVar = getVars[i].split("=");
        returnVars[unescape(newVar[0])] = unescape(newVar[1]);
    }
    
    
    return returnVars;
};

GIGO.create_form = function(action) {

    var cgi, form, server;
    
    cgi = GIGO.parseGetVars();
    server = cgi["server"];
    form = $("<form></form>",
     { id: "serverform",
       action: "javascript:GIGO.form_submit()"
       });
    form.append($("<input/>", {
        name: "server",
        value: server,
        id: "server",
        type: "text",
        maxLength: 80,
    }));
    form.append($("<input/>", {
        type: "submit",
        value: "Audit",
        id: "submitbutton"
    }));
    form.focus();
    return $("<div id=form>").append(form);
};


GIGO.add_form_to_page = function() {
    var form = GIGO.create_form(0);
    $("#form").replaceWith( $("<div id=form>").append(form) );
    $("#server").focus();
        
};

