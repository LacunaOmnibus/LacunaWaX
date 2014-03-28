
package LacunaWaX::MainFrame::MenuBar::Tools::GLC {
    use v5.14;
    use Archive::Zip;
    use Capture::Tiny qw(:all);
    use Data::Dumper;
    use File::Temp;
    use LWP::UserAgent;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);
    use YAML::Any qw(DumpFile);

    with 'LacunaWaX::Roles::MainFrame::MenuBar::Menu';

    has 'glc_url' => (
        is          => 'rw',
        isa         => 'URI',
        lazy        => 1,
        default     => sub{ URI->new('https://github.com/tsee/Games-Lacuna-Client/archive/master.zip') },
    );
    has 'itm_install_glc' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        lazy_build  => 1,
    );
    has 'itm_install_mods' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        lazy_build  => 1,
    );
    has 'mods_to_install' => (
        is          => 'rw',
        isa         => 'ArrayRef',
        lazy_build  => 1,
    );
    has 'status' => (
        is          => 'rw',
        isa         => 'LacunaWaX::Dialog::Status',
        lazy_build  => 1,
    );
    has 'ua' => (
        is          => 'rw',
        isa         => 'LWP::UserAgent',
        lazy_build  => 1,
    );

    sub BUILD {
        my $self    = shift;
        $self->_set_events();

        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;

        EVT_MENU(       $self->parent,                  $self->itm_install_glc->GetId,      sub{ $self->OnInstallGLC()  }   );
        #EVT_MENU(       $self->parent,                  $self->itm_install_mods->GetId,     sub{ $self->OnInstallMods() }   );

        return 1;
    }#}}}

    sub _build_itm_install_glc {#{{{
        my $self = shift;
        my $menu_item = $self->Append( -1, 'Install &GLC', "Install current GLC package" );
        return $menu_item;
    }#}}}
    sub _build_itm_install_mods {#{{{
        my $self = shift;
        ### Fuck it.  Capture::Tiny is simply not playing nicely with the 
        ### PDK-produced binaries.  After GLC gets installed, the user can run 
        ### ppm_install.pl themselves.
        #my $menu_item = $self->Append( -1, 'Install &Mods', "Install Perl modules needed by GLC" );
        #return $menu_item;
        return 1;
    }#}}}
    sub _build_mods_to_install {#{{{
        my $self = shift;
        my $list = [
            'AnyEvent',
            'Browser::Open',
            'Class::MOP',
            'Class::XSAccessor',
            'Crypt::SSLeay',
            'Data::Dumper',
            'Date::Format',
            'Date::Parse',
            'DateTime',
            'Exception::Class',
            'File::HomeDir',
            'HTTP::Request',
            'HTTP::Response',
            'IO::Interactive',
            'JSON::RPC::Common',
            'JSON::RPC::LWP',
            'LWP::UserAgent',
            'Math::Round',
            'MIME::Lite',
            'Moose',
            'Number::Format',
            'Scalar::Util',
            'Time::HiRes',
            'Try::Tiny',
            'URI',
            'YAML::Any',
            'namespace::clean',
        ];
        return $list;
    }#}}}
    sub _build_status {#{{{
        my $self = shift;
        my $status = LacunaWaX::Dialog::Status->new(
            parent          => $self->menu,
            title           => 'Install Perl Modules',
            user_closeable  => 0,
        );
        return $status;
    }#}}}
    sub _build_ua {#{{{
        my $self = shift;
        my $ua = LWP::UserAgent->new(
            agent   => 'lwp-perl-lacunawax/' . wxTheApp->VERSION,
            timeout => 5,
        );
        return $ua;
    }#}}}

    sub OnInstallGLC {#{{{
        my $self = shift;

        unless( wxYES == wxTheApp->popconf("If you have not yet read the help page on this, please stop and go do so now.  Have you read that?") ) {
            return;
        }

        my $attempt_dir = q{};
        if( $^O eq 'MSWin32' ) {
            $attempt_dir = 'C:\Lacuna\tsee';
            mkdir $attempt_dir unless -e $attempt_dir;
        }
        else {
            ### The non-windows user is more rare than the windows user, and 
            ### is much more likely to be able to figure out where they want 
            ### this to go without any help.
        }

        ### Open modal dir chooser dialog
        my $dir_browser = Wx::DirDialog->new(
            $self->parent->frame,
            'Choose location for GLC.  Recommended is C:\Lacuna\tsee ',
            $attempt_dir,
            0,  # style
            wxDefaultPosition,
        );
        if( $dir_browser->ShowModal() == wxID_CANCEL ) {
            return;
        }
        my $dest = $dir_browser->GetPath;

        ### Trailing slash has to be forced, or the extract will actually 
        ### occur in $dest/../
        $dest .= '/' unless $dest =~ m{[\/]$};

        ### LWP the GLC zip file
        my $resp = $self->ua->get( $self->glc_url );
        unless( $resp->is_success ) {
            wxTheApp->poperr( $resp->status_line );
            return;
        }

        ### Write it to a temp file
        my( $zh, $zn ) = File::Temp::tempfile();    # $zn is a full path.
        binmode $zh;
        print $zh $resp->decoded_content;
        close $zh;

        ### Unzip it to the directory chosen by the user
        my $zip = Archive::Zip->new( $zn );
        $zip->extractTree( 'Games-Lacuna-Client-master/', $dest );

        ### Create lacuna.yml in $target/tsee/examples/ containing the user's 
        ### current info.
        unless( -e -d "$dest/examples" ) {
            wxTheApp->poperr("Unknown error occurred during download/unzip; impossible to continue.");
            return;
        }

        ### Create lacuna.yml
        my $user_info = {
            server_uri          => wxTheApp->game_client->protocol . '://' . wxTheApp->game_client->url,
            api_key             => 'anonymous',
            empire_name         => wxTheApp->game_client->empire_name,
            empire_password     => wxTheApp->game_client->empire_pass,
            session_persistent  => 1,
        };
        DumpFile("$dest/examples/lacuna.yml", $user_info);

        wxTheApp->popmsg(
            "GLC has been downloaded to $dest and configured for your empire.",
            "GLC Downloaded"
        );

        return 1;
    }#}}}
    sub OnInstallMods {#{{{
        my $self = shift;

=pod

I originally used backticks (my $test = `perl -v`) to see if perl and ppm were 
installed.  But since the executable is being created as a GUI, there's no 
shell for backticks to make use of, so that fails in the exe.

Now using system() instead.

=cut

        ### Used by multiple Capture::Tiny::capture() calls below
        my($out,$err,$exit);

        ( $out, $err, $exit ) = capture{ system("perl", "-e1"); };
        if( $exit ) {
            wxTheApp->poperr("You don't appear to have Perl installed yet (if you do, it's not in your PATH).  You'll need to go fix that first.");
            return;
        }

        ( $out, $err, $exit ) = capture{ system("ppm", "help"); };
        if( $exit ) {
            wxTheApp->poperr("You have Perl installed and in your PATH, but it's not ActiveState Perl, so I can't help you.");
            return;
        }

        ### Set determinant gauge range.
        wxTheApp->gauge_range( scalar @{$self->mods_to_install} );

        $self->status->show;
        $self->status->say("This is going to take a little while.  This window will close automatically when all installations are complete.\nA single individual install may take a minute or two, so be patient.");
        $self->status->say_recsep;
        my $cnt = 0;
        for my $m( sort @{ $self->mods_to_install } ) {
            $self->status->say("Installing $m...");
            $exit = 1;
            ($out,$err,$exit) = capture {
                system("ppm", "install", $m);
            }
            ### An install error code of 1 means it failed, but that could be 
            ### because it's already installed.  Don't bomb out on that.

            ### The mod should be installed.  But attempting "perl -M$m -e1" 
            ### is blowing up Capture::Tiny when run from an executable, so we 
            ### can't really check to see if it's been installed.

            $cnt++;
            wxTheApp->gauge_value($cnt);
            wxTheApp->gauge_update();
        }
        $self->status->say_recsep;
        $self->status->say('Module Installation Complete!');
        sleep 2;
        $self->status->close;
        wxTheApp->gauge_value(0);

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
