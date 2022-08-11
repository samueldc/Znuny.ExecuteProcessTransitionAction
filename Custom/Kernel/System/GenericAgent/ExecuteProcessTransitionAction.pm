# --
# Copyright (C) 2001-2021 OTRS AG, https://otrs.com/
# Copyright (C) 2021-2022 Znuny GmbH, https://znuny.org/
# Copyright (C) 2022-2022 Samuel, https://github/samueldc
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::GenericAgent::ExecuteProcessTransitionAction;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::ProcessManagement::TransitionAction',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # 0=off; 1=on;
    $Self->{Debug} = $Param{Debug} || 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed param
    NEEDED:
    for my $Needed (qw(TransitionActionEntityIDs TransitionEntityID HistoryName)) {
        next NEEDED if defined $Param{New}->{$Needed};
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed in GenericAgent::ExecuteProcessTransitionAction!",
        );
        return;
    }

    # if ( !$Param{New}->{'TransitionActionEntityIDs'} ) {
    #     $Kernel::OM->Get('Kernel::System::Log')->Log(
    #         Priority => 'error',
    #         Message  => 'Need TransitionActionEntityIDs param for GenericAgent::ExecuteProcessTransitionAction module!',
    #     );
    #     return;
    # }

    # get transition actions ids
    my $ParamTransitionActionEntityIDs = $Param{New}->{TransitionActionEntityIDs};
    $ParamTransitionActionEntityIDs =~ tr/ //ds;
    my @TransitionActionEntityIDs = split(',', $ParamTransitionActionEntityIDs);

    # get ticket data
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 1,
    );

    # check if its a process ticket
    if ( !$Ticket{DynamicField_ProcessManagementProcessID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Ticket $Param{TicketID} is not a process ticket!",
        );
        return;
    }

    # check if transition action exists
    my $TransitionActionObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction');
    my $TransitionActionList = $TransitionActionObject->TransitionActionList(
        TransitionActionEntityID => \@TransitionActionEntityIDs,
    );
    if ( !IsArrayRefWithData( $TransitionActionList ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "No Data for TransitionAction '@TransitionActionEntityIDs' found!",
        );
        return;
    }

    # execute each transtion action; code based on Process.pm 
    for my $TransitionAction ( @{$TransitionActionList} ) {

        %Ticket = $TicketObject->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 1,
        );

        my $TransitionActionModuleObject = $TransitionAction->{Module}->new();

        my %Config = %{ $TransitionAction->{Config} || {} };

        my $TransitionActionEntityID = $TransitionAction->{TransitionActionEntityID};

        my $Success = $TransitionActionModuleObject->Run(
            UserID                   => $Ticket{ChangeBy},
            Ticket                   => \%Ticket,
            ProcessEntityID          => $Ticket{DynamicField_ProcessManagementProcessID},
            ActivityEntityID         => $Ticket{DynamicField_ProcessManagementActivityID},
            TransitionEntityID       => $Param{New}->{TransitionEntityID}, # only for log and information purposes; this transition will not be verified
            TransitionActionEntityID => $TransitionActionEntityID,
            Config                   => \%Config,
        );

        # log execution
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message =>
                "TransitionAction '$TransitionActionEntityID' executed for $Ticket{DynamicField_ProcessManagementProcessID}!",
        );

        # add history for ticket audit purposes
        $TicketObject->HistoryAdd(
            Name         => $Param{New}->{HistoryName} . ": $TransitionActionEntityID" ,
            HistoryType  => 'Misc',
            TicketID     => $Param{TicketID},
            UserID       => $Ticket{ChangeBy},
            CreateUserID => $Ticket{ChangeBy},
        );

    }

    return 1;
}

1;