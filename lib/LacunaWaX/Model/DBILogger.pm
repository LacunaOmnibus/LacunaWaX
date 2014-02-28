use v5.14;
use utf8;

package LacunaWaX::Model::DBILogger::Output {#{{{
    use warnings    qw(FATAL utf8);    # fatalize encoding glitches
    use base qw(Log::Dispatch::DBI);

    use Carp;
    use DateTime;

    sub set_component {#{{{
        my $self        = shift;
        my $component   = shift;
        $self->{'component'} = $component;
        return 1;
    }#}}}
    sub set_run {#{{{
        my $self = shift;
        my $run  = shift;
        $self->{run} = $run;
        return 1;
    }#}}}
    sub create_statement {#{{{
        my $self = shift;

        my $sth = $self->{dbh}->prepare(<<"SQL");
INSERT INTO $self->{table} ('run', 'component', 'level', 'datetime', 'message') VALUES (?, ?, ?, ?, ?)
SQL
        return $sth;
    }#}}}
    sub log_message {#{{{
        my $self = shift;
        my %params = @_;

        my $date;
        if( defined $params{'datetime'} ) {
            if(ref $params{'datetime'} eq 'DateTime') {
                $date = $params{'datetime'}->iso8601;
            }
            elsif( $params{'datetime'} =~ m/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d$/ ) {
                $date = $params{'datetime'};    # it's already in correct format
            }
            else {
                croak "'datetime' parameter must be a DateTime object or ISO8601 format.";
            }
        }
        else {
            $date = DateTime->now( time_zone => 'UTC' );
        }

        $self->{sth}->execute(
            $self->{'run'}, 
            $self->{'component'}, 
            $params{'level'}, 
            $date,
            $params{'message'}
        );
        return 1;
    }#}}}

}#}}}
package LacunaWaX::Model::DBILogger {#{{{
    use warnings;
    use Carp;
    use DateTime;
    use Log::Dispatch;
    use Moose;

    has 'dbh' => (
        is          => 'rw',
        isa         => 'DBI::db',
        required    => 1, 
    );
    has 'table' => (
        is          => 'rw',
        isa         => 'Str',
        required    => 1, 
    );

    ########################################

    has 'logger' => (
        is          => 'rw',
        isa         => 'Log::Dispatch',
        lazy_build  => 1, 
        handles     => {
            debug       => 'debug',
            info        => 'info',
            notice      => 'notice',
            warning     => 'warning',
            error       => 'error',
            critical    => 'critical',
            alert       => 'alert',
            emergency   => 'emergency',
        }
    );

    has 'callbacks' => (
        is          => 'rw', 
        isa         => 'CodeRef', 
        lazy_build  => 1, 
    );
    has 'component' => (
        is          => 'rw',
        isa         => 'Str',
        lazy        => 1,
        default     => 'main', 
        trigger     => \&update_output_component,
    );
    has 'min_level' => (
        is          => 'rw',
        isa         => 'Str',
        lazy        => 1, 
        default     => 'debug',
    );
    has 'name' => (
        is          => 'rw',
        isa         => 'Str',
        lazy        => 1, 
        default     => 'dbi',
    );
    has 'output' => (
        is          => 'rw',
        isa         => 'LacunaWaX::Model::DBILogger::Output',
        lazy_build  => 1, 
    );
    has 'run' => (
        is          => 'rw',
        isa         => 'Int',
        lazy_build  => 1, 
    );
    has 'time_zone' => (
        is          => 'rw',
        isa         => 'Str',
        lazy        => 1, 
        default     => 'UTC',
    );

    sub BUILD {
        my $self = shift;

        $self->logger->add( $self->output );

        return $self;
    }

    sub _build_callbacks {#{{{
        my $self = shift;
        return sub{ my %h = @_; return sprintf "%s", $h{'message'}; },
    }#}}}
    sub _build_logger {#{{{
        my $self = shift;
        my $logger = Log::Dispatch->new(
            callbacks => $self->callbacks
        );
        return $logger;
    }#}}}
    sub _build_output {#{{{
        my $self = shift;

        my $output = LacunaWaX::Model::DBILogger::Output->new(
            name        => $self->name,
            min_level   => $self->min_level,
            table       => $self->table,
            dbh         => $self->dbh,
        );

        $output->set_run($self->run);
        $output->set_component($self->component);

        return $output;
    }#}}}
    sub _build_run {#{{{
        my $self   = shift;
        my $maxrun = 0;

        my $sth  = $self->dbh->prepare("SELECT MAX(run) FROM " . $self->table);
        $sth->execute() or croak DBI::errstr;
        $maxrun = $sth->fetchrow_array() || 0;
        return ++$maxrun;
    }#}}}

    sub prune_bydate {#{{{
        my $self = shift;
        my $date = shift;
        ref $date eq 'DateTime' or return;
        my $oldest = $date->iso8601;
        my $sth = $self->dbh->prepare(q/ DELETE FROM / . $self->table . q/ WHERE datetime < ? /);
        my $rv = $sth->execute($oldest);
        return $rv;
    }#}}}
    sub update_output_component {#{{{
        my $self        = shift;
        my $comp        = shift;
        my $old_comp    = shift;
        $self->output->set_component($comp);
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}#}}}

