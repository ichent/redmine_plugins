  jQuery.noConflict();

  function update_permission(data, user_id, type) {
    if (typeof(AUTH_TOKEN) == "undefined") return;

    var checked = jQuery(data).attr('checked') ? 1 : 0;

    jQuery.ajax({
        "type" : "POST",
        "data" : 'checked=' + checked + '&user_id=' + user_id + '&type=' + type + '&authenticity_token=' + encodeURIComponent(AUTH_TOKEN),
        "url" : '/kanban_permissions/update_permission',
        "success" : function (){
            return false;
        }
    });
  }