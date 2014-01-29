
package LacunaWaX::MainFrame::MenuBar::File {
    use v5.14;
    use Data::Dumper;
    use DBI;
    use Moose;
    use Path::Tiny;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);
    with 'LacunaWaX::Roles::GuiElement';

    ### Wx::Menu is a non-hash object.  Extending such requires 
    ### MooseX::NonMoose::InsideOut instead of plain MooseX::NonMoose.
    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';

    use LacunaWaX::MainFrame::MenuBar::File::Connect;

    has 'itm_exit'      => (is => 'rw', isa => 'Wx::MenuItem',                                  lazy_build => 1);
    has 'itm_connect'   => (is => 'rw', isa => 'LacunaWaX::MainFrame::MenuBar::File::Connect',  lazy_build => 1);
    has 'itm_import'    => (is => 'rw', isa => 'Wx::MenuItem',                                  lazy_build => 1);

    has 'db_imports' => (
        is          => 'rw',
        isa         => 'HashRef',
        lazy_build  => 1,
        documentation => q{
            The tables and columns that will be imported when the user does File... Import.
        }
    );

    sub FOREIGNBUILDARGS {#{{{
        return; # Wx::Menu->new() takes no arguments
    }#}}}
    sub BUILD {
        my $self = shift;
        $self->AppendSubMenu    ( $self->itm_connect,   "&Connect...",  "Connect to a server"   );
        $self->Append           ( $self->itm_import                                             );
        $self->Append           ( $self->itm_exit                                               );
        return $self;
    }

    sub _build_db_imports {#{{{
        my $self = shift;

        my $imports = {
            ArchMinPrefs => [qw(
                server_id body_id glyph_home_id reserve_glyphs pusher_ship_name auto_search_for 
            )],
            BodyTypes => [qw(
                body_id server_id type_general 
            )],
            SSAlerts => [qw(
                server_id station_id enabled min_res 
            )],
            ServerAccounts => [qw(
                server_id username password default_for_server 
            )],
            SitterPasswords => [qw(
                server_id player_id player_name sitter 
            )],
        };
        return $imports;
    }#}}}
    sub _build_itm_exit {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Exit',
            'Exit',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_connect {#{{{
        my $self = shift;
        return LacunaWaX::MainFrame::MenuBar::File::Connect->new(
            ancestor    => $self,
            app         => $self->app,
            parent      => $self->parent,   # MainFrame, not this Menu, is the parent.
        );
    }#}}}
    sub _build_itm_import {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Import Preferences',
            'Import preferences and settings from a previous LacunaWaX install.',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU($self->parent,  $self->itm_exit->GetId,    sub{$self->OnQuit(@_)}      );
        EVT_MENU($self->parent,  $self->itm_import->GetId,  sub{$self->OnImport(@_)}    );
        return 1;
    }#}}}

    sub old_database_checks_out  {#{{{
        my $self = shift;
        my $dbh  = shift;

        ### Ensure the tables we're going to try to import exist in the old 
        ### database
        my %tables = ();
        map{ $tables{$_} = 0 }(keys %{$self->db_imports} );
        my $tbl_sth = try {
            ### A text file with an .sqlite extension _will_ get this far.
            $dbh->table_info(undef, undef, undef, 'TABLE');
        }
        catch {
            wxTheApp->poperr("wtf was that?");
            return;
        };
        return 0 unless $tbl_sth;
        while( my $r = $tbl_sth->fetchrow_hashref ) {
            delete $tables{$r->{'TABLE_NAME'}};
        }
        return 0 if keys %tables;

        ### Ensure each of those tables contains the correct columns
        foreach my $tbl( keys %{$self->db_imports} ) {
            my %cols = ();
            map{ $cols{$_} = 0 }(@{$self->db_imports->{$tbl}});
            my $sth = $dbh->column_info(undef, undef, $tbl, undef);
            while( my $r = $sth->fetchrow_hashref ) {
                delete $cols{$r->{'COLUMN_NAME'}};
            }
            return 0 if keys %cols;
        }

        return 1;
    }#}}}

    sub OnImport {#{{{
        my $self  = shift;
        my $frame = shift;
        my $event = shift;

        my %imports = (
            ArchMinPrefs => [qw(
                server_id body_id glyph_home_id reserve_glyphs 
                pusher_ship_name auto_search_for 
            )],
            BodyTypes => [qw(
                body_id server_id type_general 
            )],
            SSAlerts => [qw(
                server_id station_id enabled min_res 
            )],
            ServerAccounts => [qw(
                server_id username password default_for_server 
            )],
            SitterPasswords => [qw(
                server_id player_id player_name sitter 
            )],
        );

        unless( wxYES == wxTheApp->popconf("This will import preferences from a previous install of LacunaWaX - is that what you want to do?", "Import") ) {
            wxTheApp->popmsg("OK - bailing.");
            return;
        }

        ### Open file browser to find original
        my $file_browser = Wx::FileDialog->new(
            $self->parent,
            'Select a database file',
            '', # default dir
            #'/home/jon/Desktop', # default dir
            'lacuna_app.sqlite', # default file
            '*.sqlite',
            wxFD_OPEN|wxFD_FILE_MUST_EXIST
        );
        $file_browser->ShowModal();

        ### Connect to the old database.
        my $db_file = join '/', ($file_browser->GetDirectory, $file_browser->GetFilename);
        my $options = {sqlite_unicode => 1, quote_names => 1};
        my $old_dbh = DBI->connect("dbi:SQLite:dbname=$db_file", q{}, q{}, $options );

        ### Sanity-check old database.
        unless( $self->old_database_checks_out($old_dbh) ) {
            wxTheApp->poperr( $file_browser->GetFilename . " is not a LacunaWaX database.");
            return;
        }

        ### Get DBI connection to the new (current) database.
        my $schema  = $self->bb->resolve( service => '/Database/schema' );
        my $new_dbh = $schema->storage->dbh;

        foreach my $table_name(keys %imports) {
            my $cols = $imports{$table_name};

            my $comma_cols  = join ', ', @{$cols};
            my @ques_arr    = ();
            push @ques_arr, '?' for @$cols;
            my $ques        = join ',', @ques_arr;
            my $sel_sth     = $old_dbh->prepare("SELECT $comma_cols FROM $table_name");
            my $ins_sth     = $new_dbh->prepare("INSERT OR IGNORE INTO $table_name ($comma_cols) VALUES ($ques)");

            $sel_sth->execute();
            $new_dbh->begin_work;
            while(my $rec = $sel_sth->fetchrow_arrayref) {
                $ins_sth->execute(@{$rec});
            }
            $new_dbh->commit;
        }
        wxTheApp->popmsg("The import completed successfully.", "Import Complete.");

        ### If we're on a brand new install, the user's looking at the Intro 
        ### panel, with both connect buttons grayed out.  If they just 
        ### imported previous prefs data that included the username/password, 
        ### enable the appropriate button(s).
        if( $self->intro_panel_exists ) {
            my $server_accounts = $schema->resultset('ServerAccounts')->search();
            while(my $sa = $server_accounts->next ) {
                if( $sa->username and $sa->password ) {
                    $self->get_intro_panel->buttons->{ $sa->server->id }->Enable(1);
                }
            }
        }

        return 1;
    }#}}}
    sub OnQuit {#{{{
        my $self  = shift;
        my $frame = shift;
        my $event = shift;
        $frame->Close(1);
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
