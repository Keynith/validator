var GIGO;

GIGO = {};
GIGO.servers = {};
GIGO.tasks = [];

/*global GIGO, jQuery*/
/*jshint browser: true*/
/*jshint devel: true*/

GIGO.sites_image_size = 24;

GIGO.max_threads = 8;

GIGO.running_threads = 0;

GIGO.start_audit_string = function (server_string) {
    var i, server_list;
    GIGO.servers = [];
    jQuery("#results").empty();
    jQuery("#pb").empty();
    GIGO.stats_init();
    server_list = server_string.split(" ");
    jQuery("#pb").append(GIGO.progress_bar(0, 1, 0));
    if (server_list.length > 1) {
        jQuery("#multiple").show();
    } else {
        jQuery("#multiple").hide();
    }
    for (i = 0; i < server_list.length; i = i + 1) {
        if (server_list[i] === "mirrors") {
            GIGO.start_audit_mirrors();
            jQuery("#multiple").show();
        } else {
            GIGO.start_audit_host(server_list[i]);
        }
    }
};

GIGO.start_audit_mirrors = function () {
    var data;
    data = {};
    data.server = "test-ipv6.com";
    data.plugin = "_mirrors";
    jQuery.ajax({
        url: "/validate.cgi",
        data: data,
        dataType: "jsonp",
        error: function (jqXHR, textStatus, errorThrown) {
            alert("failed to get the mirrors list");
        },
        success: function (data, textStatus, jqXHR) {
            var x;
            while (data.mirrors.length) {
                x = data.mirrors.shift();
                GIGO.start_audit_host(x);
            }
        }
    });
};

GIGO.start_audit_host = function (server) {
    var div, task;
    
    if (GIGO.servers[server]) {
        return;
    }
    GIGO.servers[server] = 1;
    div = jQuery("<div/>", {
        "class": "ok"
    }).append(jQuery("<h2>").html(server));
    jQuery("#results").append(div);

    task = {};
    task.server = server;
    task.context = div;
    task.parent = task;
    GIGO.stats_start_server(task);
    GIGO.server_table_start(task);
    GIGO.start_task_by_name(task, "_list");
};

GIGO.next_task = function () {
    var entry, data;
    if (GIGO.running_threads < GIGO.max_threads && GIGO.tasks.length > 0) {
        entry = GIGO.tasks.shift();
        if (entry.td_image) {
            jQuery("img", entry.td_image).css("opacity", "1.0").css("filter", "alpha(opacity=100)");
        }
        data = {};
        data.server = entry.server;
        data.plugin = entry.plugin;
        GIGO.running_threads = GIGO.running_threads + 1;
        jQuery.ajax({
            url: "/validate.cgi",
            data: data,
            dataType: "jsonp",
            error: function (jqXHR, textStatus, errorThrown) {
                jQuery("#submitbutton").css("opacity", "1.0").css("filter", "alpha(opacity=100)");
                if (entry.error) {
                    GIGO.running_threads = GIGO.running_threads - 1;
                    entry.error(entry, jqXHR, textStatus, errorThrown, this.url);
                }
                GIGO.stats_finish_task(entry, "bad");
            },
            success: function (data, textStatus, jqXHR) {
                jQuery("#submitbutton").css("opacity", "1.0").css("filter", "alpha(opacity=100)");
                if (entry.success) {
                    GIGO.running_threads = GIGO.running_threads - 1;
                    entry.success(entry, data, textStatus, jqXHR, this.url);
                }
                GIGO.stats_finish_task(entry, data.status);
            }
        });
    }
};

GIGO.add_task = function (task) {

    GIGO.tasks.push(task);
    GIGO.server_table_add_tr(task);
    GIGO.stats_add_task(task);
    GIGO.next_task();
};

GIGO.sort_tasks = function () {
    GIGO.tasks.sort(function (a, b) {
        if (a.plugin < b.plugin) return -1;
        if (a.plugin > b.plugin) return 1;
        return 0;
    });
};

GIGO.next_task_scheduler = function () {
    setInterval(GIGO.next_task, 1e3);
};

GIGO.progress_bar = function (a, b, e) {
    var div, width, class2;
    if (!b) {
        a = b = 1;
    }
    width = 100 * a / b;
    width = width + "%";
    
    class2 = "";

    if (a >= b) {
        class2 = "progressbar_done";
    }
    if (e > 0) {
        class2 = "progressbar_bad";
    }
    
    div = jQuery("<div>", {
        "class": "progressbar" + " "  + class2
    });
    div.append(jQuery("<div>", {
        width: width
    }));
    return div;
};

GIGO.server_table_start = function (entry) {
    var table, div, mdiv, a_show_all, a_show_bad, m_a_show_all, m_a_show_bad;
    table = jQuery("<table></table>");
    table.append("<tr><th>status</th><th>plugin</th><th>expected</th><th>found</th></tr>");
    div = jQuery("<div></div>", {
        "class": "beforetable"
    });

    a_show_all = jQuery("<a>show all</a>", {href: "#"});
    a_show_bad = jQuery("<a>show bad</a>", {href: "#"});
    a_show_all.click(function () {
        jQuery("tr.tr1.ok:not(td)", entry.context).show();
    });
    a_show_bad.click(function () {
        jQuery("tr.tr1.ok:not(td)", entry.context).show();
        jQuery("tr.tr1.ok:not(td)", entry.context).hide();
    });
    div.append("[ ", a_show_all, " | ", a_show_bad, " ]");
    entry.parent.pb = jQuery("<div></div>").append(GIGO.progress_bar(0, 1, 0));
    entry.context.append(div, entry.pb, table);
    
    
    // Also, we need the same buttons when looking at many servers
    mdiv = jQuery("<div></div>", {
        "class": "beforetable"
    });
    m_a_show_all = jQuery("<a>show all</a>", {href: "#"});
    m_a_show_bad = jQuery("<a>show bad</a>", {href: "#"});
    m_a_show_all.click(function () {
        jQuery("tr.tr1.ok:not(td)").show();
        jQuery("div.ok:not(td)").show();
    });
    m_a_show_bad.click(function () {
        jQuery("tr.tr1.ok:not(td)").show();
        jQuery("div.ok:not(td)").show();
        jQuery("tr.tr1.ok:not(td)").hide();
        jQuery("div.ok:not(td)").hide();
    });
    mdiv.append("[ ", m_a_show_all, " | ", m_a_show_bad, " ]");
    jQuery("#actions").empty();
    jQuery("#actions").append(mdiv);
};

GIGO.server_table_add_tr = function (entry) {
    entry.tr = jQuery("<tr></tr>", {
        "class": "tr1 pending"
    });
    entry.td_image = jQuery("<td></td>", {
        "class": "td_image"
    });
    entry.td_name = jQuery("<td></td>", {
        "class": "td_name"
    });
    entry.td_expect = jQuery("<td></td>", {
        "class": "td_expect"
    });
    entry.td_found = jQuery("<td></td>", {
        "class": "td_found"
    });
    entry.td_image.append(jQuery("<img>", {
        src: "http://ds.test-ipv6.com/images/spinner.gif",
        height: GIGO.sites_image_size,
        width: GIGO.sites_image_size
    }).css("opacity", "0.1").css("filter", "alpha(opacity=10)"));
    entry.td_name.text(entry.plugin);
    entry.tr.append(entry.td_image, entry.td_name, entry.td_expect, entry.td_found);
    entry.tr2 = jQuery("<tr></tr>", {
        "class": "tr2 pending"
    });
    entry.td2_image = jQuery("<td></td>", {
        "class": "td2_image"
    });
    entry.td2_name = jQuery("<td></td>", {
        "class": "td2_name"
    });
    entry.td_notes = jQuery("<td></td>", {
        colSpan: 2,
        "class": "td_notes"
    });
    entry.tr2.append(entry.td2_image, entry.td2_name, entry.td_notes);
    entry.tr2.hide();
    jQuery("tr:last", entry.context).after(entry.tr, entry.tr2);
};

GIGO.start_task_by_name = function (entry, plugin) {
    var task = {};
    task.server = entry.server;
    task.plugin = plugin;
    task.context = entry.context;
    task.parent = entry.parent;
    task.error = GIGO.error_generic;
    task.success = GIGO.success_generic;
    GIGO.add_task(task);
};

GIGO.start_plugins = function (entry, plugins) {
    var i;
    if (plugins) {
        for (i = 0; i < plugins.length; i = i + 1) {
            GIGO.start_task_by_name(entry, plugins[i]);
        }
    }
};

GIGO.error_generic = function (entry, jqXHR, textStatus, errorThrown, url) {
    jQuery("img", entry.td_image).replaceWith(jQuery("<img>", {
        src: "http://ds.test-ipv6.com/images/knob_attention.png",
        height: GIGO.sites_image_size,
        width: GIGO.sites_image_size
    }));
    entry.td_notes.html("Error calling validate.cgi, errorThrown=" + errorThrown + " url=" + "<a href='" + url + "'>" + url + "</a>");
};

GIGO.success_generic = function (entry, data, jqXHR, textStatus) {
    if (data.status === "ok") {
        jQuery("img", entry.td_image).replaceWith(jQuery("<img>", {
            src: "http://ds.test-ipv6.com/images/knob_valid_green.png",
            height: GIGO.sites_image_size,
            width: GIGO.sites_image_size
        }));
        if (entry.tr) {
            entry.tr.addClass("ok");
            entry.tr.removeClass("pending");
        }
        if (entry.tr2) {
            entry.tr2.addClass("ok");
            entry.tr2.removeClass("pending");
        }
        GIGO.start_plugins(entry, data.plugins);
    } else if (data.status === "bad") {
        jQuery("img", entry.td_image).replaceWith(jQuery("<img>", {
            src: "http://ds.test-ipv6.com/images/knob_cancel.png",
            height: GIGO.sites_image_size,
            width: GIGO.sites_image_size
        }));
        if (entry.tr) {
            entry.tr.addClass("bad");
            entry.tr.removeClass("pending");
        }
        if (entry.tr2) {
            entry.tr2.addClass("bad");
            entry.tr2.removeClass("pending");
        }
        if (entry.tr2) {
            entry.tr2.show();
        }
        if (entry.context) {
            entry.context.addClass("bad");
            entry.context.removeClass("ok");
        }
    } else {
        jQuery("img", entry.td_image).replaceWith(jQuery("<img>", {
            src: "http://ds.test-ipv6.com/images/knob_attention.png",
            height: GIGO.sites_image_size,
            width: GIGO.sites_image_size
        }));
        if (entry.tr) {
            entry.tr.addClass("dunno");
            entry.tr.removeClass("pending");
        }
        if (entry.tr2) {
            entry.tr2.addClass("dunno");
            entry.tr2.removeClass("pending");
        }
        if (entry.tr2) {
            entry.tr2.show();
        }
        if (entry.context) {
            entry.context.addClass("bad");
            entry.context.removeClass("ok");
        }
        if (data.error_html) {
            entry.td_notes.html(data.error_html);
        } else if (data.error) {
            entry.td_notes.text(data.error);
        } else {
            entry.td_notes.text("unknown error with plugin " + entry.plugin);
        }
    }
    if (data.expect_html) {
        entry.td_expect.html(data.expect_html);
    } else if (data.expect) {
        entry.td_expect.text(data.expect);
    }
    if (data.found_html) {
        entry.td_found.html(data.found_html);
    } else if (data.found) {
        entry.td_found.text(data.found);
    }
    if (data.notes_html) {
        entry.td_notes.html(data.notes_html);
    } else if (data.notes) {
        entry.td_notes.text(data.notes);
    }
    GIGO.next_task();
};

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

/*global GIGO, jQuery, escape, unescape*/
/*jshint browser: true*/
/*jshint devel: true*/

GIGO.form_submit = function (e) {
    var server, a = [];
    server = jQuery("#server").val();
    a.push(escape("server") + "=" + escape(server));
    location.hash = a.join("&");
    jQuery("#server").blur();
    jQuery("#submitbutton").css("opacity", ".25").css("filter", "alpha(opacity=25)");
    GIGO.start_audit_string(server);
    return 0;
};

GIGO.parseGetVars = function () {
    var getVars, returnVars = [], i, newVar;
    getVars = location.search.substring(1).split("&");
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

GIGO.create_form = function (action) {
    var cgi, form, server;
    cgi = GIGO.parseGetVars();
    server = cgi["server"];
    form = jQuery("<form></form>", {
        id: "serverform",
        action: "javascript:GIGO.form_submit()"
    });
    form.append(jQuery("<input/>", {
        name: "server",
        value: server,
        id: "server",
        type: "text",
        maxLength: 80
    }));
    form.append(jQuery("<input/>", {
        type: "submit",
        value: "Audit",
        id: "submitbutton"
    }));
    form.focus();
    return jQuery("<div id=form>").append(form);
};

GIGO.add_form_to_page = function () {
    var form = GIGO.create_form(0);
    jQuery("#form").replaceWith(jQuery("<div id=form>").append(form));
    jQuery("#server").focus();
};

/*global GIGO, jQuery*/
/*jshint browser: true*/
/*jshint devel: true*/

GIGO.stats = {};

GIGO.stats_init = function () {
    jQuery("#status").html("Note, if you need to reproduce the DNS 'dig' test results, ask jfesler to open the DNS servers to your IP addresses.");
    GIGO.stats = {};
    GIGO.pending = 0;
    GIGO.bad = 0;
    GIGO.finished = 0;
    GIGO.total = 0;
};

GIGO.stats_start_server = function (task) {
    task.parent.pending = 0;
    task.parent.bad = 0;
    task.parent.finished = 0;
    task.parent.total = 0;
};

GIGO.stats_pb_server = function (task) {
    task.parent.pb.empty();
    task.parent.pb.append(GIGO.progress_bar(task.parent.finished, task.parent.total, task.parent.bad));
    jQuery("#pb").empty();
    jQuery("#pb").append(GIGO.progress_bar(GIGO.finished, GIGO.total, GIGO.bad));
};

GIGO.stats_add_task = function (task) {
    task.parent.pending = task.parent.pending + 1;
    task.parent.total = task.parent.total + 1;
    GIGO.pending = GIGO.pending + 1;
    GIGO.total = GIGO.total + 1;
    GIGO.stats_pb_server(task);
};

GIGO.stats_finish_task = function (task, status) {
    task.parent.pending = task.parent.pending - 1;
    task.parent.finished = task.parent.finished + 1;
    GIGO.pending = GIGO.pending - 1;
    GIGO.finished = GIGO.finished + 1;
    if (status === "ok") {} else {
        task.parent.bad = task.parent.bad + 1;
        GIGO.bad = GIGO.bad + 1;
    }
    if (task.parent.bad) {
        task.parent.context.addClass("bad");
        task.parent.context.removeClass("ok");
    } else {
        task.parent.context.addClass("ok");
        task.parent.context.removeClass("bad");
    }
    
    GIGO.stats_pb_server(task);
};

jQuery(document).ready(function() {
    jQuery("#noscript").hide();
    GIGO.add_form_to_page();
    GIGO.next_task_scheduler();
    GIGO.autostart();
});

