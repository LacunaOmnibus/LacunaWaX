
package LacunaWaX::MainFrame {
    use v5.14;
    use Data::Dumper;
    use Moose;
    use POSIX qw(:sys_wait_h);
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_CLOSE EVT_SET_FOCUS EVT_KILL_FOCUS EVT_SIZE);

    use LacunaWaX::Dialog::Status;
    use LacunaWaX::MainFrame::IntroPanel;
    use LacunaWaX::MainFrame::MenuBar;
    use LacunaWaX::MainFrame::StatusBar;
    use LacunaWaX::MainSplitterWindow;

    has 'frame' => (
        is          => 'rw',
        isa         => 'Wx::Frame',
        lazy_build  => 1,
        handles => {
            Connect             => "Connect",
            CreateStatusBar     => "CreateStatusBar",
            Destroy             => "Destroy",
            GetSize             => "GetSize",
            GetStatusBar        => "GetStatusBar",
            Layout              => "Layout",
            SetMenuBar          => "SetMenuBar",
            SetIcon             => "SetIcon",
            SetSize             => "SetSize",
            SetSizer            => "SetSizer",
            SetTitle            => "SetTitle",
            Show                => "Show",
        },
    );

    has 'position'  => (
        is          => 'rw', 
        isa         => 'Maybe[Wx::Point]',
        lazy_build  => 1,
        documentation => q{
            Optional - if sent, it will be the point of the upper-left corner of the ap.
            If no position is passed in, the ap will be displayed centered on the screen.
        }
    );

    has 'status_bar' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainFrame::StatusBar',
        lazy_build  => 1,
        handles     => {
            endthrob    => 'endthrob',
            throb       => 'throb',
        }
    );

    has 'style'     => (is => 'rw', isa => 'Int',       lazy_build => 1);
    has 'title'     => (is => 'rw', isa => 'Str',       lazy_build => 1);
    has 'size'      => (is => 'rw', isa => 'Wx::Size',  lazy_build => 1);
    has 'icon'      => (is => 'rw', isa => 'Wx::Icon',  lazy_build => 1);

    ### First run will try to start at 800x900 unless that's too big for the 
    ### current screen resolution.
    has 'default_width'     => (is => 'ro', isa => 'Int', lazy_build => 1);
    has 'default_height'    => (is => 'ro', isa => 'Int', lazy_build => 1);

    has 'menu_bar'      => (is => 'rw', isa => 'LacunaWaX::MainFrame::MenuBar',     lazy_build => 1 );

    has 'intro_panel' => (
        is          => 'rw', 
        isa         => 'LacunaWaX::MainFrame::IntroPanel',
        lazy_build  => 1,
        clearer     => 'clear_intro_panel',
        predicate   => 'has_intro_panel',
    );

    has 'splitter' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow',
        lazy_build  => 1, 
        clearer     => 'clear_splitter',
        predicate   => 'has_splitter',
        handles => {
            left_pane  => 'left_pane',
            right_pane => 'right_pane',
        }
    );

    has 'intro_panel_sizer' => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1 );
    has 'splitter_sizer'    => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1 );

    sub BUILD {
        my $self = shift;

        $self->Show(0);
        $self->SetMenuBar($self->menu_bar->menu_bar);
        $self->intro_panel_sizer->Add( $self->intro_panel->main_panel, 1, wxEXPAND );
        $self->SetSizer($self->intro_panel_sizer);

        ### The intro panel could really live without the status bar.  If you 
        ### wanted to skip it there for a cleaner look, this line could be 
        ### removed.  The status bar would then be created on subsequent 
        ### panels by its lazy builder.
        $self->_build_status_bar;

        $self->_set_events;
        $self->Show(1);
        return $self;
    };

    sub _build_default_height {#{{{
        my $self = shift;
        my( $sw, $sh ) = $self->get_screen_resolution;
        my $desired = 850;
        return( $sh < $desired ) ? $sh - 50 : $desired;
    }#}}}
    sub _build_default_width {#{{{
        my $self = shift;
        my( $sw, $sh ) = $self->get_screen_resolution;
        my $desired = 800;
        return( $sw < $desired ) ? $sw - 50 : $desired;
    }#}}}
    sub _build_frame {#{{{
        my $self = shift;

        my $frame = Wx::Frame->new(
            undef, -1, 
            $self->title,
            $self->position,
            $self->size,
            wxCAPTION|wxCLOSE_BOX|wxMINIMIZE_BOX|wxMAXIMIZE_BOX|wxSYSTEM_MENU|wxRESIZE_BORDER|wxCLIP_CHILDREN,
        );

        ### If $self->position is at (0,0), that means this is a first run; 
        ### there's no saved position from last time and we're using the 
        ### defaults.  In that case, center the frame.
        unless( $self->position->x or $self->position->y ) {
            $frame->Centre(wxBOTH);
        }

        return $frame;
    }#}}}
    sub _build_icon {#{{{
        my $self = shift;

        my $icon = Wx::Icon->new(
            join q{/}, wxTheApp->dir_assets, 'Futurama', '128', 'frai_128.png',
            wxBITMAP_TYPE_ANY,
        );

        return $icon;
    }#}}}
    sub _build_intro_panel_sizer {#{{{
        my $self = shift;
        my $ips = Wx::BoxSizer->new(wxHORIZONTAL);
        return $ips;
    }#}}}
    sub _build_intro_panel {#{{{
        my $self = shift;
        return LacunaWaX::MainFrame::IntroPanel->new( parent => $self );
    }#}}}
    sub _build_menu_bar {#{{{
        my $self = shift;
        my $mb = LacunaWaX::MainFrame::MenuBar->new( parent => $self );
        return $mb;
    }#}}}
    sub _build_position {#{{{
        my $self = shift;
        my $mb = Wx::Point->new( 0, 0 );    # Don't change this default position from 0,0
        return $mb;
    }#}}}
    sub _build_size {#{{{
        my $self = shift;

        my $s = wxDefaultSize;

        ### Maintain the h/w most recently set by the user
        my($w,$h) = ( $self->default_width, $self->default_height );  # defaults
        my $schema = wxTheApp->main_schema;
        if( my $db_w = $schema->resultset('AppPrefsKeystore')->find({ name => 'MainWindowW' }) ) {
            $w = $db_w->value;
        }
        if( my $db_h = $schema->resultset('AppPrefsKeystore')->find({ name => 'MainWindowH' }) ) {
            $h = $db_h->value;
        }

        ### Obviously must be called if we started with the wxDefaultSize 
        ### constant.
        ### If we start with the constructor, this shouldn't be necessary.
        ### But in that case, this actually has no effect at all whether it's 
        ### called or not.
        $s->SetWidth($w);
        $s->SetHeight($h);

        ### Regardless of which method of generating $s you used, the 
        ### following all produce the same output.
        ### But only starting with wxDefaultSize has any effect on the actual 
        ### starting size of the ap.
        #say ref $s;
        #say $s->width;
        #say $s->height;
        #say $s->IsFullySpecified;

        return $s;
    }#}}}
    sub _build_splitter {#{{{
        my $self = shift;

        my $y = LacunaWaX::MainSplitterWindow->new( parent => $self );
        return $y;
    }#}}}
    sub _build_splitter_sizer {#{{{
        my $self = shift;
        my $y= Wx::BoxSizer->new(wxHORIZONTAL);
        return $y;
    }#}}}
    sub _build_status_bar {#{{{
        my $self = shift;
        my $sb = LacunaWaX::MainFrame::StatusBar->new( parent => $self );
        return $sb;
    }#}}}
    sub _build_style {#{{{
        my $self = shift;
        return wxCAPTION|wxCLOSE_BOX|wxMINIMIZE_BOX|wxMAXIMIZE_BOX|wxSYSTEM_MENU|wxRESIZE_BORDER|wxCLIP_CHILDREN;
    }#}}}
    sub _build_title {#{{{
        my $self = shift;
        return wxTheApp->GetAppName();
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE($self->frame, sub{$self->OnClose(@_)});
        return;
    }#}}}

    before 'clear_intro_panel' => sub {#{{{
        my $self = shift;
        $self->intro_panel->main_panel->Destroy();
    };#}}}
    before 'clear_splitter' => sub {#{{{
        my $self = shift;
        $self->splitter->splitter_window->Destroy();
        return;
    };#}}}

    sub get_screen_resolution {#{{{
        my $self = shift;
        my $d = Wx::Display->new(0);
        my $s = $d->GetClientArea;
        return( $s->width, $s->height );
    }#}}}

    sub OnClose {#{{{
        my $self    = shift;
        my $frame   = shift;
        my $event   = shift;

        if( $self->has_splitter ) {
            $self->splitter->OnClose;
        }
        $event->Skip();
        return;
    }#}}}
    sub OnGameServerConnect {#{{{
        my $self        = shift;
        my $server_id   = shift;

        wxTheApp->throb();
        if( $self->has_intro_panel ) {
            ### Keep the user from double clicking the connect button and thus 
            ### producing a "You're already connected" poperr.
            foreach my $srvr_id( keys %{$self->intro_panel->buttons} ) {
                $self->intro_panel->buttons->{$srvr_id}->Disable();
                wxTheApp->Yield();
            }
        }

        if($self->has_splitter) {
            ### We're already connected so a splitter is displayed.  Clear 
            ### it.
            $self->clear_splitter;
            wxTheApp->Yield();
        }

        my $schema = wxTheApp->main_schema;
        if( my $server = $schema->resultset('Servers')->find({id => $server_id}) ) {
            wxTheApp->server( $server );

            wxTheApp->caption("Connecting...");

            unless( wxTheApp->game_connect ) {
                ### Probably bad creds filled out in Prefs frame.  Undef 
                ### server so we don't get told we're "Already Connected" on 
                ### our next attempt.
                wxTheApp->server(undef);
                wxTheApp->Yield();
                wxTheApp->endthrob();
                wxTheApp->caption("Connection Failed!  Correct your login credentials in Edit... Preferences.");
                return;
            }
            if( $self->has_intro_panel ) {
                $self->clear_intro_panel;
                wxTheApp->Yield();
            }

            ### Enable any menu items that were disabled on creation because we 
            ### weren't connected yet.
            $self->menu_bar->show_connected();
            wxTheApp->Yield();

            $self->splitter_sizer->Add( $self->splitter->splitter_window, 1, wxEXPAND );
            $self->Layout();
            wxTheApp->Yield();

            wxTheApp->caption("Connected to " . $server->name . " as " . wxTheApp->account->username);
            wxTheApp->endthrob();
        }
        else {
            Wx::MessageBox("Invalid Server!", "Whoops", wxICON_EXCLAMATION, $self);
        }

        return;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
