# --
# Kernel/System/DynamicField/Driver/CustomerUserReference.pm - Delegate for DynamicField ITSMConfigItemReference backend
# Copyright (C) 2006-2017 c.a.p.e. IT GmbH, http://www.cape-it.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::Driver::CustomerUserReference;

use strict;
use warnings;

use Data::Dumper;

use base qw(Kernel::System::DynamicField::Driver::Base);

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::DynamicFieldValue',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Ticket::ColumnFilter',
);

=head1 NAME

Kernel::System::DynamicField::Driver::CustomerUserReference

=head1 SYNOPSIS

DynamicFields ITSMConfigItemReference backend delegate

=head1 PUBLIC INTERFACE

This module implements the public interface of L<Kernel::System::DynamicField::Backend>.
Please look there for a detailed reference of the functions.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # create additional objects
    $Self->{ConfigObject}            = $Kernel::OM->Get('Kernel::Config');
    $Self->{DynamicFieldValueObject} = $Kernel::OM->Get('Kernel::System::DynamicFieldValue');

    # get the fields config
    $Self->{FieldTypeConfig} = $Self->{ConfigObject}->Get('DynamicFields::Driver') || {};

    # set field behaviors
    $Self->{Behaviors} = {
        'IsACLReducible'               => 0,
        'IsNotificationEventCondition' => 1,
        'IsSortable'                   => 1,
        'IsFiltrable'                  => 1,
        'IsStatsCondition'             => 1,
        'IsCustomerInterfaceCapable'   => 1,
    };

    # get the Dynamic Field Backend custom extensions
    my $DynamicFieldDriverExtensions = $Self->{ConfigObject}->Get('DynamicFields::Extension::Driver::CustomerUserReference');

    EXTENSION:
    for my $ExtensionKey ( sort keys %{$DynamicFieldDriverExtensions} ) {

        # skip invalid extensions
        next EXTENSION if !IsHashRefWithData( $DynamicFieldDriverExtensions->{$ExtensionKey} );

        # create a extension config shortcut
        my $Extension = $DynamicFieldDriverExtensions->{$ExtensionKey};

        # check if extension has a new module
        if ( $Extension->{Module} ) {

            # check if module can be loaded
            if (
                !$Kernel::OM->Get('Kernel::System::Main')->RequireBaseClass( $Extension->{Module} )
                )
            {
                die "Can't load dynamic fields backend module"
                    . " $Extension->{Module}! $@";
            }
        }

        # check if extension contains more behaviors
        if ( IsHashRefWithData( $Extension->{Behaviors} ) ) {

            %{ $Self->{Behaviors} } = (
                %{ $Self->{Behaviors} },
                %{ $Extension->{Behaviors} }
            );
        }
    }

    return $Self;
}

sub ValueGet {
    my ( $Self, %Param ) = @_;

    my $DFValue = $Self->{DynamicFieldValueObject}->ValueGet(
        FieldID  => $Param{DynamicFieldConfig}->{ID},
        ObjectID => $Param{ObjectID},
    );

    return if !$DFValue;
    return if !IsArrayRefWithData($DFValue);
    return if !IsHashRefWithData( $DFValue->[0] );

    # extract real values
    my @ReturnData;
    for my $Item ( @{$DFValue} ) {
        push @ReturnData, $Item->{ValueText}
    }

    return \@ReturnData;
}

sub ValueSet {
    my ( $Self, %Param ) = @_;

    # check value
    my @Values;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    my $Success;
    if ( IsArrayRefWithData( \@Values ) ) {

        # if there is at least one value to set, this means one or more values are selected,
        #    set those values!
        my @ValueText;
        for my $Item (@Values) {
            push @ValueText, { ValueText => $Item };
        }

        $Success = $Self->{DynamicFieldValueObject}->ValueSet(
            FieldID  => $Param{DynamicFieldConfig}->{ID},
            ObjectID => $Param{ObjectID},
            Value    => \@ValueText,
            UserID   => $Param{UserID},
        );
    }
    else {

        # otherwise no value was selected, then in fact this means that any value there should be
        # deleted
        $Success = $Self->{DynamicFieldValueObject}->ValueDelete(
            FieldID  => $Param{DynamicFieldConfig}->{ID},
            ObjectID => $Param{ObjectID},
            UserID   => $Param{UserID},
        );
    }

    return $Success;
}

sub ValueLookup {
    my ( $Self, %Param ) = @_;

    my @Keys;
    if ( ref $Param{Key} eq 'ARRAY' ) {
        @Keys = @{ $Param{Key} };
    }
    else {
        @Keys = ( $Param{Key} );
    }

    # to store final values
    my @Values;

    KEYITEM:
    for my $Item ( @Keys ) {
        next KEYITEM if !$Item;

        # set the value as the key by default
        my $Value = $Item;
    }

    return \@Values;
}

sub ValueIsDifferent {
    my ( $Self, %Param ) = @_;

    # special cases where the values are different but they should be reported as equals
    if (
        !defined $Param{Value1}
        && ref $Param{Value2} eq 'ARRAY'
        && !IsArrayRefWithData( $Param{Value2} )
        )
    {
        return
    }
    if (
        !defined $Param{Value2}
        && ref $Param{Value1} eq 'ARRAY'
        && !IsArrayRefWithData( $Param{Value1} )
        )
    {
        return
    }

    # compare the results
    return DataIsDifferent(
        Data1 => \$Param{Value1},
        Data2 => \$Param{Value2}
    );
}

sub ValueValidate {
    my ( $Self, %Param ) = @_;

    # check value
    my @Values;
    if ( IsArrayRefWithData( $Param{Value} ) ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    my $Success;
    for my $Item (@Values) {

        $Success = $Self->{DynamicFieldValueObject}->ValueValidate(
            Value => {
                ValueText => $Item,
            },
            UserID => $Param{UserID}
        );

        return if !$Success
    }

    return $Success;
}

sub PossibleValuesGet {
    my ( $Self, %Param ) = @_;

    my %PossibleValues;
    

    # return the possible values hash as a reference
    return \%PossibleValues;
}

sub TemplateValueTypeGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    # set the field types
    my $EditValueType   = 'ARRAY';
    my $SearchValueType = 'ARRAY';

    # return the correct structure
    if ( $Param{FieldType} eq 'Edit' ) {
        return {
            $FieldName => $EditValueType,
        }
    }
    elsif ( $Param{FieldType} eq 'Search' ) {
        return {
            'Search_' . $FieldName => $SearchValueType,
        }
    }
    else {
        return {
            $FieldName             => $EditValueType,
            'Search_' . $FieldName => $SearchValueType,
        }
    }
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldID     = $Param{DynamicFieldConfig}->{ID};
    my $FieldName   = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel  = $Param{DynamicFieldConfig}->{Label};

    my @Data = $Param{ParamObject}->GetArray( Param => $FieldName );   

    my $Value;

    # set the field value or default
    if ( $Param{UseDefaultValue} ) {
        $Value = ( defined $FieldConfig->{DefaultValues} ? $FieldConfig->{DefaultValues} : '' );
    }
    $Value = $Param{Value} // $Value;

    # check if a value in a template (GenericAgent etc.)
    # is configured for this dynamic field
    if (
        IsHashRefWithData( $Param{Template} )
        && defined $Param{Template}->{$FieldName}
        )
    {
        $Value = $Param{Template}->{$FieldName};
    }

    # extract the dynamic field value form the web request
    my $FieldValue = $Self->EditFieldValueGet(
        %Param,
    );

    # set values from ParamObject if present
    if ( IsArrayRefWithData($FieldValue) ) {
        $Value = $FieldValue;
    }

    # check and set class if necessary
    my $FieldClass = '';
    if ( defined $Param{Class} && $Param{Class} ne '' ) {
        $FieldClass = $Param{Class};
    }

    # set field as mandatory
    if ( $Param{Mandatory} ) {
        $FieldClass .= ' Validate_Required';
    }

    # set error css class
    if ( $Param{ServerError} ) {
        $FieldClass .= ' ServerError';
    }

    

    # check value
    my $SelectedValuesArrayRef = [];
    if ( defined $Value ) {
        if ( ref $Value eq 'ARRAY' ) {
            $SelectedValuesArrayRef = $Value;
        }
        else {
            $SelectedValuesArrayRef = [$Value];
        }
    }

    my $AutoCompleteFieldName = $FieldName . "_AutoComplete";
    my $ContainerFieldName    = $FieldName . "_Container";
    my $DisplayFieldName      = $FieldName . "_Display";
    my $IDCounterName         = $FieldName . "_IDCount";
    my $ValidateFieldName     = $FieldName . "_Validate";
    my $ValueFieldName        = $FieldName . "_";

    my $MaxArraySize          = $FieldConfig->{MaxArraySize} || 1;

    # get used Constrictions
    my $ConstrictionString = $FieldName . ';TicketID';
    my $Constrictions      = $Param{DynamicFieldConfig}->{Config}->{Constrictions};
    if ( $Constrictions ) {
        my $CustomerConstriction = 0;
        my @Constrictions = split(/[\n\r]+/, $Constrictions);
        CONSTRICTION:
        for my $Constriction ( @Constrictions ) {
            my @ConstrictionRule = split(/::/, $Constriction);
            # check for valid constriction
            next CONSTRICTION if (
                scalar(@ConstrictionRule) != 4
                || $ConstrictionRule[0] eq ""
                || $ConstrictionRule[1] eq ""
                || $ConstrictionRule[2] eq ""
            );
            # only handle static constrictions in admininterface
            if (
                $ConstrictionRule[1] eq 'Ticket'
            ) {
                $ConstrictionString .= ';' . $ConstrictionRule[2];
            }
            elsif (
                $ConstrictionRule[1] eq 'CustomerUser'
            ) {
                $CustomerConstriction = 1;
            }
        }
        if ( $CustomerConstriction ) {
            $ConstrictionString .= ';CustomerUserID;SelectedCustomerUser';
        }
    }

    my $TranslateRemoveSelection = $Param{LayoutObject}->{LanguageObject}->Translate("Remove selection");

    my $FromInvalid = "";
    my $CustomerHiddenContainer = "Hidden";

    my $HTMLString = <<"END";
    <style>
        .CustomerContainer$AutoCompleteFieldName,.CcCustomerContainer$AutoCompleteFieldName,.BccCustomerContainer$AutoCompleteFieldName
        {
            background-color:#F2F2F2;
            border:1px solid #CCCCCC;
            -moz-box-shadow:inset 1px 1px 5px #ccc;
            -webkit-box-shadow:inset 1px 1px 5px #ccc;
            box-shadow:inset 1px 1px 5px #ccc;
            padding:5px 7px 10px 6px;width:74%;
            position:relative;-moz-border-radius:2px;
            -webkit-border-radius:2px;border-radius:2px;
        }
        .CustomerContainer$AutoCompleteFieldName > div,.CcCustomerContainer$AutoCompleteFieldName > div,.BccCustomerContainer$AutoCompleteFieldName > div
        {
            margin-top:5px;
        }
        .CustomerContainer$AutoCompleteFieldName .$AutoCompleteFieldName-DynamicCustomerText,.CcCustomerContainer$AutoCompleteFieldName .$AutoCompleteFieldName-DynamicCustomerText,.BccCustomerContainer$AutoCompleteFieldName .$AutoCompleteFieldName-DynamicCustomerText
        {
            width:89%;
            margin-left:7px;
        }
        .CustomerContainer$AutoCompleteFieldName .$AutoCompleteFieldName-DynamicCustomerText
        {
            transition:background-color 1s ease,border 1s ease;
        }
        .CustomerContainer$AutoCompleteFieldName .$AutoCompleteFieldName-DynamicCustomerText.MainCustomer
        {
            background-color:#F7ECC3;
            border:1px solid #E8CC8B;
        }
        .CustomerContainer$AutoCompleteFieldName .$AutoCompleteFieldName-DynamicCustomerText.Radio
        {
            width:84%;
            margin-left:0px;
        }
        .CustomerContainer$AutoCompleteFieldName .BoxLabel,.CcCustomerContainer$AutoCompleteFieldName .BoxLabel,.BccCustomerContainer$AutoCompleteFieldName .BoxLabel
        {
            background-color:#CCCCCC;
            font-size:11px;
            right:100%;
            top:10px;
            padding:0 5px;
            position:absolute;
            text-align:center;
            text-shadow:1px 1px 1px #FFFFFF;
            min-width:20px;
            color:#555;
        }
    </style>
    <div class="Field $FieldClass">
        <select class="DynamicFieldText Modernize $FieldClass" id="$FieldName" multiple="multiple" name="$FieldName" style="display:none;" ></select>
        <input id="$AutoCompleteFieldName" type="text" name="$AutoCompleteFieldName" value="" class="$AutoCompleteFieldName W75pc $FromInvalid" autocomplete="off" />
        <div id="$AutoCompleteFieldName-ServerError" class="TooltipErrorMessage">
        </div>
    </div>
    <div class="clear"></div>
    <div class="Field $CustomerHiddenContainer">
        <div class="CustomerTicketTemplate$AutoCompleteFieldName SpacingTopSmall Hidden">
            <input style="display:none;" name="CustomerSelected$AutoCompleteFieldName" title="Select this customer as the main customer." id="CustomerSelected$AutoCompleteFieldName" class="CustomerTicketRadio$AutoCompleteFieldName" type="radio" value=""/>
            <input name="CustomerKey$AutoCompleteFieldName" id="CustomerKey$AutoCompleteFieldName" class="CustomerKey$AutoCompleteFieldName" type="hidden" value=""/>
            <input class="$AutoCompleteFieldName-DynamicCustomerText Radio" title="Customer user name="$AutoCompleteFieldName-DynamicCustomerText" id="$AutoCompleteFieldName-DynamicCustomerText" type="text" value="" readonly="readonly" />
            <a href="#" id="RemoveCustomerTicket" class="RemoveButton$AutoCompleteFieldName CustomerTicketRemove">
                <i class="fa fa-minus-square-o"></i>
                <span class="InvisibleText">Remove Ticket Customer User</span>
            </a>
        </div>
        <div id="TicketCustomerContent$AutoCompleteFieldName" class="CustomerContainer$AutoCompleteFieldName">
END
#
    my $typeField = "Single customer";
    my $CustomerSelected = "";
    my $CustomerDisabled = "";
    my $Count = "";
    my $CustomerElement = "";

    if($typeField eq  "Multiple customers"){
        $HTMLString .= <<"END";
            <div class="SpacingTopSmall ">
                <input name="CustomerSelected$AutoCompleteFieldName" title="Select this customer as the main customer." id="CustomerSelected$AutoCompleteFieldName" class="CustomerTicketRadio$AutoCompleteFieldName" type="radio" value="$Count" $CustomerSelected  $CustomerDisabled />
                <input name="CustomerKey$AutoCompleteFieldName\_[% Data.Count | html %]" id="CustomerKey$AutoCompleteFieldName\_[% Data.Count | html %]" class="CustomerKey$AutoCompleteFieldName" type="hidden" value="[% Data.CustomerKey | html %]"/>
                <input class="$AutoCompleteFieldName-DynamicCustomerText Radio" title="Customer user name="$AutoCompleteFieldName-DynamicCustomerText_$Count" id="$AutoCompleteFieldName-DynamicCustomerText_$Count" type="text" value="$CustomerElement" readonly="readonly" />
                <a href="#" id="RemoveCustomerTicket_[% Data.Count %]" class="RemoveButton$AutoCompleteFieldName CustomerTicketRemove">
                    <i class="fa fa-minus-square-o"></i>
                    <span class="InvisibleText">Remove Ticket Customer User</span>
                </a>
            </div>
END
    }

    $HTMLString .= "</div>";

    my $MultipleCustomerCounter = 1;
    my $CustomerCounter = 0;

    if($MultipleCustomerCounter){
        $HTMLString .= <<"END";
        <input name="CustomerTicketCounter$AutoCompleteFieldName" id="CustomerTicketCounter$AutoCompleteFieldName" type="hidden" value="$CustomerCounter"/>
END
    }

    $HTMLString .= "</div>";

    my $ValueCounter = 0;
    my $ValidValue = "";
    if($ValueCounter){
       $ValidValue = '1';
    }

    #TargetNS.AddDynamicFieldCustomer($(Event.target).attr('id'), CustomerValue, CustomerKey,null, CustomerUserInputType);

     $HTMLString .= <<"END";
     <script type="language">
         Core.Config.Set('DynamicFieldCustomerUser.TranslateRemoveSelection', '$TranslateRemoveSelection');
         DynamicFieldCustomerUser.InitEditField("$FieldName", "$FieldID", "$MaxArraySize", "$ValueCounter", "$FieldConfig->{QueryDelay}", "$FieldConfig->{MinQueryLength}", "$ConstrictionString", "$FieldConfig->{CustomerUserInputType}");
END


    ITEM:
    for my $Item ( sort @Data ) {
        my %CustomerData = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $Item,
        );

        my $completeName = "$CustomerData{UserFirstname} $CustomerData{UserLastname} <$CustomerData{UserEmail}>";

        $HTMLString .= <<"END";
        DynamicFieldCustomerUser.AddDynamicFieldCustomer("$FieldName\_AutoComplete","$completeName","$Item",null,"$FieldConfig->{CustomerUserInputType}");
END
        #$Kernel::OM->Get('Kernel::System::Log')->Log(
        #    Priority => 'error',
        #    Message  => "Item ".Dumper($Item),
        #);
    }

    $HTMLString .= 
     "</script>";

    $Param{LayoutObject}->AddJSOnDocumentComplete( Code => <<"END");
Core.Config.Set('DynamicFieldCustomerUser.TranslateRemoveSelection', '$TranslateRemoveSelection');
DynamicFieldCustomerUser.InitEditField("$FieldName", "$FieldID", "$MaxArraySize", "$ValueCounter", "$FieldConfig->{QueryDelay}", "$FieldConfig->{MinQueryLength}", "$ConstrictionString", "$FieldConfig->{CustomerUserInputType}");
END

    my $JSValueCounter = 0;
    for my $Key ( @{ $SelectedValuesArrayRef } ) {
        next if (!$Key);
        $JSValueCounter++;

        $Param{LayoutObject}->AddJSOnDocumentComplete( Code => <<"END");
DynamicFieldCustomerUser.InitEditValue("$FieldName", "$JSValueCounter");
END
    }

    if ( $Param{Mandatory} ) {
        my $DivID = $FieldName . 'Error';

        my $FieldRequiredMessage = $Param{LayoutObject}->{LanguageObject}->Translate("This field is required.");

        # for client side validation
        $HTMLString .= <<"END";
        <div id="$DivID" class="TooltipErrorMessage">
            <p>
                $FieldRequiredMessage
            </p>
        </div>
END
    }

    if ( $Param{ServerError} ) {

        my $ErrorMessage = $Param{ErrorMessage} || 'This field is required.';
        $ErrorMessage = $Param{LayoutObject}->{LanguageObject}->Translate($ErrorMessage);
        my $DivID = $FieldName . 'ServerError';

        # for server side validation
        $HTMLString .= <<"END";
        <div id="$DivID" class="TooltipErrorMessage">
            <p>
                $ErrorMessage
            </p>
        </div>
END
    }

    if ( $Param{AJAXUpdate} ) {

        my $FieldSelector = '#' . $FieldName;

        my $FieldsToUpdate;
        if ( IsArrayRefWithData( $Param{UpdatableFields} ) ) {

            # Remove current field from updatable fields list
            my @FieldsToUpdate = grep { $_ ne $FieldName } @{ $Param{UpdatableFields} };

            # quote all fields, put commas in between them
            $FieldsToUpdate = join( ', ', map {"'$_'"} @FieldsToUpdate );
        }

        # add js to call FormUpdate()
        $Param{LayoutObject}->AddJSOnDocumentComplete( Code => <<"END");
DynamicFieldCustomerUser.InitAJAXUpdate("$FieldName", [ $FieldsToUpdate ]);
END
    }

    # call EditLabelRender on the common Driver
    my $LabelString = $Self->EditLabelRender(
        %Param,
        Mandatory => $Param{Mandatory} || '0',
        FieldName => $FieldName,
    );

    my $Data = {
        Field => $HTMLString,
        Label => $LabelString,
    };

    return $Data;
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    my $Value;

    # check if there is a Template and retrieve the dynamic field value from there
    if ( IsHashRefWithData( $Param{Template} ) ) {
        $Value = $Param{Template}->{$FieldName};
    }

    # otherwise get dynamic field value from the web request
    elsif (
        defined $Param{ParamObject}
        && ref $Param{ParamObject} eq 'Kernel::System::Web::Request'
        )
    {
        my @Data = $Param{ParamObject}->GetArray( Param => $FieldName );

        # delete empty values (can happen if the user has selected the "-" entry)
        my $Index = 0;
        ITEM:
        for my $Item ( sort @Data ) {

            if ( !$Item ) {
                splice( @Data, $Index, 1 );
                next ITEM;
            }
            $Index++;
        }

        $Value = \@Data;
    }

    if ( defined $Param{ReturnTemplateStructure} && $Param{ReturnTemplateStructure} eq 1 ) {
        return {
            $FieldName => $Value,
        };
    }

    # for this field the normal return an the ReturnValueStructure are the same
    return $Value;
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    # get the field value from the http request
    my $Values = $Self->EditFieldValueGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        ParamObject        => $Param{ParamObject},

        # not necessary for this Driver but place it for consistency reasons
        ReturnValueStructure => 1,
    );

    my $ServerError;
    my $ErrorMessage;

    # create resulting structure
    my $Result = {
        ServerError  => $ServerError,
        ErrorMessage => $ErrorMessage,
    };

    return $Result;
}

sub SearchFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldID     = $Param{DynamicFieldConfig}->{ID};
    my $FieldName   = 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel  = $Param{DynamicFieldConfig}->{Label};

    my $Value;
    my @DefaultValue;

    if ( defined $Param{DefaultValue} ) {
        @DefaultValue = split /;/, $Param{DefaultValue};
    }

    # set the field value
    if (@DefaultValue) {
        $Value = \@DefaultValue;
    }

    # get the field value, this function is always called after the profile is loaded
    my $FieldValue = $Self->SearchFieldValueGet(%Param);

    # set values from ParamObject if present
    if ( IsArrayRefWithData($FieldValue) ) {
        $Value = $FieldValue;
    }

    # check and set class if necessary

    my $FieldClass = '';
    if ( defined $Param{Class} && $Param{Class} ne '' ) {
        $FieldClass = $Param{Class};
    }

    my $AutoCompleteFieldName = $FieldName . "_AutoComplete";
    my $ContainerFieldName    = $FieldName . "_Container";
    my $DisplayFieldName      = $FieldName . "_Display";
    my $IDCounterName         = $FieldName . "_IDCount";
    my $ValueFieldName        = $FieldName . "_";

    my $MaxArraySize          = $FieldConfig->{MaxArraySize} || 1;

    my $TranslateRemoveSelection = $Param{LayoutObject}->{LanguageObject}->Translate("Remove selection");

    my $HTMLString = <<"END";
    <div class="InputField_Container W50pc">
        <input id="$AutoCompleteFieldName" type="text" style="margin-bottom:2px;" />
        <div class="Clear"></div>
        <div id="$ContainerFieldName" class="InputField_InputContainer" style="display:block;">
END


    # call EditLabelRender on the common Driver
    my $LabelString = $Self->EditLabelRender(
        %Param,
        FieldName => $FieldName,
    );

    my $Data = {
        Field => $HTMLString,
        Label => $LabelString,
    };

    return $Data;
}

sub SearchFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $Value;

    # get dynamic field value from param object
    if ( defined $Param{ParamObject} ) {
        my @FieldValues = $Param{ParamObject}->GetArray(
            Param => 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name}
        );

        $Value = \@FieldValues;
    }

    # otherwise get the value from the profile
    elsif ( defined $Param{Profile} ) {
        $Value = $Param{Profile}->{ 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name} };
    }
    else {
        return;
    }

    if ( defined $Param{ReturnProfileStructure} && $Param{ReturnProfileStructure} eq 1 ) {
        return {
            'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name} => $Value,
        };
    }

    return $Value;
}

sub SearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    # get field value
    my $Value = $Self->SearchFieldValueGet(%Param);

    my $DisplayValue;

    if ( defined $Value && !$Value ) {
        $DisplayValue = '';
    }

    if ($Value) {
        if ( ref $Value eq 'ARRAY' ) {

            my @DisplayItemList;
            for my $Item ( @{$Value} ) {

            }

            # combine different values into one string
            $DisplayValue = join ' + ', @DisplayItemList;
        }
        else {

            
        }
    }

    # return search parameter structure
    return {
        Parameter => {
            Equals => $Value,
        },
        Display => $DisplayValue,
    };
}

sub SearchSQLGet {
    my ( $Self, %Param ) = @_;

    my %Operators = (
        Equals            => '=',
        GreaterThan       => '>',
        GreaterThanEquals => '>=',
        SmallerThan       => '<',
        SmallerThanEquals => '<=',
    );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Operators{ $Param{Operator} } ) {
        my $SQL = " $Param{TableAlias}.value_text $Operators{$Param{Operator}} '";
        $SQL .= $DBObject->Quote( $Param{SearchTerm} ) . "' ";
        return $SQL;
    }

    if ( $Param{Operator} eq 'Like' ) {

        my $SQL = $DBObject->QueryCondition(
            Key   => "$Param{TableAlias}.value_text",
            Value => $Param{SearchTerm},
        );

        return $SQL;
    }

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        'Priority' => 'error',
        'Message'  => "Unsupported Operator $Param{Operator}",
    );

    return;
}

sub SearchSQLOrderFieldGet {
    my ( $Self, %Param ) = @_;

    return "$Param{TableAlias}.value_text";
}

sub ReadableValueRender {
    my ( $Self, %Param ) = @_;

    # set Value and Title variables
    my $Value = '';
    my $Title = '';

    # check value
    my @Values;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    my @ReadableValues;

    VALUEITEM:
    for my $Item (@Values) {
        next VALUEITEM if !$Item;

        push @ReadableValues, $Item;
    }

    # set new line separator
    my $ItemSeparator = $Param{DynamicFieldConfig}->{Config}->{ItemSeparator} || ', ';

    # Output transformations
    $Value = join( $ItemSeparator, @ReadableValues );
    $Title = $Value;

    # cut strings if needed
    if ( $Param{ValueMaxChars} && length($Value) > $Param{ValueMaxChars} ) {
        $Value = substr( $Value, 0, $Param{ValueMaxChars} ) . '...';
    }
    if ( $Param{TitleMaxChars} && length($Title) > $Param{TitleMaxChars} ) {
        $Title = substr( $Title, 0, $Param{TitleMaxChars} ) . '...';
    }

    # create return structure
    my $Data = {
        Value => $Value,
        Title => $Title,
    };

    return $Data;
}

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');


    # set HTMLOuput as default if not specified
    if ( !defined $Param{HTMLOutput} ) {
        $Param{HTMLOutput} = 1;
    }    

    # get raw Value strings from field value
    my @Keys;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Keys = @{ $Param{Value} };
    }
    else {
        @Keys = ( $Param{Value} );
    }

    my @Values;
    my @Titles;
    my $HtmlOutput = "";

    for my $Key (@Keys) {
        next if ( !$Key );

        my %User = $CustomerUserObject->CustomerUserDataGet(
            User => $Key,
        );

        

        # set title as value after update and before limit
        my $EntryTitle = $User{UserFirstname}.' '.$User{UserLastname};
        my $EntryValue = $User{UserFirstname}.' '.$User{UserLastname};

        my %CustomerData;
        if ( $Key ) {
            %CustomerData = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
                User => $Key,
            );
        }
        my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

        my $CustomerTable = $LayoutObject->AgentCustomerViewTable(
            Data   => \%CustomerData,
            Ticket => $Param{Ticket},
            Max    => $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::CustomerInfoZoomMaxSize'),
        );

        
        my $Output = $LayoutObject->Output(
            TemplateFile => 'AgentTicketZoom/CustomerInformation',
            Data         => {
                CustomerTable => $CustomerTable,
            },
        );

        my $widgetName = "widgetMove";

        my $find = "class=\"WidgetSimple\"";
        my $replace = "class=\"WidgetSimple $widgetName\"";

        $Output = $Output =~ s/$find/$replace/r;

        $find = $Param{LayoutObject}->{LanguageObject}->Translate("Customer Information");
        $replace = $Param{DynamicFieldConfig}->{Label};

        $Output = $Output =~ s/$find/$replace/r;

        $HtmlOutput .=$Output;
        $EntryValue = $Key;

        push ( @Values, $EntryValue );
        push ( @Titles, $EntryTitle );
    }

    # set item separator
    my $ItemSeparator = $Param{DynamicFieldConfig}->{Config}->{ItemSeparator} || ', ';

    my $Value = join( $ItemSeparator, @Values );
    my $Title = join( $ItemSeparator, @Titles );

    # this field type does not support the Link Feature in normal way. Links are provided via Value in HTMLOutput
    my $Link;

    if($Param{LayoutObject}->{Action} ne 'CustomerTicketZoom'){
        $Value .= $HtmlOutput;
    }

    # create return structure
    my $Data = {
        Value => $Value,
        Title => $Title,
        Link  => $Link,
    };

    return $Data;
}

sub StatsFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    # set PossibleValues
    my $Values;

    my %DefaultValuesList;

    

    # get historical values from database
    my $HistoricalValues = $Self->{DynamicFieldValueObject}->HistoricalValueGet(
        FieldID   => $Param{DynamicFieldConfig}->{ID},
        ValueType => 'Text,',
    );

    # add historic values to current values (if they don't exist anymore)
    for my $Key ( keys ( %{$HistoricalValues} ) ) {
        if ( !$Values->{$Key} ) {
            $Values->{$Key} = $HistoricalValues->{$Key}
        }
    }

    # use PossibleValuesFilter if defined
    $Values = $Param{PossibleValuesFilter} if ( defined($Param{PossibleValuesFilter}) );

    return {
        Values             => $Values,
        Name               => $Param{DynamicFieldConfig}->{Label},
        Element            => 'DynamicField_' . $Param{DynamicFieldConfig}->{Name},
        Block              => 'MultiSelectField',
    };
}

sub StatsSearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    my $Operator = 'Equals';
    my $Value    = $Param{Value};

    return {
        $Operator => $Value,
    };
}

sub ColumnFilterValuesGet {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};

    # get column filter values from database
    my $ColumnFilterValues = $Kernel::OM->Get('Kernel::System::Ticket::ColumnFilter')->DynamicFieldFilterValuesGet(
        TicketIDs => $Param{TicketIDs},
        FieldID   => $Param{DynamicFieldConfig}->{ID},
        ValueType => 'Text',
    );

    return $ColumnFilterValues;
}

sub ObjectMatch {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    # the attribute must be an array
    return 0 if !IsArrayRefWithData( $Param{ObjectAttributes}->{$FieldName} );

    my $Match;

    # search in all values for this attribute
    VALUE:
    for my $AttributeValue ( @{ $Param{ObjectAttributes}->{$FieldName} } ) {

        next VALUE if !defined $AttributeValue;

        # only need to match one
        if ( $Param{Value} eq $AttributeValue ) {
            $Match = 1;
            last VALUE;
        }
    }

    return $Match;
}

sub _ExportXMLSearchDataPrepare {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    return if !$Param{XMLDefinition} || ref $Param{XMLDefinition} ne 'ARRAY';
    return if !$Param{What}          || ref $Param{What}          ne 'ARRAY';
    return if !$Param{SearchData}    || ref $Param{SearchData}    ne 'HASH';

    ITEM:
    for my $Item ( @{ $Param{XMLDefinition} } ) {

        # create key
        my $Key = $Param{Prefix} ? $Param{Prefix} . '::' . $Item->{Key} : $Item->{Key};
        my $DataKey = $Item->{Key};

        # prepare value
        my $Values = $Param{SearchData}->{$DataKey};
        if ($Values) {

            # create search key
            my $SearchKey = $Key;
            $SearchKey =~ s{ :: }{\'\}[%]\{\'}xmsg;

            # create search hash
            my $SearchHash = {
                '[1]{\'Version\'}[1]{\''
                    . $SearchKey
                    . '\'}[%]{\'Content\'}' => $Values,
            };
            push @{ $Param{What} }, $SearchHash;
        }
        next ITEM if !$Item->{Sub};

        # start recursion, if "Sub" was found
        $Self->_ExportXMLSearchDataPrepare(
            XMLDefinition => $Item->{Sub},
            What          => $Param{What},
            SearchData    => $Param{SearchData},
            Prefix        => $Key,
        );
    }

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
