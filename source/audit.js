GIGO.sites_image_size = 24;

GIGO.max_threads = 4;

GIGO.running_threads = 0;

GIGO.start_audit_string = function(server_string) {
    var i, server_list;
    GIGO.servers = [];
    $("#results").empty();
    server_list = server_string.split(" ");
    for (i = 0; i < server_list.length; i = i + 1) {
        if (server_list[i] === "mirrors") {
            GIGO.start_audit_mirrors();
        } else {
            GIGO.start_audit_host(server_list[i]);
        }
    }
};

GIGO.start_audit_mirrors = function() {
    var entry, cgi, a, url, data;
    data = {};
    data.server = "test-ipv6.com";
    data.plugin = "_mirrors";
    jQuery.ajax({
        url: "/validate.cgi",
        data: data,
        dataType: "jsonp",
        error: function(jqXHR, textStatus, errorThrown) {
            alert("failed to get the mirrors list");
        },
        success: function(data, textStatus, jqXHR) {
            var i;
            while (data.mirrors.length) {
                var x = data.mirrors.shift();
                GIGO.start_audit_host(x);
            }
        }
    });
};

GIGO.start_audit_host = function(server) {
    var task = {};
    task.server = server;
    if (GIGO.servers[server]) {
        return;
    }
    task.id = Math.floor(Math.random() * 1e9);
    GIGO.servers[server] = task.id;
    task.pid = "#" + task.id;
    task.cgi = "server=" + escape(server);
    $("#results").append($("<div/>", {
        id: task.id,
        "class": "ok"
    }));
    task.context = $(task.pid);
    var h1 = $("<h1>");
    h1.text(server);
    task.context.append($("<div/>").append(h1));
    task.plugin = "_list";
    task.success = GIGO.success__list;
    GIGO.add_task(task);
    GIGO.next_task();
};

GIGO.next_task = function() {
    var entry, cgi, a, url, data;
    if (GIGO.running_threads < GIGO.max_threads && GIGO.tasks.length > 0) {
        entry = GIGO.tasks.shift();
        if (entry.td_image) {
            $("img", entry.td_image).css("opacity", "1.0").css("filter", "alpha(opacity=100)");
        }
        data = {};
        data.server = entry.server;
        data.plugin = entry.plugin;
        GIGO.running_threads = GIGO.running_threads + 1;
        jQuery.ajax({
            url: "/validate.cgi",
            data: data,
            dataType: "jsonp",
            error: function(jqXHR, textStatus, errorThrown) {
                $("#submitbutton").css("opacity", "1.0").css("filter", "alpha(opacity=100)");
                if (entry.error) {
                    GIGO.running_threads = GIGO.running_threads - 1;
                    entry.error(entry, jqXHR, textStatus, errorThrown, this.url);
                }
            },
            success: function(data, textStatus, jqXHR) {
                $("#submitbutton").css("opacity", "1.0").css("filter", "alpha(opacity=100)");
                if (entry.success) {
                    GIGO.running_threads = GIGO.running_threads - 1;
                    entry.success(entry, data, textStatus, jqXHR, this.url);
                }
            }
        });
    }
};

GIGO.add_task = function(task) {
    var entry = {};
    GIGO.tasks.push(task);
};

GIGO.next_task_scheduler = function() {
    setInterval(GIGO.next_task, 1e3);
};

GIGO.success__list = function(entry, data, jqXHR, textStatus) {
    div = $("<div/>").append(entry.plugin + " = data");
    if (data.abort) {
        div = $("<div/>").append("Aborting: " + data.error);
        entry.context.append(div);
        return;
    }
    var i;
    var table = $("<table></table>");
    table.append("<tr><th>?</th><th>plugin</th><th>expected</th><th>found</th></tr>");
    for (i = 0; i < data.plugins.length; i++) {
        var p = data.plugins[i];
        var tid = "tr_" + entry.id + "_" + p;
        var task = {};
        task.server = entry.server;
        task.id = entry.id;
        task.pid = entry.pid;
        task.tid = tid;
        task.plugin = p;
        task.context = entry.context;
        task.error = GIGO.error_generic;
        task.success = GIGO.success_generic;
        var tr = $("<tr></tr>", {
            id: task.tid,
            "class": "tr1 pending"
        });
        var td_image = $("<td></td>", {
            id: task.tid + "_td_image",
            "class": "td_image"
        });
        var td_name = $("<td></td>", {
            id: task.tid + "_td_name",
            "class": "td_name"
        });
        var td_expect = $("<td></td>", {
            id: task.tid + "_td_expect",
            "class": "td_expect"
        });
        var td_found = $("<td></td>", {
            id: task.tid + "_td_found",
            "class": "td_found"
        });
        td_image.append($("<img>", {
            src: "/images/spinner.gif",
            height: GIGO.sites_image_size,
            width: GIGO.sites_image_size
        }).css("opacity", "0.1").css("filter", "alpha(opacity=10)"));
        td_name.text(p);
        tr.append(td_image, td_name, td_expect, td_found);
        var tr2 = $("<tr></tr>", {
            id: task.tid,
            "class": "tr2 pending"
        });
        var td2_image = $("<td></td>", {
            "class": "td2_image"
        });
        var td2_name = $("<td></td>", {
            "class": "td2_name"
        });
        var td_notes = $("<td></td>", {
            id: task.tid + "_td_notes",
            colSpan: 2,
            "class": "td_notes"
        });
        tr2.append(td2_image, td2_name, td_notes);
        tr2.hide();
        table.append(tr, tr2);
        task.td_image = td_image;
        task.td_name = td_name;
        task.td_expect = td_expect;
        task.td_found = td_found;
        task.td_notes = td_notes;
        task.tr = tr;
        task.tr2 = tr2;
        GIGO.add_task(task);
        GIGO.next_task();
    }
    entry.context.append(table);
};

GIGO.error_generic = function(entry, jqXHR, textStatus, errorThrown, url) {
    $("img", entry.td_image).replaceWith($("<img>", {
        src: "/images/knob_attention.png",
        height: GIGO.sites_image_size,
        width: GIGO.sites_image_size
    }));
    entry.td_notes.html("Error calling validate.cgi, errorThrown=" + errorThrown + " url=" + "<a href='" + url + "'>" + url + "</a>");
};

GIGO.success_generic = function(entry, data, jqXHR, textStatus) {
    if (data.status === "ok") {
        $("img", entry.td_image).replaceWith($("<img>", {
            src: "/images/knob_valid_green.png",
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
    } else if (data.status === "bad") {
        $("img", entry.td_image).replaceWith($("<img>", {
            src: "/images/knob_cancel.png",
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
        $("img", entry.td_image).replaceWith($("<img>", {
            src: "/images/knob_attention.png",
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
            rentry.td_notes.text("unknown error with plugin " + entry.plugin);
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

