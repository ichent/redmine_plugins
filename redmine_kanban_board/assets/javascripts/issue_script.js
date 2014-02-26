jQuery.noConflict();

jQuery(document).ready(function($){
    $('#kanban_view').change(function(){
        if ($('#kanban_view').attr('checked')) {
            $('#kanban_categories').show();
        }
        else {
            $('#kanban_categories').hide();
        }
    });
});