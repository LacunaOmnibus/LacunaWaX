
### CHECK
###
### The only difference between this and the Database global is the schema 
### attribute here is using a different package.  Keeping both this and 
### ./Database.pm because of a 5-byte difference is braindead.
###
### Refactor.

package LacunaWaX::Model::Globals::DatabaseLog {
    use v5.14;
    use Moose;

    use LacunaWaX::Model::LogsSchema;

    has 'db_file'     => (
        is          => 'rw', 
        isa         => 'Path::Tiny',
        required    => 1,
    );

    #####################

    has 'connection' => (
        is          => 'rw', 
        isa         => 'DBI::db',
        lazy_build  => 1,
    );

    has 'dsn'     => (
        is          => 'rw', 
        isa         => 'Str',
        lazy_build  => 1,
    );

    has 'schema'     => (
        is          => 'rw', 
        isa         => 'LacunaWaX::Model::LogsSchema',
        lazy_build  => 1,
    );

    has 'sql_options' => (
        is      => 'rw',
        isa     => "HashRef[Any]",
        lazy    => 1,
        default => sub{ {sqlite_unicode => 1, quote_names => 1} },
    );

    sub BUILD {
        my $self = shift;

        return $self;
    }

        sub _build_connection {#{{{
            my $self    = shift;
            my $conn    = DBI->connect( $self->dsn, q{}, q{}, $self->sql_options );
            return $conn;
        }#}}}
        sub _build_dsn {#{{{
            my $self    = shift;
            my $dsn     = 'DBI:SQLite:dbname=' . $self->db_file->stringify;
            return $dsn;
        }#}}}
        sub _build_schema {#{{{
            my $self = shift;

            my $schema = LacunaWaX::Model::LogsSchema->connect( $self->dsn, $self->sql_options );
            return $schema;
        }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

