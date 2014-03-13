
package LacunaWaX::MainFrame::MenuBar::File {
    use v5.14;
    use Data::Dumper;
    use DBI;
    use IO::All;
    use Moose;
    use Path::Tiny;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    with 'LacunaWaX::Roles::MainFrame::MenuBar::Menu';
    use LacunaWaX::MainFrame::MenuBar::File::Connect;

    has 'itm_exit'      => (is => 'rw', isa => 'Wx::MenuItem',                                  lazy_build => 1);
    has 'itm_connect'   => (is => 'rw', isa => 'LacunaWaX::MainFrame::MenuBar::File::Connect',  lazy_build => 1);
    has 'itm_import'    => (is => 'rw', isa => 'Wx::MenuItem',                                  lazy_build => 1);
    has 'itm_export'    => (is => 'rw', isa => 'Wx::MenuItem',                                  lazy_build => 1);

    sub BUILD {
        my $self = shift;
        $self->AppendSubMenu    ( $self->itm_connect->menu, "&Connect...",  "Connect to a server"   );
        $self->Append           ( $self->itm_import                                                 );
        $self->Append           ( $self->itm_export                                                 );
        $self->Append           ( $self->itm_exit                                                   );
        $self->_set_events();
        return $self;
    }

    sub _build_itm_exit {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self->menu, -1,
            '&Exit',
            'Exit',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_connect {#{{{
        my $self = shift;
        return LacunaWaX::MainFrame::MenuBar::File::Connect->new(
            parent => $self->parent,   # MainFrame, not this Menu, is the parent.
        );
    }#}}}
    sub _build_itm_export {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self->menu, -1,
            '&Export Database',
            'Export your preferences database for backup or to prep for upgrade.',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_import {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self->menu, -1,
            '&Import Preferences',
            'Import preferences and settings from a previous LacunaWaX install.',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( $self->parent,  $self->itm_exit->GetId,    sub{$self->OnQuit(@_)}      );
        EVT_MENU( $self->parent,  $self->itm_import->GetId,  sub{$self->OnImport(@_)}    );
        EVT_MENU( $self->parent,  $self->itm_export->GetId,  sub{$self->OnExport(@_)}    );
        return 1;
    }#}}}

    sub OnExport {#{{{
        my $self  = shift;
        
        wxTheApp->popmsg(
            "I'm about to open a file browser.  Browse to where you want to export the database (your desktop should be fine).",
            "Export database prep"
        );

        ### Open modal file browser
        my $file_browser = Wx::FileDialog->new(
            $self->parent->frame,
            'Select a database file',
            $ENV{'HOME'},           # default dir
            'lacuna_app.sqlite',    # default file
            q{},
            wxFD_SAVE|wxFD_OVERWRITE_PROMPT
        );
        if( $file_browser->ShowModal() == wxID_CANCEL ) {
            return;
        }

        my $source_db_file  = wxTheApp->db_file;
        my $dest_db_file    = join '/', ($file_browser->GetDirectory, $file_browser->GetFilename);

        $dest_db_file =~ s{\\}{/}g;
        io($dest_db_file) < io($source_db_file);

        wxTheApp->popmsg(
            "Your database has been exported to $dest_db_file.",
            "Export database success!"
        );

        return 1;
    }#}}}
    sub OnImport {#{{{
        my $self  = shift;

        ### Open modal file browser
        my $file_browser = Wx::FileDialog->new(
            $self->parent->frame,
            'Select a database file',
            '', # default dir
            'lacuna_app.sqlite', # default file
            'SQLite Databases (*.sqlite)|*.sqlite|All Files (*.*)|*.*',
            wxFD_OPEN|wxFD_FILE_MUST_EXIST
        );
        if( $file_browser->ShowModal() == wxID_CANCEL ) {
say "import cancel";
            return;
        }

        my $db_file = join '/', ($file_browser->GetDirectory, $file_browser->GetFilename);
        unless( $file_browser->GetFilename ) {
            wxTheApp->popmsg("No file selected.");
            return;
        }
        unless( -e $db_file ) {
            wxTheApp->popmsg("$db_file: No such file or directory.");
            return;
        }

        my $rv = try {
            wxTheApp->import_old_database($db_file)
        }
        catch {
            wxTheApp->poperr( "error is: $_ ($db_file)");
            return;
        } or return;
        wxTheApp->popmsg("The import completed successfully.", "Import Complete.");

        ### If we're on a brand new install, the user's looking at the Intro 
        ### panel, with both connect buttons grayed out.  If they just 
        ### imported previous prefs data that included the username/password, 
        ### enable the appropriate button(s).
        if( wxTheApp->has_intro_panel ) {
            my $schema = wxTheApp->main_schema;
            my $server_accounts = $schema->resultset('ServerAccounts')->search();
            while(my $sa = $server_accounts->next ) {
                if( $sa->username and $sa->password ) {
                    wxTheApp->intro_panel->buttons->{ $sa->server->id }->Enable(1);
                }
            }
            wxTheApp->intro_panel->lbl_firsttime->SetLabel('Thanks!  Click the button to login.');
            wxTheApp->intro_panel->bottom_panel_sizer->Layout();
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
