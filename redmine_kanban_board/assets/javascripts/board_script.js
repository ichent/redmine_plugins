jQuery.noConflict();

jQuery(document).ready(function($){
    $('.column').sortable({
	connectWith: '.column',
	handle: 'h2',
	cursor: 'move',
	placeholder: 'placeholder',
	forcePlaceholderSize: true,
	opacity: 0.4,
	stop: function(event, ui){
            $(ui.item).find('h2').click();
            
            var sortorder = '';
            $('.column').each(function(){
		var itemorder = $(this).sortable('toArray');
		var columnId = $(this).attr('id');
		sortorder += columnId + '=' + itemorder.toString() + '&';
            });

            if (typeof(AUTH_TOKEN) == "undefined") return;

            $("#ajax-indicator").show();

            $.ajax({
                "type" : "POST",
                "data" : sortorder +  'authenticity_token=' + encodeURIComponent(AUTH_TOKEN),
                "url" : '/kanban/update_board',
                "success" : function (result) {
                    $('.qtip_windows').html(result);
                    $("#ajax-indicator").hide();

                    return false;
                }
            });
	}
    })
    .disableSelection();
	
    // Windows
    $('#layer1').Draggable({
        zIndex: 	20,
        ghosting:	false,
        handle:	'#layer1_handle'
    });

    $("#layer1").hide();
    $('#close1').click(function(){
        $("#layer1").hide();
    });

    $('.dragbox').dblclick(function(){
        issue_id = $(this).attr('id');
        issue_id = issue_id.replace('item', '');

        location.href = '/issues/' + issue_id;
    });
});

function board_search() {
    var search_str = '';

    var project = jQuery('#search_board #project').val();

    if (parseInt(project) > 0) {
        search_str += 'project=' + project;
    }

    var author = jQuery('#search_board #author').val();

    if (parseInt(author) > 0) {
        if (search_str != '') {
            search_str += '&';
        }
        search_str += 'author=' + author;
    }

    var assigned_to = jQuery('#search_board #assigned_to').val();

    if (parseInt(assigned_to) > 0) {
        if (search_str != '') {
            search_str += '&';
        }
        search_str += 'assigned_to=' + assigned_to;
    }

    var url = '/kanban/board';
    
    if (search_str != '') {
        url += '?' + search_str;
    }

    location.href = url;
}

function change_board_view(view_type) {
    jQuery("#ajax-indicator").show();

    jQuery.ajax({
        "type" : "POST",
        "data" : 'authenticity_token=' + encodeURIComponent(AUTH_TOKEN) + '&board_view=' + view_type,
        "url" : '/kanban/change_board_view',
        "success" : function (result) {
            jQuery('#column1').html(result);
            jQuery("#ajax-indicator").hide();
            
            return false;
        }
    });
}