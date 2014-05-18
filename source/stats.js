/*global GIGO, jQuery*/
/*jshint browser: true*/
/*jshint devel: true*/

GIGO.stats = {};

GIGO.stats_init = function () {
    jQuery("#status").html("status goes here");
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

