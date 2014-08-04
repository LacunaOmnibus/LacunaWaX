use v5.14;

=pod

The Lottery and Autovote functions have both been cleaned up, and live in 
their own classes under the LacunaWaX::Schedule:: namespace now.

The other scheduled functions need to be moved under there too.  See those two 
already-fixed classes for inspiration.

=cut

package LacunaWaX::Schedule {
    use Carp;
    use Data::Dumper;
    use LacunaWaX::Preload::Cava;
    use LacunaWaX::Model::Mutex;
    use LacunaWaX::Model::Client;
    use LWP::UserAgent;
    use Moose;
    use Try::Tiny;

    use LacunaWaX::Schedule::Archmin;
    use LacunaWaX::Schedule::Lottery;
    use LacunaWaX::Schedule::SS_Health;

    has 'globals'       => (is => 'rw', isa => 'LacunaWaX::Model::Globals',     required    => 1);
    has 'schedule'      => (is => 'rw', isa => 'Str',                           required    => 1);
    has 'mutex'         => (is => 'rw', isa => 'LacunaWaX::Model::Mutex',       lazy_build  => 1);
    has 'game_client'   => (is => 'rw', isa => 'LacunaWaX::Model::Client',
        documentation =>q{
            Not a lazy_build, but still auto-generated (in connect()).  No need to pass this in.
        }
    );

    sub BUILD {
        my $self = shift;
        return $self;
    }

    around qw(archmin lottery ss_health) => sub {#{{{
        my $orig = shift;
        my $self = shift;

        my $logger = $self->globals->logger;
        $logger->component('Schedule');
        $logger->info("# -=-=-=-=-=-=- #");
        $logger->info("Scheduler beginning with task '" . $self->schedule .  q{'.});

        ### ex lock for the entire run might seem a little heavy-handed.  But 
        ### I'm not just trying to limit database collisions; I'm also 
        ### limiting simultaneous RPCs; multiple schedulers firing at the same 
        ### time could be seen as a low-level DOS.
        $logger->info($self->schedule . " attempting to obtain exclusive lock.");
        unless( $self->mutex->lock_exnb ) {
            $logger->info($self->schedule . " found existing scheduler lock; this run will pause until the lock releases.");
            $self->mutex->lock_ex;
        }
        $logger->info($self->schedule . " succesfully obtained exclusive lock.");

        $self->$orig();

        $self->mutex->lock_un;
        $logger->info("Scheduler run of task " . $self->schedule . " complete.");
        return $self;
    };#}}}
    sub _build_mutex {#{{{
        my $self = shift;
        return LacunaWaX::Model::Mutex->new( globals => $self->globals, name => 'schedule' );
    }#}}}

    sub archmin {#{{{
        my $self = shift;

        my $am       = LacunaWaX::Schedule::Archmin->new( globals => $self->globals );
        my $pushes   = $am->push_all_servers;
        my $searches = $am->search_all_servers;
        $am->logger->info("--- Archmin Run Complete ---");

        return($searches, $pushes);
    }#}}}
    sub lottery {#{{{
        my $self = shift;

        my $lottery = LacunaWaX::Schedule::Lottery->new( globals => $self->globals );
        my $cnt     = $lottery->play_all_servers;
        $lottery->logger->info("--- Lottery Run Complete ---");

        return $cnt;
    }#}}}
    sub ss_health {#{{{
        my $self = shift;

        my $ss_health = LacunaWaX::Schedule::SS_Health->new( globals => $self->globals );
        my $cnt = $ss_health->diagnose_all_servers;
        $ss_health->logger->info("--- Station Health Check Complete ---");

        return $cnt;
    }#}}}

    sub test {#{{{
        my $self = shift;

        my $logger = $self->globals->logger;
        $logger->component('ScheduleTest');
        $logger->info("ScheduleTest has been called.");

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
