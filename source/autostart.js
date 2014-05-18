/*global GIGO, jQuery*/
/*jshint browser: true*/
/*jshint devel: true*/

GIGO.autostart = function () {
    var cgi, server_string, server_list, i, good;
    cgi = GIGO.parseGetVars();
    server_string = cgi["server"];
    good = 0;
    if (server_string) {
        good = 1;
        server_list = server_string.split(" ");
        for (i = 0; i < server_list.length; i = i + 1) {
            if (!server_list[i].match("ipv6")) {
                good = 0;
            }
        }
    }
    if (good) {
        GIGO.start_audit_string(server_string);
    }
};

