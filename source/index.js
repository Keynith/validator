
jQuery(document).ready(function() {
   jQuery("#noscript").hide(); /* Hide the ugly "JavaScript Required" message */
   GIGO.add_form_to_page();
   GIGO.next_task_scheduler();
   GIGO.autostart();
});

