  jQuery.noConflict();

  function on_select_country(type_state, type_name) {
    new Ajax.Updater(type_state, 'state',
                     {method: 'GET',
                      parameters: {account_country: $(type_name + '_country').value},
                      onComplete: function ()
                                       {
                                         if ($(type_name + '_country').value == 'United States of America')
                                          {
                                             $(type_state).enable();
                                          }
                                         else
					  {
                                            $(type_state).disable();
                                          }
                                        }
                     }
                   );
  }

  function on_select_plan(i_plan, src) {
      new Ajax.Updater('hosted_btn_'+i_plan, 'plan',
                       {method: 'GET',
                        parameters: {plan: i_plan, src: $(src).checked}
                       }
                  );
  }


  function change_plan(type, plan, year) {
    if (confirm("Are you sure?")) {
      location.href = "subs/change_plan?type=" + type + "&plan=" + plan + "&year=" + year;
    }

    return false;
  }

  function copy_address_from_account() {
      if (jQuery("#copy_address").attr("checked")) {
        jQuery("#credit_card_country").val(jQuery("#account_country").val());
        //$("account_country").clear();
        jQuery("#credit_card_address").val(jQuery("#account_address").val());
        jQuery("#credit_card_city").val(jQuery("#account_city").val());
        jQuery("#credit_card_first_name").val(jQuery("#account_firstname").val());
        jQuery("#credit_card_last_name").val(jQuery("#account_lastname").val());

        var state = jQuery("#account_state").val();
        jQuery("#credit_card_state").empty();

        jQuery("#account_state option").each(function() {
          jQuery("#credit_card_state").append(jQuery("<option value='" + jQuery(this).val() + "'>" + jQuery(this).val() + "</option>"));
        });

        jQuery("#credit_card_state").val(state);

        if (jQuery("#account_state").val() == "--") {
            jQuery("#credit_card_state").attr("disabled", true);
        }
        else {
            jQuery("#credit_card_state").attr("disabled", false);
        }

        jQuery("#credit_card_zip").val(jQuery("#account_zip").val());
        jQuery("#credit_card_phone").val(jQuery("#account_phone").val());
      }
  }