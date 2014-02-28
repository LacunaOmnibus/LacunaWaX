
=pod

Do not use this for Wx components, such as fonts.  

This is used by scheduled processes, and using Wx in those causes 
explosions.

This has no caching at all.

=cut

package LacunaWaX::Model::Globals {
    use v5.14;
    use Log::Dispatch;
    use Lucy::Search::IndexSearcher;
    use Moose;
    use Path::Tiny;

    use LacunaWaX::Model::DBILogger;
    use LacunaWaX::Model::Globals::Database;

    has 'root_dir' => (
        is          => 'rw', 
        isa         => 'Str',
        required    => 1,
    );

    ##########################################

    has 'api_key' => (
        is          => 'rw',
        isa         => 'Str',
        default     => '02484d96-804d-43e9-a6c4-e8e80f239573'
    );

    ### Database
    has 'db_file' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        lazy_build  => 1,
    );

    has 'db_log_file' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        required    => 1,
        lazy_build  => 1,
    );

    has 'db_log'     => (
        is          => 'rw', 
        isa         => 'LacunaWaX::Model::Globals::Database',
        lazy_build  => 1,
        handles     => {
            ### I'm almost certain to call this both ways.
            log_schema  => 'schema',
            logs_schema => 'schema',
        }
    );

    has 'db_main'     => (
        is          => 'rw', 
        isa         => 'LacunaWaX::Model::Globals::Database',
        lazy_build  => 1,
        handles     => {
            main_schema => 'schema',
        }
    );

    ### Directories
    has 'dir_assets' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        lazy_build  => 1,
    );
    has 'dir_bin' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        lazy_build  => 1,
    );
    has 'dir_html' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        lazy_build  => 1,
    );
    has 'dir_html_idx' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        lazy_build  => 1,
    );
    has 'dir_ico' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        lazy_build  => 1,
    );
    has 'dir_root' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        lazy_build  => 1,
    );
    has 'dir_user' => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        lazy_build  => 1,
    );

    ### Logging
    has 'log_time_zone' => (
        is       => 'rw', 
        isa      => 'Str',
        lazy     => 1,
        default  => 'UTC',
    );

    has 'log_component' => (
        is      => 'rw', 
        isa     => 'Str',
        lazy    => 1,
        default => 'main',
    );

    has 'logger' => (
        is          => 'rw', 
        isa         => 'LacunaWaX::Model::DBILogger',
        lazy_build  => 1,
    );

    has 'run' => (
        is      => 'rw', 
        isa     => 'Int',
        default => 0,
    );

    ### Lucy
    has 'lucy_searcher' => (
        is          => 'rw', 
        isa         => 'Lucy::Search::IndexSearcher',
        lazy_build  => 1,
    );

    sub BUILD {
        my $self = shift;
        return $self;
    }

    sub _build_db_file {#{{{
        my $self = shift;
        my $arg  = shift;

        my $f = q{};

        if( $arg and not ref $arg ) {
            ### Allow the user to pass in a file path as a string
            $f = path( $arg );
        }
        elsif( $arg and ref $arg eq 'Path::Tiny' ) {
            ### Or already as a Path::Tiny object
            $f = $arg;
        }
        else {
            ### Or they can skip it altogether and use the default.
            $f = $self->dir_user->child( 'lacuna_app.sqlite' );
        }
        return $f;
    }#}}}
    sub _build_db_log_file {#{{{
        my $self = shift;
        my $arg  = shift;

        my $f = q{};

        if( $arg and not ref $arg ) {
            ### Allow the user to pass in a file path as a string
            $f = path( $arg );
        }
        elsif( $arg and ref $arg eq 'Path::Tiny' ) {
            ### Or already as a Path::Tiny object
            $f = $arg;
        }
        else {
            ### Or they can skip it altogether and use the default.
            $f = $self->dir_user->child( 'lacuna_log.sqlite' );
        }
        return $f;
    }#}}}
    sub _build_db_main {#{{{
        my $self = shift;

        my $db = LacunaWaX::Model::Globals::Database->new(
            db_file => $self->db_file,
        );
        return $db;
    }#}}}
    sub _build_db_log {#{{{
        my $self = shift;

        my $db = LacunaWaX::Model::Globals::Database->new(
            db_file => $self->db_log_file,
        );
        return $db;
    }#}}}

    sub _build_dir_assets {#{{{
        my $self = shift;
        my $p = path( join q{/}, $self->dir_user, 'assets' );
        return $p;
    }#}}}
    sub _build_dir_bin {#{{{
        my $self = shift;
        my $p = path( join q{/}, $self->dir_root, 'bin' );
        return $p;
    }#}}}
    sub _build_dir_html {#{{{
        my $self = shift;
        my $p = path( join q{/}, $self->dir_user, 'doc', 'html' );
        return $p;
    }#}}}
    sub _build_dir_html_idx {#{{{
        my $self = shift;
        my $p = path( join q{/}, $self->dir_user, 'doc', 'html', 'html.idx' );
        return $p;
    }#}}}
    sub _build_dir_ico {#{{{
        my $self = shift;
        my $p = path( join q{/}, $self->dir_user, 'ico' );
        return $p;
    }#}}}
    sub _build_dir_root {#{{{
        my $self = shift;
        my $p = path( $self->root_dir );
        return $p;
    }#}}}
    sub _build_dir_user {#{{{
        my $self = shift;
        my $p = path( join q{/}, $self->dir_root, 'user' );
        return $p;
    }#}}}
    sub _build_logger {#{{{
        my $self = shift;

        my %args = (
            name        => 'dbi',
            min_level   => 'debug',
            component   => $self->log_component,
            time_zone   => $self->log_time_zone,
            dbh         => $self->db_log->connection,
            table       => 'Logs',
        );
        if( $self->run ) { $args{'run'} = $self->run; }

        my $l = LacunaWaX::Model::DBILogger->new(%args);
        unless( $self->run ) { $self->run( $l->run ); }

        return $l;
    };#}}}
    sub _build_lucy_searcher {#{{{
        my $self = shift;

        my $lucy = Lucy::Search::IndexSearcher->new( index => $self->dir_html_idx );
        return $lucy;
    }#}}}


    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

=head2 run

I want all log entries from a given run of the app to have the same 'run' 
value, to make it easy to eyeball all of what happened last run.  I did think 
about just using a pid for this, but I wanted the number sequential.

The Model::DBILogger output class will lazy_build its run attribute, setting 
it one higher than the current highest run value in the Logs table.

The problem is that my logger class is not a singleton.  This is so I can get 
a logger, set its component one time, and have that component setting stick 
for the life of that logger.

Previously, when the logger was a singleton, this would happen:
    
    $log->component("MyComponent");
    $log->info('foo');                  # logs 'foo' set as 'MyComponent'.

    $app->method_that_does_its_own_logging_and_sets_a_different_component();

    $log->info('bar');                  # logs 'bar' set as 'DifferentComponent'


But when loggers were first set up as "not singletons", they were all getting 
their own run values, and I don't want that either.

So now, the flow is:
    - Globals gets instantiated once per run of the app.  Its run attribute 
      starts out undef.
    - A logger gets instantiated.
        - If self->run is undef:
            - that logger generates its own run value.
            - THAT run value then gets set as the global run value.
        - If self->run has a value:
            - the new logger takes that run value as its own.

