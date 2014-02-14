
package LacunaWaX {
    use v5.14;
    use strict;
    use warnings;
    use Data::Dumper;  $Data::Dumper::INDENT = 1;
    use English qw( -no_match_vars );
    use Games::Lacuna::Client::TMTRPC;
    use Getopt::Long;
    use Math::BigFloat;
    use Moose;
    use Time::Duration;
    use Time::HiRes;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MOVE EVT_CLOSE);

    use LacunaWaX::Preload::Cava;
    use LacunaWaX::MainFrame;
    use LacunaWaX::MainSplitterWindow;
    use LacunaWaX::Model::Client;
    use LacunaWaX::Model::Container;
    use LacunaWaX::Model::WxContainer;
    use LacunaWaX::Schedule;
    use LacunaWaX::Servers;

    use MooseX::NonMoose;
    $Wx::App::VERSION = "1.0";
    extends 'Wx::App';

    our $VERSION = '2.0';

    has 'root_dir'          => (is => 'rw', isa => 'Str',                               required   => 1);
    has 'bb'                => (is => 'rw', isa => 'LacunaWaX::Model::Container',       lazy_build => 1);
    has 'wxbb'              => (is => 'rw', isa => 'LacunaWaX::Model::WxContainer',     lazy_build => 1);
    has 'db_file'           => (is => 'rw', isa => 'Str',                               lazy_build => 1);
    has 'db_log_file'       => (is => 'rw', isa => 'Str',                               lazy_build => 1);
    has 'icon_bundle'       => (is => 'rw', isa => 'Wx::IconBundle',                    lazy_build => 1);

    ### X and Y of the current screen resolution
    has 'display_x'     => (is => 'rw', isa => 'Int', lazy_build => 1);
    has 'display_y'     => (is => 'rw', isa => 'Int', lazy_build => 1);

    has 'main_frame' => (
        is      => 'rw', 
        isa     => 'LacunaWaX::MainFrame', 
        lazy_build => 1,
        handles => {
            menu_bar            => 'menu_bar',
            intro_panel         => 'intro_panel',
            has_intro_panel     => 'has_intro_panel',
            left_pane           => 'left_pane',
            right_pane          => 'right_pane',
            splitter            => 'splitter',
        }
    );
    has 'servers' => (
        is      => 'ro',
        isa     => 'LacunaWaX::Servers',
        handles => {
            server_ids              => 'ids',
            server_records          => 'records',
            server_pairs            => 'pairs',
            server_record_by_id     => 'get',
        },
        lazy_build => 1,
    );
    has 'server' => (
        is              => 'rw',
        isa             => 'Maybe[LacunaWaX::Model::Schema::Servers]',
        clearer         => 'clear_server',
        documentation   => q{
            DBIC Servers record of the server to which we're connected.
            Populated by call to ->game_connect().
        },
    );
    has 'account' => (
        is              => 'rw', 
        isa             => 'Maybe[LacunaWaX::Model::Schema::ServerAccounts]',
        clearer         => 'clear_server_prefs',
        documentation   => q{
            DBIC ServerAccounts record of the account we're connected as.
            Populated by call to ->game_connect().
        },
    );
    has 'game_client' => (
        is              => 'rw', 
        isa             => 'LacunaWaX::Model::Client', 
        clearer         => 'clear_game_client',
        predicate       => 'has_game_client',
        documentation   => q{
            Chicken-and-egg.
            This makes sense as an attribute of LacunaWaX, but it cannot connect 
            until the user has updated their username/password in the 
            Preferences window during their first run.  Populated by call to 
            ->game_connect().
        }
    );

    sub FOREIGNBUILDARGS {#{{{
        return (); # Wx::App->new() gets no arguments.
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->SetTopWindow($self->main_frame->frame);
        $self->main_frame->frame->SetIcons( $self->icon_bundle );
        $self->main_frame->frame->Show(1);
        my $logger = $self->bb->resolve( service => '/Log/logger' );
        $logger->debug('Starting application');

        $self->_set_events;
        return $self;
    }
    sub _build_bb {#{{{
        my $self = shift;
        return LacunaWaX::Model::Container->new(
            name            => 'my container',
            root_dir        => $self->root_dir,
            db_file         => $self->db_file,
            db_log_file     => $self->db_log_file,
        );
    }#}}}
    sub _build_db_file {#{{{
        my $self = shift;
        my $file = $self->root_dir . '/user/lacuna_app.sqlite';
        return $file;
    }#}}}
    sub _build_db_log_file {#{{{
        my $self = shift;
        my $file = $self->root_dir . '/user/lacuna_log.sqlite';
        return $file;
    }#}}}
    sub _build_display_x {#{{{
        my $self = shift;
        return Wx::SystemSettings::GetMetric(wxSYS_SCREEN_X);
    }#}}}
    sub _build_display_y {#{{{
        my $self = shift;
        return Wx::SystemSettings::GetMetric(wxSYS_SCREEN_Y);
    }#}}}
    sub _build_icon_bundle {#{{{
        my $self = shift;

        my $bundle = Wx::IconBundle->new();
        my @images = map{ join q{/}, ($self->bb->resolve(service => q{/Directory/ico}), qq{frai_$_.png}) }qw(16 24 32 48 64 72 128 256);
        foreach my $i(@images) {
            $bundle->AddIcon( Wx::Icon->new($i, wxBITMAP_TYPE_ANY) );
        }

        return $bundle;
    }#}}}
    sub _build_main_frame {#{{{
        my $self = shift;

        my $args = {
            app         => $self,
            title       => $self->bb->resolve(service => '/Strings/app_name'),
        };

        ### Coords to place frame if we saved them from a previous run.
        ### If not, we'll start the main_frame in the center of the display.
        my $schema = $self->bb->resolve( service => '/Database/schema' );
        if( my $db_x = $schema->resultset('AppPrefsKeystore')->find({ name => 'MainWindowX' }) ) {
            if( my $db_y = $schema->resultset('AppPrefsKeystore')->find({ name => 'MainWindowY' }) ) {
                my( $x, $y ) = ($db_x->value, $db_y->value );
                if( 
                        $x >= 0 and $x < $self->display_x
                    and $y >= 0 and $y < $self->display_y
                ) {
                    ### Attempting to fix the hidden window problem.  Only try  
                    ### to set the MainFrame's position if the recorded X and 
                    ### Y are inside the bounds of the current display.
                    $args->{'position'} = Wx::Point->new($x, $y);
                }
            }
        }


        ### position arg is optional.  Window will be centered on display if 
        ### position is not sent.
        my $mf = LacunaWaX::MainFrame->new( $args );
        return $mf;
    }#}}}
    sub _build_servers {#{{{
        my $self        = shift;
        my $schema      = $self->bb->resolve( service => '/Database/schema' );
        return LacunaWaX::Servers->new( schema => $schema );
    }#}}}
    sub _build_wxbb {#{{{
        my $self = shift;
        return LacunaWaX::Model::WxContainer->new(
            name        => 'wx container',
            root_dir    => $self->root_dir,
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE( $self->main_frame->frame, sub{$self->OnClose(@_)} );
        return;
    }#}}}

    sub api_ship_name {#{{{
        my $self = shift;
        my $ship = shift;

=head2 api_ship_name

Given a human-friendly ship name as returned by human_ship_name, this turns it 
back into an API-friendly name (eg "Snark 3" => "snark3").

=cut

        $ship =~ s/\s(\d)/$1/g;     # <space> digit => digit
        $ship =~ s/ /_/g;           # space => underscore
        $ship = lc $ship;           # lowercase the whole mess
        return $ship;
    }#}}}
    sub build_img_list_glyphs {#{{{
        my $self = shift;

=head2 build_img_list_glyphs

Returns a Wx::ImageList of glyphs.  ImageList contains one image per glyph 
type, ordered alpha by glyph name.

Does I<not> return a singleton; a new ImageList is created each time this is 
called.

=cut

        my $img_list = Wx::ImageList->new( '39', '50', '0', '20' );
        foreach my $g( @{$self->game_client->glyphs} ) {#{{{

            my $img = $self->wxbb->resolve(service => "/Assets/images/glyphs/$g.png");
            $img->Rescale('39', '50');
            my $bmp = Wx::Bitmap->new($img);

            $img_list->Add($bmp, wxNullBitmap);
        }#}}}
        return $img_list;
    }#}}}
    sub build_img_list_warships {#{{{
        my $self = shift;

=head2 build_img_list_warships

Returns a Wx::ImageList of warships.  ImageList contains one image per warship  
as returned by $self->warships.

Does I<not> return a singleton; a new ImageList is created each time this is 
called.

04/30/2013 - I've added the code to resolve the ship images out of the 
assets.zip file, but because this code is not being used, that zip file does not 
contain any ships images.  If this becomes needed, add the ships images to that 
assets file and this method /should/ just work.

04/05/2013 - this is not being used by anything, so I'm removing the ships 
images from user/assets/ to keep them from having to be installed each time.

=cut

        my $img_list = Wx::ImageList->new( '50', '50', '0', '4' );
        foreach my $ship( @{$self->game_client->warships} ) {

            my $img = $self->wxbb->resolve(service => "/Assets/images/ships/$ship.png");
            $img->Rescale('50', '50');
            my $bmp = Wx::Bitmap->new($img);

            $img_list->Add($bmp, wxNullBitmap);
            $self->Yield;
        }

        return $img_list;
    }#}}}
    sub caption {#{{{
        my $self = shift;
        my $msg  = shift;

=head2 caption

Sets the main frame caption text and returns the previously-set text

 my $old_caption = $app->caption('New Text');

Really just a convenience method to keep you from having to call

 my $old_caption = $self->main_frame->status_bar->change_caption('New Text');

=cut

        my $old_text = $self->main_frame->status_bar->change_caption($msg);
        return $old_text;
    }#}}}
    sub cartesian_distance {#{{{
        my $self = shift;
        my $ox = shift;
        my $oy = shift;
        my $tx = shift;
        my $ty = shift;

=head2 cartesian_distance

Returns the distance between two points.

 my $dist = $client->cartesian_distance(
    $origin_x, $origin_y,
    $target_x, $target_y,
 );

Caution; the number returned is likely to be big and floaty.  Don't try to 
perform arithmetic on it without Math::BigFloat.

=cut

        return sqrt( ($tx - $ox)**2 + ($ty - $oy)**2 );
    }#}}}
    sub database_checks_out  {#{{{
        my $self    = shift;
        my $dbh     = shift;
        my $tables  = shift;

=head2 database_checks_out

Returns true if the database passed in contains the correct tables and columns.

 $must_have_these = {
  table_name_one => [ column_one,   column_two  ],
  table_name_two => [ column_three, column_four ],
 };

 $dbh = get_DBI_database_handle_from_somewhere();

 if( database_checks_out($dbh, $tables) ) {
  say "Your database is OK";
 }
 else {
  say "Your database is NOT OK.";
 }

=cut

        ### Ensure the tables we're going to try to import exist in the old 
        ### database
        my %checked_tables = ();
        map{ $checked_tables{$_} = 0 }(keys %{$tables} );
        my $tbl_sth = try {
            $dbh->table_info(undef, undef, undef, 'TABLE');
        }
        catch { return };
        return 0 unless $tbl_sth;
        while( my $r = $tbl_sth->fetchrow_hashref ) {
            delete $checked_tables{$r->{'TABLE_NAME'}};
        }
        return 0 if keys %checked_tables;

        ### Ensure each of those tables contains the correct columns
        foreach my $tbl( keys %{$tables} ) {
            my %checked_cols = ();
            map{ $checked_cols{$_} = 0 }(@{$tables->{$tbl}});
            my $sth = $dbh->column_info(undef, undef, $tbl, undef);
            while( my $r = $sth->fetchrow_hashref ) {
                delete $checked_cols{$r->{'COLUMN_NAME'}};
            }
            return 0 if keys %checked_cols;
        }

        return 1;
    }#}}}
    sub endthrob {#{{{
        my $self = shift;

        $self->main_frame->status_bar->bar_reset;
        $self->Yield; 
        local %SIG = ();
        $SIG{ALRM} = undef;     ##no critic qw(RequireLocalizedPunctuationVars) - PC thinks $SIG there is a scalar - whoops
        alarm 0;
        return;
    }#}}}
    sub game_connect {#{{{
        my $self = shift;

=pod

Attempts to connect to the server in $self->server.  "Connect" means "send a 
ping in the form of an "empire get_status call".


Returns true/false on success/fail.

=cut

        my $logger = $self->bb->resolve( service => '/Log/logger' );
        $logger->component('LacunaWaX');
        $logger->debug("Attempting to create client connection");

        my $schema = $self->bb->resolve( service => '/Database/schema' );
        unless( $self->server ) {
            $logger->debug("No server set up yet; cannot connect.");
            return;
        }
        if( 
            my $server_account = $schema->resultset('ServerAccounts')->search({
                server_id => $self->server->id,
                default_for_server => 1
            })->single
        ) {
            $logger->debug("Server is set up; attempting to connect.");
            $self->Yield;
            $self->account( $server_account );

            my $game_client = LacunaWaX::Model::Client->new (
                    app         => $self,
                    bb          => $self->bb,
                    wxbb        => $self->wxbb,
                    server_id   => $self->server->id,
                    rpc_sleep   => 0,
                    allow_sleep => 0,   # Treat '> RPC Limit' error as any other error from the GUI
            );
            $self->game_client( $game_client );

            $self->Yield;
            my $rv = $self->game_client->ping;
            return unless $rv;  # no $rv means bad creds.
            $self->Yield;
        }
        else {
            $self->poperr("Could not find server.");
            return;
        }
        $self->Yield;
        return $self->game_client->ping;    # rslt of the previous call was cached, so this is OK.
    }#}}}
    sub halls_to_level {#{{{
        my $self    = shift;
        my $current = shift;
        my $max     = shift;

=head2 halls_to_level

Returns the number of halls needed to get from one level to another.

 say "It will take " 
    . $client->halls_to_level(4, 10)
    . " halls to go from level 4 to level 10."; # 21

=cut

        return $self->triangle($max) - $self->triangle($current);
    }#}}}
    sub import_old_database {#{{{
        my $self    = shift;
        my $db_file = shift;

        ### Attempts to import the important (there's a linguistic joke hiding 
        ### in there somewhere) stuff from a previous LW database into the 
        ### current one.
        ###
        ### The previous and current databases may not be in exactly the same 
        ### format.  That's OK as long as the previous database contains the 
        ### tables and column listed in $imports, below.
        ###
        ### Dies with message on failure, so wrap in try/catch.

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

        ### Connect to the old database.
        my $options = {sqlite_unicode => 1, quote_names => 1};
        my $old_dbh = DBI->connect("dbi:SQLite:dbname=$db_file", q{}, q{}, $options ) or die "$DBI::errstr\n";

        ### Sanity-check old database.
        unless( $self->database_checks_out($old_dbh, $imports) ) {
            $old_dbh->disconnect();
            die "$db_file is not a LacunaWaX database.\n";
        }

        ### Get DBI connection to the new (current) database.
        my $schema  = $self->bb->resolve( service => '/Database/schema' );
        my $new_dbh = $schema->storage->dbh;

        foreach my $table_name(keys %{$imports}) {
            my $cols        = $imports->{$table_name};
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

        return 1;
    }#}}}
    sub poperr {#{{{
        my $self    = shift;
        my $message = shift || 'Unknown error occurred';
        my $title   = shift || 'Error!';
        Wx::MessageBox($message, $title, wxICON_EXCLAMATION, $self->main_frame->frame );
        return;
    }#}}}
    sub popmsg {#{{{
        my $self    = shift;
        my $message = shift || 'Everything is fine';
        my $title   = shift || 'LacunaWaX';
        Wx::MessageBox($message,
                        $title,
                        wxOK | wxICON_INFORMATION,
                        $self->main_frame->frame );
        return;
    }#}}}
    sub popconf {#{{{
        my $self    = shift;
        my $message = shift || 'Everything is fine';
        my $title   = shift || 'LacunaWaX';

=pod

The rv from this will be either wxYES or wxNO.  BOTH ARE POSITIVE INTEGERS.

So don't do this:

 ### BAD AND WRONG AND EVIL
 if( popconf("Are you really sure", "Really?") ) {
  ### Do Eeet
 }
 else {
  ### User said 'no', so don't really do eeet.
  ### GONNNNNG!  THAT IS WRONG!
 }

That code will never hit the else block, even if the user choses 'No', since the 
'No' response is true.  This could be A Bad Thing.


Instead, you need something like this...

 ### GOOD AND CORRECT AND PURE
 if( wxYES == popconf("Are you really sure", "Really really?") ) {
  ### Do Eeet
 }
 else {
  ### User said 'no', so don't really do eeet.
 }

...or often, more simply, this...

 return if wxNO == popconf("Are you really sure", "Really really?");
 ### do $stuff confident that the user did not say no.

=cut

        my $resp = Wx::MessageBox($message,
                                    $title,
                                    wxYES_NO|wxYES_DEFAULT|wxICON_QUESTION|wxSTAY_ON_TOP,
                                    $self->main_frame->frame );
        return $resp;
    }#}}}
    sub secs_to_human {#{{{
        my $self        = shift;
        my $secs        = shift;
        my $exact_flag  = shift;

=head2 secs_to_human

Returns a nice string in English describing a number of seconds.  By default, 
returns a rounded short string with two time elements.  Pass a true value as 
the second argument to receive a fully accurate (to the second) result.

 $secs = 3603243;

 say $self->secs_to_human($secs);       # "41 days and 17 hours"
 say $self->secs_to_human($secs, 1);    # "41 days, 16 hours, 54 minutes, and 3 seconds";

=cut

        return ($exact_flag) ? duration_exact($secs) : duration($secs);
    }#}}}
    sub str_trim {#{{{
        my $self = shift;
        my $str  = shift;

=head2 str_trim

Basic string trimmer - removes whitespace from front and back of the given 
string.

 my $old = '   foo   ';
 my $new = $self->str_trim($old);
 say "-$new-";  # -foo-

=cut

        $str =~ s/^\s+//;
        $str =~ s/\s+$//;
        return $str;
    }#}}}
    sub throb {#{{{
        my $self = shift;

        $self->main_frame->status_bar->gauge->Pulse;        ## no critic qw(ProhibitLongChainsOfMethodCalls)
        $self->Yield; 
        local %SIG = ();
        $SIG{ALRM} = sub {  ##no critic qw(RequireLocalizedPunctuationVars) - PC thinks $SIG there is a scalar - whoops
            $self->main_frame->status_bar->gauge->Pulse;    ## no critic qw(ProhibitLongChainsOfMethodCalls)
            $self->Yield; 
            alarm 1;
        };
        alarm 1;
        return;
    }#}}}
    sub travel_time {#{{{
        my $self = shift;
        my $rate = shift;
        my $dist = shift;

=head2 travel_time

Returns the time (in seconds) to cover a given distance given a rate of speed, 
where rate is a ship's listed speed.

 my $dist = $client->cartesian_distance(
    $origin_x, $origin_y,
    $target_x, $target_y,
 );
 my $seconds_travelling = $client->travel_time($rate, $dist);

=cut

        my $secs = Math::BigFloat->new($dist);
        $secs->bdiv($rate);
        $secs->bmul(360_000);
        $secs = sprintf "%.0f", $secs;
        return $secs;
    }#}}}
    sub triangle {#{{{
        my $self = shift;
        my $int  = shift;

=head2 triangle 

Returns the triangle sum of a given int.

 say $client->triangle(5);  # 15

=cut

        return( $int * ($int+1) / 2 ); 
    }#}}}

    sub OnClose {#{{{
        my($self, $frame, $event) = @_;

        my $schema = $self->bb->resolve( service => '/Database/schema' );
        my $logger = $self->bb->resolve( service => '/Log/logger' );
        $logger->component('LacunaWaX');

        ### Save main window position
        my $db_x = $schema->resultset('AppPrefsKeystore')->find_or_create({ name => 'MainWindowX' });
        my $db_y = $schema->resultset('AppPrefsKeystore')->find_or_create({ name => 'MainWindowY' });
        my $point = $self->GetTopWindow()->GetPosition;
        $db_x->value( $point->x ); $db_x->update;
        $db_y->value( $point->y ); $db_y->update;

        ### Save main window size
        my $db_w = $schema->resultset('AppPrefsKeystore')->find_or_create({ name => 'MainWindowW' });
        my $db_h = $schema->resultset('AppPrefsKeystore')->find_or_create({ name => 'MainWindowH' });
        my $size = $self->GetTopWindow()->GetSize;
        $db_w->value( $size->width ); $db_w->update;
        $db_h->value( $size->height ); $db_h->update;

        ### Prune old log entries
        my $now   = DateTime->now();
        my $dur   = DateTime::Duration->new(days => 7);     # TBD this duration should perhaps be configurable
        my $limit = $now->subtract_duration( $dur );
        $logger->debug('Pruning old log entries');
        $logger->prune_bydate( $limit );
        $logger->debug('Closing application');

        ### Set the current app version
        ### TBD doing this here is somewhat questionable; see UPGRADING in the 
        ### dev notes file.
        if( my $app_version = $schema->resultset('AppPrefsKeystore')->find_or_create({ name => 'AppVersion' }) ) {
            $app_version->value( $LacunaWaX::VERSION );
            $app_version->update;
        }
        if( my $db_version = $schema->resultset('AppPrefsKeystore')->find_or_create({ name => 'DbVersion' }) ) {
            $db_version->value( $LacunaWaX::Model::Schema::VERSION );
            $db_version->update;
        }

        $event->Skip();
        return;
    }#}}}
    sub OnInit {#{{{
        my $self = shift;
        ### This gets called by the Wx::App (our parent) constructor.  This 
        ### means that $self is not yet a LacunaWaX object, so Moose hasn't 
        ### gotten involved fully yet.
        ### eg $self->root_dir is going to be undef, even though it's required 
        ### and was passed in by the user.
        ###
        ### The point being that any code in here should relate only to the 
        ### Wx::App, not to the LacunaWaX.
        Wx::InitAllImageHandlers();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

 vim: syntax=perl
