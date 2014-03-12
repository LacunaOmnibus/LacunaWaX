use v5.14;

package LacunaWaX::Schedule::SS_Health {
    use Carp;
    use English qw( -no_match_vars );
    use Moose;
    use Try::Tiny;
    with 'LacunaWaX::Roles::ScheduledTask';

    use LacunaWaX::Model::SStation;
    use LacunaWaX::Model::SStation::Command;
    use LacunaWaX::Model::SStation::Police;

    has 'station' => (
        is  => 'rw',
        isa => 'LacunaWaX::Model::SStation',
        handles => {
            subpar_res              => 'subpar_res',
            incoming_hostiles       => 'incoming_hostiles',
            has_hostile_spies       => 'has_hostile_spies',
            has_command             => 'has_command',
            has_police              => 'has_police',
            star_unseized           => 'star_unseized',
            star_seized_by_other    => 'star_seized_by_other',
        },
        documentation => q{
            This cannot be built until after a call to game_connect().
        }
    );

    has 'alerts' => (
        is          => 'rw',
        isa         => 'ArrayRef[Str]',
        default     => sub{ [] },
    );

    has 'inbox' => (
        is          => 'rw',
        isa         => 'Object',
        lazy_build  => 1,
    );

    sub BUILD {
        my $self = shift;
        $self->logger->component('SS_Health');
        return $self;
    }
    sub _build_inbox {#{{{
        my $self = shift;
        return $self->game_client->inbox
    }#}}}

    sub add_alert {#{{{
        my $self = shift;
        my $alert = shift;
        push( @{$self->alerts}, $alert );
        return 1;
    }#}}}
    sub has_alerts {#{{{
        my $self = shift;
        return scalar @{$self->alerts};
    }#}}}
    sub diagnose_all_servers {#{{{
        my $self        = shift;
        my @server_recs = $self->schema->resultset('Servers')->search()->all;   ## no critic qw(ProhibitLongChainsOfMethodCalls)

        foreach my $server_rec( @server_recs ) {
            my $server_count = try {
                $self->diagnose_server($server_rec);
            }
            catch {
                chomp(my $msg = $_);
                $self->logger->error($msg);
                return;
            } or return;
        }
        $self->logger->info("Stations have been checked on all servers.");
        return;
    }#}}}
    sub diagnose_server {#{{{
        my $self            = shift;
        my $server_rec      = shift;    # Servers table record
        my $server_checks   = 0;

        unless( $self->game_connect($server_rec->id) ) {
            $self->logger->info("Failed to connect to " . $server_rec->name . " - check your credentials!");
            return $server_checks;
        }
        $self->logger->info("Diagnosing stations on server " . $server_rec->name);

        my @ss_alert_recs = $self->schema->resultset('SSAlerts')->search({    ## no critic qw(ProhibitLongChainsOfMethodCalls)
            server_id => $server_rec->id
        })->all;

        STATION_RECORD:
        foreach my $ss_rec(@ss_alert_recs) {
            $self->make_station($ss_rec);
            try {
                $self->diagnose_station($ss_rec);
            }
            catch {
                $self->logger->error("Unable to diagnose station " . $self->station->name . ": $ARG");
            } or next STATION_RECORD;
        }

        return 1;
    }#}}}
    sub diagnose_station {#{{{
        my $self    = shift;
        my $ss_rec  = shift;    # SSAlerts table record

        return unless $ss_rec->enabled;
        $self->alerts([]);
        $self->logger->info("Diagnosing " . $self->station->name);

        $self->logger->info("Checking we have sufficient resources");
        if( my $restype = $self->station->subpar_res($ss_rec->min_res) ) {
            $self->add_alert("At _least_ one res ($restype) per hour has dropped too low!");
        }

        if( $self->has_police ) {
            if( $ss_rec->hostile_ships ) {
                $self->logger->info("Looking for hostile inbound ships");
                if( my $shipcount = $self->incoming_hostiles() ) {
                    $self->add_alert("There are hostile ships inbound!");
                }
            }

            if( $ss_rec->hostile_spies ) {
                $self->logger->info("Looking for hostile spies onsite");
                if( $self->has_hostile_spies($ss_rec) ) {
                    $self->add_alert("There are spies onsite who are not set to Counter Espionage.  These may be hostiles.");
                }
            }
        }

        $self->logger->info("Making sure our star is seized...");
        if( $self->star_unseized() ) {
            $self->add_alert("The station's star is unseized!");
        }

        if( $ss_rec->own_star_seized ) {
            $self->logger->info("...and making sure it's seized by us.");
            if( $self->star_seized_by_other() ) {
                $self->add_alert("Star has been seized by another SS!");
            }
        }

        $self->send_alert_mail();

        return;
    }#}}}
    sub make_station {#{{{
        my $self    = shift;
        my $ss_rec  = shift;
        my $station = LacunaWaX::Model::SStation->new(
            id          => $ss_rec->station_id,
            game_client => $self->game_client,
        );
        $self->station( $station );
        return 1;
    }#}}}
    sub send_alert_mail {#{{{
        my $self = shift;

        return 0 unless $self->has_alerts;

        my $body = "
While performing a routine checkup of your station, I 
found a problem that could be dangerous to its long 
term health and happiness.

Please look into this immediately.
            
The problem I found was:
--------------------------------------------------
";

        #foreach my $a( $self->all_alerts ) {
        foreach my $a( @{$self->alerts} ) {
            $self->logger->info( "PROBLEM - $a" );    # SS name has already been mentioned in the log
            $body .= "$a\n";
        }

        $body .= "--------------------------------------------------

Your humble station physician,
Dr. Flurble J. Notaqwak

";


        $self->inbox->send_message(
            $self->game_client->empire_name,        # to
            'SS ALERT: ' . $self->station->name,    # subject
            $body,                                  # 3 guesses
        );

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
