// --
// DynamicFieldCustomerUser.js - provides the functionality for AJAX calls of DynamicFieldCustomerUser
// Copyright (C) 2006-2017 c.a.p.e. IT GmbH, http://www.cape-it.de
//
// written/edited by:
//   Mario(dot)Illinger(at)cape(dash)it(dot)de
//
// --
// $Id$
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

/**
 * @namespace
 * @exports TargetNS as DynamicFieldCustomerUser
 * @description
 *      This namespace contains the functionality for AJAX calls of DynamicFieldCustomerUser.
 */
var DynamicFieldCustomerUser = (function (TargetNS) {

    var Identifiers = new Object();

    /**
     * @function
     * @description
     *      Initialize the edit field
     * @param {String} Identifier - The name of the field which should be initialized
     * @param {String} IdentifierID - The id of the field which should be initialized
     * @param {String} MaxArraySize - Maximum number of entries
     * @param {String} IDCounter - Initial counter for entry ids
     * @param {String} QueryDelay - Delay before autocomplete search
     * @param {String} MinQueryLength - Minimum length for autocomplete search
     * @param {String} Constriction - Semicolon separated string of constriction relevant parameters
     * @return nothing
     */
    TargetNS.InitEditField = function (Identifier, IdentifierID, MaxArraySize, IDCounter, QueryDelay, MinQueryLength, Constriction, CustomerUserInputType) {
        Identifiers[Identifier] = new Object();
        Identifiers[Identifier]['AutoCompleteField']   = Identifier + '_AutoComplete';
        Identifiers[Identifier]['ContainerField']      = Identifier + '_Container';
        Identifiers[Identifier]['ValidateField']       = Identifier + '_Validate';
        Identifiers[Identifier]['ValueField']          = Identifier + '_';
        Identifiers[Identifier]['FieldID']             = '#' + Identifier;
        Identifiers[Identifier]['AutoCompleteFieldID'] = '#' + Identifiers[Identifier]['AutoCompleteField'];
        Identifiers[Identifier]['ContainerFieldID']    = '#' + Identifiers[Identifier]['ContainerField'];
        Identifiers[Identifier]['ValidateFieldID']     = '#' + Identifiers[Identifier]['ValidateField'];
        Identifiers[Identifier]['ValueFieldID']        = '#' + Identifiers[Identifier]['ValueField'];
        Identifiers[Identifier]['IDCounter']           = IDCounter;
        Identifiers[Identifier]['MaxArraySize']        = MaxArraySize;
        Identifiers[Identifier]['MinQueryLength']      = MinQueryLength;
        Identifiers[Identifier]['QueryDelay']          = QueryDelay;
        Identifiers[Identifier]['Constriction']        = new Object();
        $("#"+Identifiers[Identifier]['AutoCompleteField']+", ."+Identifiers[Identifier]['AutoCompleteField']).each(function () {
            TargetNS.InitSearchDynamicFieldCustomerUser($(this),CustomerUserInputType);
        });
        
    };

    /**
     * @function
     * @description
     *      Initialize the edit value
     * @param {String} Identifier - The name of the field the entry belongs to
     * @param {String} Counter - The counter of the entry which should be initialized
     * @return nothing
     */
    TargetNS.InitEditValue = function (Identifier, Counter) {
        $(Identifiers[Identifier]['ValueFieldID'] + Counter).siblings('div.Remove').find('a').bind('click', function() {
            $(this).closest('.InputField_Selection').remove();
            CheckInputFields(Identifier);
            $(Identifiers[Identifier]['FieldID']).trigger('change');
            return false;
        });
    };

    /**
     * @function
     * @description
     *      Initialize the ajax update
     * @param {String} Identifier - The name of field which should be initialized
     * @param {Array} FieldsToUpdate - Array of field names that should be included
     * @return nothing
     */
    TargetNS.InitAJAXUpdate = function (Identifier, FieldsToUpdate) {
        $(Identifiers[Identifier]['FieldID']).bind('change', function (Event) {
            var CurrentValue = '';
            $('.InputField_Selection > input[name=' + Identifier + ']').each(function() {
                if (CurrentValue.length > 0) {
                    CurrentValue += ';';
                }
                CurrentValue += encodeURIComponent($(this).val());
            });
            if ($(this).data('CurrentValue') != CurrentValue) {
                $(this).data('CurrentValue', CurrentValue);
                Core.AJAX.FormUpdate($(this).parents('form'), 'AJAXUpdate', Identifier, FieldsToUpdate, function(){}, undefined, false);
            }
        });
    };

    /**
     * @private
     * @name CheckInputFields
     * @memberof DynamicFieldCustomerUser
     * @function
     * @param {String} Identifier - The name of the field
     * @returns nothing
     * @description
     *      Checks if input field should be shown or dummyfield is needed
     */
    function CheckInputFields(Identifier) {
        if ($('.InputField_Selection > input[name=' + Identifier + ']').length == 0) {
            $(Identifiers[Identifier]['ContainerFieldID']).hide().append(
                '<input class="InputField_Dummy" type="hidden" name="' + Identifier + '" value="" />'
            );
        }
        if ($('.InputField_Selection > input[name=' + Identifier + ']').length < Identifiers[Identifier]['MaxArraySize']) {
            $(Identifiers[Identifier]['AutoCompleteFieldID']).show();
        }
    }

    /**
     * @private
     * @name SerializeForm
     * @memberof DynamicFieldCustomerUser
     * @function
     * @returns {String} The query string.
     * @param {jQueryObject} $Element - The jQuery object of the form  or any element within this form that should be serialized
     * @param {Object} [Include] - Elements (Keys) which should be included in the serialized form string (optional)
     * @description
     *      Serializes the form data into a query string.
     */
    function SerializeForm($Element, Include) {
        var QueryString = "";
        if (isJQueryObject($Element) && $Element.length) {
            $Element.closest('form').find('input:not(:file), textarea, select').filter(':not([disabled=disabled])').each(function () {
                var Name = $(this).attr('name') || '';

                // only look at fields with name
                // only add element to the string, if there is no key in the data hash with the same name
                if (
                    !Name.length
                    || (
                        typeof Include !== 'undefined'
                        && typeof Include[Name] === 'undefined'
                    )
                ){
                    return;
                }

                if ($(this).is(':checkbox, :radio')) {
                    if ($(this).is(':checked')) {
                        QueryString += encodeURIComponent(Name) + '=' + encodeURIComponent($(this).val() || 'on') + ";";
                    }
                }
                else if ($(this).is('select')) {
                    $.each($(this).find('option:selected'), function(){
                        QueryString += encodeURIComponent(Name) + '=' + encodeURIComponent($(this).val() || '') + ";";
                    });
                }
                else {
                    QueryString += encodeURIComponent(Name) + '=' + encodeURIComponent($(this).val() || '') + ";";
                }
            });
        }
        return QueryString;
    };

    /**
     * @private
     * @name GetSessionInformation
     * @memberof DynamicFieldCustomerUser
     * @function
     * @returns {Object} Hash with session data, if needed.
     * @description
     *      Collects session data in a hash if available.
     */
    function GetSessionInformation() {
        var Data = {};
        if (!Core.Config.Get('SessionIDCookie')) {
            Data[Core.Config.Get('SessionName')] = Core.Config.Get('SessionID');
            Data[Core.Config.Get('CustomerPanelSessionName')] = Core.Config.Get('SessionID');
        }
        Data.ChallengeToken = Core.Config.Get('ChallengeToken');
        return Data;
    }

    /*Novo código*/

    /**
     * @private
     * @name BackupDataDFCustomerUser
     * @memberof DynamicFieldCustomerUser
     * @member {Object}
     * @description
     *      Saves Customer data for later restore.
     */
    TargetNS.BackupDataDynamicFieldCustomerUser = {
        CustomerInfo: '',
        CustomerEmail: '',
        CustomerKey: ''
    },
    /**
     * @private
     * @name CustomerFieldChangeRunCountDFCustomerUser
     * @memberof DynamicFieldCustomerUser
     * @member {Object}
     * @description
     *      Needed for the change event of customer fields, if ActiveAutoComplete is false (disabled).
     */
    TargetNS.DynamicCustomerFieldChangeRunCount = {};

    /**
     * @private
     * @name InitSearchDynamicFieldCustomerUser
     * @memberof DynamicFieldCustomerUser
     * @function
     * @param {jQueryObject} $Element - The jQuery object of the input field with autocomplete.
     * @description
     *      Initializes the module.
     */
    TargetNS.InitSearchDynamicFieldCustomerUser = function ($Element,CustomerUserInputType) {
        // get customer tickets for AgentTicketCustomer
        if (Core.Config.Get('Action') === 'AgentTicketCustomer') {
            //alert("2");
            //GetCustomerTickets($('#CustomerAutoComplete').val(), $('#CustomerID').val());

            $Element.blur(function () {
                if ($Element.val() === '') {
                    TargetNS.ResetCustomerInfo();
                    DeactivateSelectionCustomerID();
                    $('#CustomerTickets').empty();
                }
            });
        }

        // just save the initial state of the customer info
        if ($('#CustomerInfo').length) {
            TargetNS.BackupDataDynamicFieldCustomerUser.CustomerInfo = $('#CustomerInfo .Content').html();
        }

        if (isJQueryObject($Element)) {
            // Hide tooltip in autocomplete field, if user already typed something to prevent the autocomplete list
            // to be hidden under the tooltip. (Only needed for serverside errors)
            $Element.off('keyup.Validate').on('keyup.Validate', function () {
               var Value = $Element.val();
               if ($Element.hasClass('ServerError') && Value.length) {
                   $('#OTRS_UI_Tooltips_ErrorTooltip').hide();
               }
            });

            Core.App.Subscribe('Event.CustomerUserAddressBook.AddTicketCustomer.Callback.' + $Element.attr('id'), function(UserLogin, CustomerTicketText) {
                $Element.val(CustomerTicketText);
                TargetNS.AddDynamicFieldCustomer($Element.attr('id'), CustomerTicketText, UserLogin, null, CustomerUserInputType);
            });

            Core.UI.Autocomplete.Init($Element, function (Request, Response) {
                var baseUrl = Core.Config.Get('Baselink');

                if(baseUrl.indexOf("customer.pl")> -1)
                    baseUrl = baseUrl.replace("customer.pl","index.pl");
                var URL = Core.Config.Get('Baselink'),
                    Data = {
                        Action: 'AgentCustomerSearch',
                        Term: Request.term,
                        MaxResults: Core.UI.Autocomplete.GetConfig('MaxResultsDisplayed')
                    };

                $Element.data('AutoCompleteXHR', Core.AJAX.FunctionCall(URL, Data, function (Result) {
                    var ValueData = [];
                    $Element.removeData('AutoCompleteXHR');
                    $.each(Result, function () {
                        ValueData.push({
                            label: this.Label + " (" + this.Value + ")",
                            // customer list representation (see CustomerUserListFields from Defaults.pm)
                            value: this.Label,
                            // customer user id
                            key: this.Value
                        });
                    });
                    Response(ValueData);
                }));
            }, function (Event, UI) {
                var CustomerKey = UI.item.key,
                    CustomerValue = UI.item.value;

                    TargetNS.BackupDataDynamicFieldCustomerUser.CustomerKey = CustomerKey;
                    TargetNS.BackupDataDynamicFieldCustomerUser.CustomerEmail = CustomerValue;

                $Element.val(CustomerValue);

                if (
                    Core.Config.Get('Action') === 'AgentTicketEmail'
                    || Core.Config.Get('Action') === 'AgentTicketCompose'
                    || Core.Config.Get('Action') === 'AgentTicketForward'
                    || Core.Config.Get('Action') === 'AgentTicketEmailOutbound'
                    || Core.Config.Get('Action') === 'AgentTicketEmailResend'
                    )
                {
                    $Element.val('');
                }

                if (
                    Core.Config.Get('Action') !== 'AgentTicketPhone'
                    && Core.Config.Get('Action') !== 'CustomerTicketMessage'
                    && Core.Config.Get('Action') !== 'AgentTicketEmail'
                    && Core.Config.Get('Action') !== 'AgentTicketCompose'
                    && Core.Config.Get('Action') !== 'AgentTicketForward'
                    && Core.Config.Get('Action') !== 'AgentTicketEmailOutbound'
                    && Core.Config.Get('Action') !== 'AgentTicketEmailResend'
                    )
                {
                    // set hidden field SelectedCustomerUser
                    $('#SelectedCustomerUser').val(CustomerKey);

                    //ActivateSelectionCustomerID();

                    // needed for AgentTicketCustomer.pm
                    if ($('#CustomerUserID').length) {
                        $('#CustomerUserID').val(CustomerKey);
                        if ($('#CustomerUserOption').length) {
                            $('#CustomerUserOption').val(CustomerKey);
                        }
                        else {
                            $('<input type="hidden" name="CustomerUserOption" id="CustomerUserOption">').val(CustomerKey).appendTo($Element.closest('form'));
                        }
                    }

                    // get customer tickets
                    //alert("1");
                    //GetCustomerTickets(CustomerKey);

                    // get customer data for customer info table
                    //GetCustomerInfo(CustomerKey);
                }
                else {
                    TargetNS.AddDynamicFieldCustomer($(Event.target).attr('id'), CustomerValue, CustomerKey,null, CustomerUserInputType);
                }
            }, 'CustomerSearch');

            if (
                Core.Config.Get('Action') !== 'AgentTicketCustomer'
                && Core.Config.Get('Action') !== 'AgentTicketPhone'
                && Core.Config.Get('Action') !== 'AgentTicketEmail'
                && Core.Config.Get('Action') !== 'AgentTicketCompose'
                && Core.Config.Get('Action') !== 'AgentTicketForward'
                && Core.Config.Get('Action') !== 'AgentTicketEmailOutbound'
                && Core.Config.Get('Action') !== 'AgentTicketEmailResend'
                )
            {
                $Element.blur(function () {
                    var FieldValue = $(this).val();
                    if (FieldValue !== TargetNS.BackupDataDynamicFieldCustomerUser.CustomerEmail && FieldValue !== TargetNS.BackupDataDynamicFieldCustomerUser.CustomerKey) {
                        $('#SelectedCustomerUser').val('');
                        $('#CustomerUserID').val('');
                        $('#CustomerID').val('');
                        $('#CustomerUserOption').val('');
                        $('#ShowCustomerID').html('');

                        // reset customer info table
                        $('#CustomerInfo .Content').html(TargetNS.BackupDataDynamicFieldCustomerUser.CustomerInfo);

                        if (Core.Config.Get('Action') === 'AgentTicketProcess' && typeof Core.Config.Get('CustomerFieldsToUpdate') !== 'undefined') {
                            // update services (trigger ServiceID change event)
                            Core.AJAX.FormUpdate($('#CustomerID').closest('form'), 'AJAXUpdate', 'ServiceID', Core.Config.Get('CustomerFieldsToUpdate'));
                        }
                    }
                });
            }
            else {
                // initializes the customer fields
                TargetNS.InitCustomerField(CustomerUserInputType);
            }
        }

        // On unload remove old selected data. If the page is reloaded (with F5) this data
        // stays in the field and invokes an ajax request otherwise. We need to use beforeunload
        // here instead of unload because the URL of the window does not change on reload which
        // doesn't trigger pagehide.
        $(window).on('beforeunload.CustomerSearch', function () {
            $('#SelectedCustomerUser').val('');
            return; // return nothing to suppress the confirmation message
        });

        CheckPhoneCustomerCountLimit();
    };

    /**
     * @name InitCustomerField
     * @memberof DynamicFieldCustomerUser
     * @function
     * @description
     *      This function initializes the customer fields.
     */
    TargetNS.InitCustomerField = function (CustomerUserInputType) {        

        // loop over the field with CustomerAutoComplete class
        $('.CustomerAutoComplete').each(function() {
            var ObjectId = $(this).attr('id');

            $('#' + ObjectId).on('change', function () {

                if (!$('#' + ObjectId).val() || $('#' + ObjectId).val() === '') {
                    return false;
                }

                // if autocompletion is disabled and only avaible via the click
                // of a button next to the input field, we cannot handle this
                // change event the normal way.
                if (!Core.UI.Autocomplete.GetConfig('ActiveAutoComplete')) {
                    // we wait some time after this event to check, if the search button
                    // for this field was pressed. If so, no action is needed
                    // If the change event was fired without clicking the search button,
                    // probably the user clicked out of the field.
                    // This should also add the customer (the enetered value) to the list

                    if (typeof TargetNS.DynamicCustomerFieldChangeRunCount[ObjectId] === 'undefined') {
                        TargetNS.DynamicCustomerFieldChangeRunCount[ObjectId] = 1;
                    }
                    else {
                        TargetNS.DynamicCustomerFieldChangeRunCount[ObjectId]++;
                    }

                    if (Core.UI.Autocomplete.SearchButtonClicked[ObjectId]) {
                        delete TargetNS.DynamicCustomerFieldChangeRunCount[ObjectId];
                        delete Core.UI.Autocomplete.SearchButtonClicked[ObjectId];
                        return false;
                    }
                    else {
                        if (TargetNS.DynamicCustomerFieldChangeRunCount[ObjectId] === 1) {
                            window.setTimeout(function () {
                                $('#' + ObjectId).trigger('change');
                            }, 200);
                            return false;
                        }
                        delete TargetNS.DynamicCustomerFieldChangeRunCount[ObjectId];
                    }
                }


                // If the autocomplete popup window is visible, delay this change event.
                // It might be caused by clicking with the mouse into the autocomplete list.
                // Wait until it is closed to be sure that we don't add a customer twice.

                if ($(this).autocomplete("widget").is(':visible')) {
                    window.setTimeout(function(){
                        $('#' + ObjectId).trigger('change');
                    }, 200);
                    return false;
                }

                TargetNS.AddDynamicFieldCustomer(ObjectId, $('#' + ObjectId).val(),null,null, CustomerUserInputType);
                return false;
            });

            $('#' + ObjectId).on('keypress', function (e) {
                if (e.which === 13){
                    TargetNS.AddDynamicFieldCustomer(ObjectId, $('#' + ObjectId).val(),null,null,CustomerUserInputType);
                    return false;
                }
            });
        });
    };

    /**
     * @private
     * @name CheckPhoneCustomerCountLimit
     * @memberof DynamicFieldCustomerUser
     * @function
     * @description
     *      In AgentTicketPhone, this checks if more than one entry is allowed
     *      in the customer list and blocks/unblocks the autocomplete field as needed.
     */
    function CheckPhoneCustomerCountLimit() {

        // Only operate in AgentTicketPhone
        if (Core.Config.Get('Action') !== 'AgentTicketPhone') {
            return;
        }

        // Check if multiple from entries are allowed
        if (parseInt(Core.Config.Get('CustomerSearch').AllowMultipleFrom, 10)) {
            return;
        }

        if ($('#TicketCustomerContentFromCustomer input.'+Field+'-DynamicCustomerText').length > 0) {
            $('#FromCustomer').val('').prop('disabled', true).prop('readonly', true);
            $('#Dest').trigger('focus');
        }
        else {
            $('#FromCustomer').val('').prop('disabled', false).prop('readonly', false);
        }
    }

    function htmlDecode(Text){
        return Text.replace(/&amp;/g, '&');
    }

    /**
     * @name AddTicketCustomer
     * @memberof DynamicFieldCustomerUser
     * @function
     * @returns {Boolean} Returns false.
     * @param {String} Field
     * @param {String} CustomerValue - The readable customer identifier.
     * @param {String} CustomerKey - Customer key on system.
     * @param {String} SetAsTicketCustomer -  Set this customer as main ticket customer.
     * @description
     *      This function adds a new ticket customer
     */
    TargetNS.AddDynamicFieldCustomer = function (Field, CustomerValue, CustomerKey, SetAsTicketCustomer, CustomerUserInputType) {
        
        var $Clone = $('.CustomerTicketTemplate' + Field).clone(),
            CustomerTicketCounter = $('#CustomerTicketCounter' + Field).val(),
            TicketCustomerIDs = 0,
            IsDuplicated = false,
            IsFocused = ($(document.activeElement).attr('id') == Field),
            Suffix;

        if (typeof CustomerKey !== 'undefined') {
            CustomerKey = htmlDecode(CustomerKey);
        }

        if (CustomerValue === '') {
            return false;
        }

        if($('[class*='+Field+'-DynamicCustomerText]').length> 1 && CustomerUserInputType === "Single contact"){
            return false;
        }
            

        // check for duplicated entries
        $('[class*='+Field+'-DynamicCustomerText]').each(function() {
            if ($(this).val() === CustomerValue) {
                IsDuplicated = true;
            }
        });
        if (IsDuplicated) {

            alert('Entrou aqui');
            TargetNS.ShowDuplicatedDialog(Field);
            return false;
        }

        // get number of how much customer ticket are present
        TicketCustomerIDs = $('.CustomerContainer'+Field+' input[type="radio"]').length;

        // increment customer counter
        CustomerTicketCounter++;

        // set sufix
        Suffix = '_' + CustomerTicketCounter;

        // remove unnecessary classes
        $Clone.removeClass('Hidden CustomerTicketTemplate' + Field);

        // copy values and change ids and names
        $Clone.find(':input, a').each(function(){
            var ID = $(this).attr('id');
            $(this).attr('id', ID + Suffix);
            $(this).val(CustomerValue);
            if (ID !== 'CustomerSelected'+ Field) {
                $(this).attr('name', ID + Suffix);
            }

            // add event handler to radio button
            if($(this).hasClass('CustomerTicketRadio'+ Field)) {

                if (TicketCustomerIDs === 0) {
                    $(this).prop('checked', true);
                }

                // set counter as value
                $(this).val(CustomerTicketCounter);

                // bind change function to radio button to select customer
                $(this).on('change', function () {
                    // remove row
                    if ($(this).prop('checked')){
                        //TargetNS.ReloadCustomerInfo(CustomerKey);
                    }
                    return false;
                });
            }

            // set customer key if present
            if($(this).hasClass('CustomerKey'+ Field)) {
                $(this).val(CustomerKey);

                var o = new Option(CustomerKey, CustomerKey);
                /// jquerify the DOM object 'o' so we can use the html method
                $(o).html(CustomerKey);
                $("#"+Field.replace("_AutoComplete","")).append(o);
                $("#"+Field.replace("_AutoComplete","")+" option[value=\""+CustomerKey+"\"]").attr('selected', 'selected');
            }

            

            // add event handler to remove button
            if($(this).hasClass('RemoveButton'+ Field)) {

                // bind click function to remove button
                $(this).on('click', function () {
                    // remove row
                    TargetNS.RemoveCustomerTicket($(this),Field,CustomerKey);

                    // clear CustomerHistory table if there are no selected customer users
                    if ($('#TicketCustomerContent' + Field + ' .CustomerTicketRadio'+ Field).length === 0) {
                        $('#CustomerTickets'+ Field).empty();
                    }
                    return false;
                });
                // set button value
                $(this).val(CustomerValue);
            }

        });
        // show container
        $('#TicketCustomerContent' + Field).parent().removeClass('Hidden');
        // append to container
        $('#TicketCustomerContent' + Field).append($Clone);

        // set new value for CustomerTicketCounter
        $('#CustomerTicketCounter' + Field).val(CustomerTicketCounter);
        if ((CustomerKey !== '' && TicketCustomerIDs === 0 && (Field === 'ToCustomer' || Field === 'FromCustomer')) || SetAsTicketCustomer) {
            if (SetAsTicketCustomer) {
                $('#CustomerSelected'+Field+'_' + CustomerTicketCounter).prop('checked', true).trigger('change');
            }
            else {
                $('.CustomerContainer'+Field+' input[type="radio"]:first').prop('checked', true).trigger('change');
            }
        }

        // Return the value to the search field.
        $('#' + Field).val('');

        // Re-focus the field, but only if it was previously focused.
        if (IsFocused) {
            $('#' + Field).focus();
        }

        //CheckPhoneCustomerCountLimit();

        // Reload Crypt options on specific screens.
        if (
            (
                Core.Config.Get('Action') === 'AgentTicketEmail'
                || Core.Config.Get('Action') === 'AgentTicketCompose'
                || Core.Config.Get('Action') === 'AgentTicketForward'
                || Core.Config.Get('Action') === 'AgentTicketEmailOutbound'
                || Core.Config.Get('Action') === 'AgentTicketEmailResend'
            )
            && $('#CryptKeyID').length
            )
        {
            Core.AJAX.FormUpdate($('#' + Field).closest('form'), 'AJAXUpdate', '', ['CryptKeyID']);
        }

        // now that we know that at least one customer has been added,
        // we can remove eventual errors from the customer field
        $('#FromCustomer, #ToCustomer')
            .removeClass('Error ServerError')
            .closest('.Field')
            .prev('label')
            .removeClass('LabelError');
        Core.Form.ErrorTooltips.HideTooltip();

        return false;
    }; 

    /**
     * @name RemoveCustomerTicket
     * @memberof DynamicFieldCustomerUser
     * @function
     * @param {jQueryObject} Object - JQuery object used as base to delete it's parent.
     * @description
     *      This function removes a customer ticket entry.
     */
    TargetNS.RemoveCustomerTicket = function (Object, Field,CustomerKey) {
        var TicketCustomerIDs = 0,
        $Field = Object.closest('.Field'),
        $Form;

        if (
            Core.Config.Get('Action') === 'AgentTicketEmail'
            || Core.Config.Get('Action') === 'AgentTicketCompose'
            || Core.Config.Get('Action') === 'AgentTicketForward'
            || Core.Config.Get('Action') === 'AgentTicketEmailOutbound'
            || Core.Config.Get('Action') === 'AgentTicketEmailResend'
            )
        {
            $Form = Object.closest('form');
        }
        console.log("sss",CustomerKey);

        $("#"+Field.replace("_AutoComplete","")+" option[value='"+CustomerKey+"']").remove();

        Object.parent().remove();
        TicketCustomerIDs = $('.CustomerContainer'+Field+' input[type="radio"]').length;
        if (TicketCustomerIDs === 0) {
            //TargetNS.ResetCustomerInfo();
        }

        // Reload Crypt options on specific screens.
        if (
            (
                Core.Config.Get('Action') === 'AgentTicketEmail'
                || Core.Config.Get('Action') === 'AgentTicketCompose'
                || Core.Config.Get('Action') === 'AgentTicketForward'
                || Core.Config.Get('Action') === 'AgentTicketEmailOutbound'
                || Core.Config.Get('Action') === 'AgentTicketEmailResend'
            )
            && $('#CryptKeyID').length
            )
        {
            Core.AJAX.FormUpdate($Form, 'AJAXUpdate', '', ['CryptKeyID']);
        }

        if(!$('.CustomerContainer'+Field+' input[type="radio"]').is(':checked')){
            //set the first one as checked
            $('.CustomerContainer'+Field+' input[type="radio"]:first').prop('checked', true).trigger('change');
        }

        if ($Field.find('.'+Field+'-DynamicCustomerText:visible').length === 0) {
            $Field.addClass('Hidden');

            //DeactivateSelectionCustomerID();
        }

        //CheckPhoneCustomerCountLimit();
    };

    /**
     * @name ShowDuplicatedDialog
     * @memberof DynamicFieldCustomerUser
     * @function
     * @param {String} Field - ID object of the element should receive the focus on close event.
     * @description
     *      This function shows an alert dialog for duplicated entries.
     */
    TargetNS.ShowDuplicatedDialog = function(Field){
        Core.UI.Dialog.ShowAlert(
            Core.Language.Translate('Duplicated entry'),
            Core.Language.Translate('This address already exists on the address list.') + ' ' + Core.Language.Translate('It is going to be deleted from the field, please try again.'),
            function () {
                Core.UI.Dialog.CloseDialog($('.Alert'));
                $('#' + Field).val('');
                $('#' + Field).focus();
                return false;
            }
        );
    };

    return TargetNS;
}(DynamicFieldCustomerUser || {}));
