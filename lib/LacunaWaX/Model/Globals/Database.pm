
package LacunaWaX::Model::Globals::Database {
    use v5.14;
    use Moose;

    use LacunaWaX::Model::LogsSchema;
    use LacunaWaX::Model::Schema;

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
        isa         => 'Object',
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

            my $schema;
            if( $self->db_file->stringify =~ /log/ ) {
                $schema = LacunaWaX::Model::LogsSchema->connect( $self->dsn, $self->sql_options );
            }
            else {
                $schema = LacunaWaX::Model::Schema->connect( $self->dsn, $self->sql_options );
            }
            return $schema;
        }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

=head1 NAME

LacunaWaX::Model::Globals::Database - LacunaWaX Databases 

=head1 SYNOPSIS

 my $main = LacunaWaX::Model::Globals::Database->new(
  db_file => 'lacuna_app.sqlite'
 );

 my $log = LacunaWaX::Model::Globals::Database->new(
  db_file => 'lacuna_log.sqlite'
 );

 say "I'm connected to " . $main->dsn;

 ### Use this as a regular DBI db handle
 my $dbh = $main->connection;

 ### DBIC schema
 my $schema = $main->schema;

=head1 DESCRIPTION

LacunaWaX uses two database files; C<lacuna_app.sqlite> and 
C<lacuna_log.sqlite>, each of which has its own DBIC schema.

When instantiating a LacunaWaX::Model::Globals::Database object, the module 
itself will decide whether you want the main or the logs schema, based upon 
whether the name of the logfile you send contains the string "log" or not.

If you go renaming database files, you can pass in your own schema if you 
like.  But adding the string "log" to the main database filename, or removing 
it from the log database filename, is silly.  Just leave it there.

=cut

