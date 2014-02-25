
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
    with 'LacunaWaX::Roles::GuiElement';

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';

    use LacunaWaX::MainFrame::MenuBar::File::Connect;

    has 'itm_exit'      => (is => 'rw', isa => 'Wx::MenuItem',                                  lazy_build => 1);
    has 'itm_connect'   => (is => 'rw', isa => 'LacunaWaX::MainFrame::MenuBar::File::Connect',  lazy_build => 1);
    has 'itm_import'    => (is => 'rw', isa => 'Wx::MenuItem',                                  lazy_build => 1);
    has 'itm_export'    => (is => 'rw', isa => 'Wx::MenuItem',                                  lazy_build => 1);

    sub FOREIGNBUILDARGS {#{{{
        return; # Wx::Menu->new() takes no arguments
    }#}}}
    sub BUILD {
        my $self = shift;
        $self->AppendSubMenu    ( $self->itm_connect,   "&Connect...",  "Connect to a server"   );
        $self->Append           ( $self->itm_import                                             );
        $self->Append           ( $self->itm_export                                             );
        $self->Append           ( $self->itm_exit                                               );
        return $self;
    }

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
    sub _build_itm_export {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Export Database',
            'Export your preferences database for backup or to prep for upgrade.',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
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
        EVT_MENU( $self->parent,  $self->itm_exit->GetId,    sub{$self->OnQuit(@_)}      );
        EVT_MENU( $self->parent,  $self->itm_import->GetId,  sub{$self->OnImport(@_)}    );
        EVT_MENU( $self->parent,  $self->itm_export->GetId,  sub{$self->OnExport(@_)}    );
        #EVT_MENU( wxTheApp->main_frame->frame,  $self->itm_exit->GetId,    sub{$self->OnQuit(@_)}      );
        #EVT_MENU( wxTheApp->main_frame->frame,  $self->itm_import->GetId,  sub{$self->OnImport(@_)}    );
        #EVT_MENU( wxTheApp->main_frame->frame,  $self->itm_export->GetId,  sub{$self->OnExport(@_)}    );
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
            $self->parent,
            'Select a database file',
            $ENV{'HOME'},           # default dir
            'lacuna_app.sqlite',    # default file
            #'*.sqlite',
            q{},
            wxFD_SAVE|wxFD_OVERWRITE_PROMPT
        );
        $file_browser->ShowModal();

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

        unless( wxYES == wxTheApp->popconf("This will import preferences from a previous install of LacunaWaX - is that what you want to do?", "Import") ) {
            return;
        }

        ### Open modal file browser
        my $file_browser = Wx::FileDialog->new(
            $self->parent,
            'Select a database file',
            '', # default dir
            'lacuna_app.sqlite', # default file
            'SQLite Databases (*.sqlite)|*.sqlite|All Files (*.*)|*.*',
            wxFD_OPEN|wxFD_FILE_MUST_EXIST
        );
        $file_browser->ShowModal();

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
        if( $self->intro_panel_exists ) {
            my $schema = wxTheApp->main_schema;
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
