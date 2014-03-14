
use v5.14;

package LacunaWaX {
    use Carp;
    use Data::Dumper;
    use DateTime::TimeZone;
    use Time::Duration qw(duration duration_exact);
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MOVE EVT_CLOSE);

    use base 'Wx::App';
    $Wx::App::VERSION   = "2.04";
    our $VERSION        = '2.04';

    use LacunaWaX::Preload::Perlapp;
    use LacunaWaX::MainFrame;
    use LacunaWaX::Model::Globals;
    use LacunaWaX::Model::Globals::Wx;
    use LacunaWaX::Servers;

    sub new {
        my $class = shift;
        my %args  = @_;
        my $self  = $class->SUPER::new();

        croak "root dir is required" unless defined $args{'root_dir'};
        $self->{'root_dir'} = $args{'root_dir'};

        ### Initialize all attributes that can be.  These used to be our lazy 
        ### attributes.
        $self->_init_attrs;

        $self->SetAppName('LacunaWaX');
        $self->SetTopWindow( $self->main_frame->frame );
        $self->main_frame->SetIcon( $self->icon_image );
        $self->main_frame->Show(1);

        $self->logger->debug('Starting application');

        $self->_set_events();
        return $self;
    }
    sub _init_attrs {#{{{
        my $self = shift;

        ### Do not change the order of the attributes without testing.
        ### db_file might depend on the existence of globals, etc.
        my @build_attrs = (
            'globals', 'wxglobals',
            'clock_type', 'time_zone',
            'db_file', 'db_log_file',
            'icon_image',
            'display_x', 'display_y',
            'servers' ,
            'main_frame',
        );
        foreach my $attr(@build_attrs) {
            my $meth = "_build_$attr";
            unless( $self->can( $meth) ) {
                die "Builder expected but not found for attribute '$attr'.";
            }
            $self->$attr( $self->$meth );
        }
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE( $self->main_frame, sub{$self->OnClose(@_)} );
        return;
    }#}}}
    sub OnInit {#{{{
        my $self = shift;
        ### This gets called by the Wx::App (our parent) constructor.  This 
        ### means that $self is not yet a LacunaWaX object; new() has not run 
        ### yet.
        ###
        ### The point being that any code in here should relate only to the 
        ### Wx::App, not to the LacunaWaX.
        Wx::InitAllImageHandlers();
        return 1;
    }#}}}

### Accessors
    sub account {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'account'} = $arg if $arg;
        return $self->{'account'};
    }#}}}
    sub clock_type {#{{{
        my $self = shift;
        my $arg  = shift;

        my $type;
        if( $arg and grep{ /^$arg$/ }(12, 24) ) {
            $type = $arg;
        }
        $self->{'clock_type'} = $type if $type;
        return $self->{'clock_type'};
    }#}}}
    sub db_file {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'db_file'} = $arg if $arg;
        return $self->{'db_file'};
    }#}}}
    sub db_log_file {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'db_log_file'} = $arg if $arg;
        return $self->{'db_log_file'};
    }#}}}
    sub icon_image {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'icon_image'} = $arg if $arg;
        return $self->{'icon_image'};
    }#}}}
    sub game_client {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'game_client'} = $arg if $arg;
        return $self->{'game_client'};
    }#}}}
    sub globals {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'globals'} = $arg if $arg;
        return $self->{'globals'};
    }#}}}
    sub wxglobals {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'wxglobals'} = $arg if $arg;
        return $self->{'wxglobals'};
    }#}}}
    sub display_x {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'display_x'} = $arg if $arg;
        return $self->{'display_x'};
    }#}}}
    sub display_y {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'display_y'} = $arg if $arg;
        return $self->{'display_y'};
    }#}}}
    sub main_frame {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'main_frame'} = $arg if $arg;
        return $self->{'main_frame'};
    }#}}}
    sub root_dir {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'root_dir'} = $arg if $arg;
        return $self->{'root_dir'};
    }#}}}
    sub servers {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'servers'} = $arg if $arg;
        return $self->{'servers'};
    }#}}}
    sub server {#{{{
        my $self = shift;
        my $arg  = shift;
        $self->{'server'} = $arg if $arg;
        return $self->{'server'};
    }#}}}
    sub time_zone {#{{{
        my $self = shift;
        my $arg  = shift;

        ### Accepts a DateTime::TimeZone:: object, or just a time_zone name 
        ### ('local', 'America/New_York', etc), or no arg for a simple 
        ### accessor.

        my $tz;
        if( $arg ) {
            if( (ref $arg) =~ /^DateTime::TimeZone::/ ) {
                $tz = $arg;
            }
            else {
                $tz = try {
                    my $t = DateTime::TimeZone->new( name => $arg );
                    return $t;
                }
                catch {
                    say "===$_===";
                    return;
                };
            }
        }

        $self->{'time_zone'} = $tz if $tz;
        return $self->{'time_zone'};
    }#}}}

### Builders
    sub _build_clock_type {#{{{
        my $self = shift;

        my $schema  = $self->main_schema;
        my $rs      = $schema->resultset('AppPrefsKeystore')->search({ name => 'ClockType' });

        my $clock_type = 12;
        if( my $rec = $rs->next ) {
            $clock_type = $rec->value;
        }

        return $clock_type;
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
    sub _build_globals {#{{{
        my $self = shift;
        my $g = LacunaWaX::Model::Globals->new( root_dir => $self->root_dir );
        return $g;
    }#}}}
    sub _build_icon_image {#{{{
        my $self = shift;

        my $png = join q{/}, ($self->globals->dir_ico, qq{frai_256.png});
        my $img = Wx::Image->new($png, wxBITMAP_TYPE_PNG);
        $img->Rescale(32,32);
        my $bmp = Wx::Bitmap->new($img);

        my $icon = Wx::Icon->new();
        $icon->CopyFromBitmap($bmp);

        return $icon;
    }#}}}
    sub _build_main_frame {#{{{
        my $self = shift;

        my $args = {
            title => $self->GetAppName,
        };

        ### Coords to place frame if we saved them from a previous run.
        ### If not, we'll start the main_frame in the center of the display.
        my $schema = $self->main_schema;
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
        my $self = shift;
        return LacunaWaX::Servers->new( schema => $self->main_schema );
    }#}}}
    sub _build_time_zone {#{{{
        my $self = shift;

        my $schema  = $self->main_schema;
        my $rs      = $schema->resultset('AppPrefsKeystore')->search({ name => 'TimeZone' });

        my $zone_name = 'local';
        if( my $rec = $rs->next ) {
            $zone_name = $rec->value;
        }
        my $tz = try {
            DateTime::TimeZone->new( name => $zone_name );
        }
        catch {
            DateTime::TimeZone->new( name => 'local' ); # in case a bogus string somehow gets into the database.
        };
        return $tz;
    }#}}}
    sub _build_wxglobals {#{{{
        my $self = shift;
        return LacunaWaX::Model::Globals::Wx->new( globals => $self->globals );
    }#}}}

### Handlers
    ### Globals
    sub logger {#{{{
        my $self = shift;
        $self->globals->logger(@_);
    }#}}}
    sub log_schema {#{{{
        my $self = shift;
        $self->globals->log_schema(@_);
    }#}}}
    sub main_schema {#{{{
        my $self = shift;
        $self->globals->main_schema(@_);
    }#}}}
    ### WxGlobals
    sub get_image {#{{{
        my $self = shift;
        $self->wxglobals->get_image(@_);
    }#}}}
    sub set_image {#{{{
        my $self = shift;
        $self->wxglobals->set_image(@_);
    }#}}}
    sub get_font {#{{{
        my $self = shift;
        $self->wxglobals->get_font(@_);
    }#}}}
    sub set_font {#{{{
        my $self = shift;
        $self->wxglobals->set_font(@_);
    }#}}}
    sub get_cache {#{{{
        my $self = shift;
        $self->wxglobals->cache(@_);
    }#}}}
    sub borders_on {#{{{
        my $self = shift;
        $self->wxglobals->borders_on(@_);
    }#}}}
    sub borders_off {#{{{
        my $self = shift;
        $self->wxglobals->borders_off(@_);
    }#}}}
    sub borders_are_on {#{{{
        my $self = shift;
        $self->wxglobals->borders_are_on(@_);
    }#}}}
    sub borders_are_off {#{{{
        my $self = shift;
        $self->wxglobals->borders_are_off(@_);
    }#}}}
    ### Servers
    sub server_ids {#{{{
        my $self = shift;
        $self->servers->ids(@_);
    }#}}}
    sub server_records {#{{{
        my $self = shift;
        $self->servers->records(@_);
    }#}}}
    sub server_record_by_id {#{{{
        my $self = shift;
        $self->servers->get(@_);
    }#}}}
    ### MainFrame
    sub menu_bar {#{{{
        my $self = shift;
        $self->main_frame->menu_bar(@_);
    }#}}}
    sub intro_panel {#{{{
        my $self = shift;
        $self->main_frame->intro_panel(@_);
    }#}}}
    sub has_intro_panel {#{{{
        my $self = shift;
        $self->main_frame->has_intro_panel(@_);
    }#}}}
    sub left_pane {#{{{
        my $self = shift;
        $self->main_frame->left_pane(@_);
    }#}}}
    sub right_pane {#{{{
        my $self = shift;
        $self->main_frame->right_pane(@_);
    }#}}}
    sub splitter {#{{{
        my $self = shift;
        $self->main_frame->splitter(@_);
    }#}}}

### Events
    sub OnClose {#{{{
        my($self, $frame, $event) = @_;

        my $schema = wxTheApp->main_schema;
        $self->logger->component('LacunaWaX');

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
        $self->logger->debug('Pruning old log entries');
        $self->logger->prune_bydate( $limit );
        $self->logger->debug('Closing application');

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

### Utilities
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

            my $img  = $self->get_image( "glyphs/$g.png" );
            $img->Rescale('39', '50');
            my $bmp = Wx::Bitmap->new($img);

            $img_list->Add($bmp, wxNullBitmap);
        }#}}}
        return $img_list;
    }#}}}
    sub build_sizer {#{{{
        my $self        = shift;
        my $parent      = shift;
        my $direction   = shift;
        my $name        = shift or die "iSizer name is required.";
        my $force_box   = shift || 0;
        my $pos         = shift || wxDefaultPosition;
        my $size        = shift || wxDefaultSize;

        my $hr = { };
        if( $self->wxglobals->sizer_borders or $force_box ) {
            $hr->{'box'} = Wx::StaticBox->new($parent, -1, $name, $pos, $size),
            $hr->{'box'}->SetFont( wxTheApp->get_font('para_text_1') );
            $hr->{'sizer'} = Wx::StaticBoxSizer->new($hr->{'box'}, $direction);
        }
        else {
            $hr->{'sizer'} = Wx::BoxSizer->new($direction);
        }

        return $hr->{'sizer'};
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
    $source_x, $source_y,
    $target_x, $target_y,
 );

Caution; the number returned is likely to be big and floaty.  Don't try to 
perform arithmetic on it without Math::BigFloat.

=cut

        return sqrt( ($tx - $ox)**2 + ($ty - $oy)**2 );
    }#}}}
    sub commaize_number {
        my $self    = shift;
        my $num     = shift;
        return $num unless( $num =~ /^[\d]{4,}$/ );

        my @pieces;
        if( $num =~ /^[\d]{4,}$/ ) {
            while($num) {
                my $p;

                if( length $num >= 3 ) {
                    $p = substr($num, ((length $num) - 3), 3, q{});
                }
                else {
                    $p = $num;
                    $num = q{};
                }
                unshift @pieces, $p;
            }
        }

        return join ',', @pieces;
    }
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
        if( keys %checked_tables ) {
            $tbl_sth->finish();
            return 0;
        }

        ### Ensure each of those tables contains the correct columns
        foreach my $tbl( keys %{$tables} ) {
            my %checked_cols = ();
            map{ $checked_cols{$_} = 0 }(@{$tables->{$tbl}});
            my $sth = $dbh->column_info(undef, undef, $tbl, undef);
            while( my $r = $sth->fetchrow_hashref ) {
                delete $checked_cols{$r->{'COLUMN_NAME'}};
            }
            if( keys %checked_cols ) {
                $sth->finish();
                return 0;
            }
        }

        return 1;
    }#}}}
    sub endthrob {#{{{
        my $self = shift;
        $self->main_frame->status_bar->endthrob;
    }#}}}
    sub get_top_left_corner {#{{{
        my $self = shift;
        return $self->GetTopWindow()->GetPosition;
    }#}}}
    sub game_connect {#{{{
        my $self = shift;

=pod

Attempts to connect to the server in $self->server.  "Connect" means "send a 
ping in the form of an "empire get_status call".


Returns true/false on success/fail.

=cut

        $self->logger->component('LacunaWaX');
        $self->logger->debug("Attempting to create client connection");

        my $schema = wxTheApp->main_schema;
        unless( $self->server ) {
            $self->logger->debug("No server set up yet; cannot connect.");
            return;
        }
        if( 
            my $server_account = $schema->resultset('ServerAccounts')->search({
                server_id => $self->server->id,
                default_for_server => 1
            })->single
        ) {
            $self->logger->debug("Server is set up; attempting to connect.");
            $self->Yield;
            $self->account( $server_account );

            my $game_client = LacunaWaX::Model::Client->new (
                    app         => $self,
                    server_id   => $self->server->id,
                    globals     => $self->globals,
                    rpc_sleep   => 0,
                    allow_sleep => 0,   # Treat '> RPC Limit' error as any other error from the GUI
                    use_gui     => 1,   # Allows use of the cache
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
        ### tables and column listed in $sanity.

        ### These tables and columns must exist in any database we attempt to 
        ### import.  They've existed in LW long enough that any database that 
        ### does not have these is simply not an LW database.
        my $sanity = {
            ArchMinPrefs => [qw(
                server_id body_id glyph_home_id pusher_ship_name auto_search_for 
            )],
            BodyTypes => [qw(
                body_id server_id type_general 
            )],
            ServerAccounts => [qw(
                server_id username password default_for_server 
            )],
        };

        ### These are the tables we're going to try to import.  If any of them  
        ### don't exist in the old database, they'll just be skipped.
        ###
        ### The old database may contain these tables sans some columns that 
        ### have been added since. Those will be dealt with; only the existing 
        ### columns will be imported.
        my $imports = [qw( ArchMinPrefs BodyTypes SSAlerts ServerAccounts SitterPasswords )];

        ### Connect to the old database.
        my $options = {sqlite_unicode => 1, quote_names => 1};
        my $old_dbh = DBI->connect("dbi:SQLite:dbname=$db_file", q{}, q{}, $options ) or die "$DBI::errstr\n";

        ### Sanity-check old database.
        unless( $self->database_checks_out($old_dbh, $sanity) ) {
            $old_dbh->disconnect();
            die "$db_file is not a LacunaWaX database.\n";
        }

        ### Get DBI connection to the new (current) database.
        my $schema = wxTheApp->main_schema;
        my $new_dbh = $schema->storage->dbh;

        ### Import
        my @redo_tables = ();
        TABLE:
        foreach my $table_name( @{$imports} ) {#{{{
            my $sel_sth = try { $old_dbh->prepare("SELECT * FROM $table_name") or die; }
                catch { return; }
                or next TABLE;
            $sel_sth->execute();

            ### Pull one rec off $sel_sth so we can get its column names.
            my $rec  = $sel_sth->fetchrow_hashref;
            my @cols = keys %{$rec};
            @cols or next TABLE;
            my @vals = ();
            map{ push @vals, $rec->{$_} }@cols;

            my $comma_cols  = join ', ', @cols;
            my @ques_arr    = ();
            push @ques_arr, '?' for @cols;
            my $ques        = join ',', @ques_arr;

            ### Do that first record that we pulled off the $sel_sth before 
            ### looping the rest of the way through it.
            my $ins_stmt = "INSERT OR IGNORE INTO $table_name ($comma_cols) VALUES ($ques)";
            my $ins_sth = $new_dbh->prepare( $ins_stmt ) or die "no prepare";

            try { $ins_sth->execute(@vals) or die; }
                catch { die "single exe failed"; };

            $new_dbh->begin_work;
            while( my $rec = $sel_sth->fetchrow_hashref ) {
                my @vals = ();
                map{ push @vals, $rec->{$_} }@cols;
                try { $ins_sth->execute(@vals) or die; } 
                    catch { die "loop exe failed"; };
            }
            $new_dbh->commit;

        }#}}}

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
        $self->Yield;
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
        $self->main_frame->status_bar->throb;
    }#}}}
    sub travel_time {#{{{
        my $self = shift;
        my $rate = shift;
        my $dist = shift;

=head2 travel_time

Returns the time (in seconds) to cover a given distance given a rate of speed, 
where rate is a ship's listed speed.

 my $dist = $client->cartesian_distance(
    $source_x, $source_y,
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

}

1;

