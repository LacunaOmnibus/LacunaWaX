
=head2 CHILD WINDOWS

Each prop displayed in the NewPropositionsPane is its own PropRow object.  Each of 
these rows creates its own Dialog::Status object which will display status of 
sitter voting on that particular prop.

So creation and destruction of the Dialog::Status windows is the responsibility of 
the individual PropRow objects; see PropRow.pm for that.

Self-voting does not display a Dialog::Status as it's not necessary.

=cut

package LacunaWaX::MainSplitterWindow::RightPane::NewPropositionsPane {
    use v5.14;
    use LacunaWaX::Model::Client;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHOICE);
    with 'LacunaWaX::Roles::MainSplitterWindow::RightPane';

    use LacunaWaX::MainSplitterWindow::RightPane::NewPropositionsPane::PropRow;

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
    );

    #########################################

    ### Name and ID of the planet with the embassy
    has 'planet_name'   => (is => 'rw', isa => 'Str');
    has 'planet_id'     => (is => 'rw', isa => 'Int');

    has 'embassy'  => (
        is          => 'rw', 
        isa         => 'Games::Lacuna::Client::Buildings::Embassy',
    );

    has 'flg_embassy_planet_validated'  => (
        is          => 'rw', 
        isa         => 'Bool',
        default     => 0
    );

    has 'lbl_embassy_planet' => (
        is          => 'rw',
        isa         => 'Wx::StaticText',
        lazy_build  => 1
    );
    has 'chc_embassy_planet' => (
        is          => 'rw', 
        isa         => 'Wx::Choice',
        lazy_build  => 1,
    );
    has 'btn_embassy_planet' => (
        is          => 'rw', 
        isa         => 'Wx::Button',
        lazy_build  => 1,
    );

    has 'props' => (is => 'rw', isa => 'ArrayRef',  lazy_build => 1);

    has 'rows' => (is => 'rw', isa => 'ArrayRef', lazy => 1, default => sub{ [] });

    has 'already_voted' => (is => 'rw', isa => 'HashRef', lazy => 1, default => sub{ {} },
        clearer => 'clear_already_voted',
        documentation => q/
            If a user has already voted on one prop, they've probably already voted on all of them.
            Players who've already voted on something get put in here.
            { player_name => their record in the SitterPasswords table. }
        /
    );
    has 'over_rpc' => (is => 'rw', isa => 'HashRef', lazy => 1, default => sub{ {} },
        documentation => q{
            Players who are over their daily RPC usage get put in here (by name) so we don't try 
            voting for them again (no point).
        }
    );

    has 'row_spacer_size' => (is => 'rw', isa => 'Int', lazy => 1, default => 1,
        documentation => q{
            The pixel size of the horizontal spacer used to slightly separate each row
        }
    );

    has 'szr_header'               => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => 'vertical'     );
    has 'szr_embassy_planet'       => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => 'vertical'     );
    has 'szr_props'                => (is => 'rw', isa => 'Wx::Sizer',                          documentation => 'vertical'     );
    has 'szr_close_status'         => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => 'horizontal'   );

    has 'lbl_header'                => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_instructions_box'      => (is => 'rw', isa => 'Wx::BoxSizer',      lazy_build => 1);
    has 'lbl_instructions'          => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_close_status'          => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'chk_close_status'          => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->szr_header->Add($self->lbl_header, 0, 0, 0);
        $self->szr_header->AddSpacer(5);
        $self->szr_header->Add($self->lbl_instructions_box, 0, 0, 0);

        $self->szr_embassy_planet->Add($self->lbl_embassy_planet, 0, 0, 0);
        $self->szr_embassy_planet->Add($self->chc_embassy_planet, 0, 0, 0);
        $self->szr_embassy_planet->Add($self->btn_embassy_planet, 0, 0, 0);

    ### *SIGH*.
    ### TheTower says that the user's Embassy ID now gets handed back in the 
    ### empire status blob, so all this setting of an embassy is not necessary 
    ### anymore.  Figures.
    ###
    ### But that does mean that I won't have to fiddle the sitter manager 
    ### dialog.

    ### Create sizer with drop-down containing "None" (default) and list of 
    ### planets.  "Pick which planet has your embassy.  If you have more than 
    ### one embassy, pick any planet with an embassy; it doesn't matter 
    ### which".
    ###
    ### If there's an ID stored, ensure that planet has an embassy.  If 
    ### there's an ID but no embassy at that ID, produce popup error.
    ###
    ### If there's an ID stored and an embassy is on that planet, set 
    ### flg_embassy_planet_validated to true.
    ###
    ### If flg_embassy_planet_validated is false, stop here.
    ###
    ### ALMOST DONE TO HERE
    ###     When the user first sets their embassy planet, we'll need to 
    ###     either call a "show current votes" method, or (easier), just tell 
    ###     the user in the "your planet has been saved" popup that they're 
    ###     going to need to re-display this screen to actually see votes.
    ###
    ###
    ### From here on, display votes pretty much the same way that the current 
    ### PropPane does now.


        #$self->szr_close_status->Add($self->lbl_close_status, 0, 0, 0);
        #$self->szr_close_status->AddSpacer(10);
        #$self->szr_close_status->Add($self->chk_close_status, 0, 0, 0);

        #$self->szr_props( $self->create_szr_props() );

        $self->content_sizer->Add($self->szr_header, 0, 0, 0);
        $self->content_sizer->Add($self->szr_embassy_planet, 0, 0, 0);
        #$self->content_sizer->Add($self->szr_close_status, 0, 0, 0);
        #$self->content_sizer->AddSpacer(20);
        #$self->content_sizer->Add($self->szr_props, 0, 0, 0);

        $self->_set_events();
        return $self;
    }
    sub _build_chc_embassy_planet {#{{{
        my $self = shift;

        my %planets_by_id = reverse %{wxTheApp->game_client->planets};
        my @sorted_planets = ( 'No Embassy', sort values %planets_by_id );

        ### Get the embassy planet from a previous run if available
        my $schema = wxTheApp->main_schema;
        my $emb_planet_rec = $schema->resultset('EmpirePrefsKeystore')->search({ 'name' => 'EmbassyPlanetID' })->single;
        if( $emb_planet_rec and my $pid = $emb_planet_rec->value ) {
            if( wxTheApp->game_client->planet_name($pid) ) {
                $self->planet_id( $pid );
                $self->planet_name( wxTheApp->game_client->planet_name($pid) );
            }
        }

        my $v = Wx::Choice->new(
            $self->parent, -1, 
            wxDefaultPosition, 
            Wx::Size->new(140, 30), 
            ['', @sorted_planets],
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        if( $self->planet_name ) {
            if( $self->validate_embassy_on_planet($self->planet_id) ) {
                $self->flg_embassy_planet_validated( 1 );
                $v->SetStringSelection( $self->planet_name );
            }
            else {
                wxTheApp->poperr("You used to have an embassy planet set, but there's no embassy on that planet anymore.\n\nChoose which planet your embassy is on now, please.");
                $self->planet_name(q{});
                $self->planet_id(0);
            }
        }
        return $v;
    }#}}}
    sub _build_chk_close_status {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Yes',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_parl {#{{{
        my $self = shift;
        my $parl = try {
            wxTheApp->game_client->get_building($self->planet_id, 'Parliament');
        }
        catch {
            #my $msg = (ref $_) ? $_->text : $_;
            my $msg = (ref $_) ? $_->message : $_;
            wxTheApp->poperr($msg);
            return;
        };

        return( $parl and ref $parl eq 'Games::Lacuna::Client::Buildings::Parliament' ) ? $parl : undef;
    }#}}}
    sub _build_props {#{{{
        my $self = shift;
        my $props = [];
        return $props unless $self->parl_exists_here;

        $props = try {
            my $rv = $self->parl->view_propositions();
            return $rv->{'propositions'} // $props;
        }
        catch {
            #my $msg = (ref $_) ? $_->text : $_;
            my $msg = (ref $_) ? $_->message : $_;
            wxTheApp->poperr($msg);
            return $props;
        };

        return $props;
    }#}}}
    sub _build_btn_embassy_planet {#{{{
        my $self = shift;
        my $v = Wx::Button->new(
            $self->parent, -1, 
            "Set Embassy Planet",
            wxDefaultPosition, 
            Wx::Size->new(140, 30)
        );
        return $v;
    }#}}}
    sub _build_lbl_close_status {#{{{
        my $self = shift;

        my $text = "Close the sitter status window automatically?";

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition, 
            Wx::Size->new(-1, -1)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_lbl_embassy_planet {#{{{
        my $self = shift;

        my $text = "Choose any planet with an embassy on it: ";

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition, 
            Wx::Size->new(-1, -1)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_lbl_instructions {#{{{
        my $self = shift;

        my $text = "    Mouse over a proposition's name to get its full description.  If nothing is listed below, there are simply no propositions active on this SS right now.
    If you click the 'Yes' button under 'Sitters:', a Yes vote will be recorded for every player for whom you have recorded a sitter password (provided that player is in your alliance).  See the Sitter Manager in the Tools menu to record sitters.
    There is not a 'No:' button under Sitters on purpose.  This is because I'm having a hard time envisioning a circumstance where you'd need to explicitly vote No for all of the people you have sitters for.  I think it's much more likely that such a button would get clicked by accident at some point.  And once a vote has been cast, it can't be changed.  So being able to vote No for all of your sitters just seems fraught with danger.  Yeah, I said 'fraught'.";

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition, 
            Wx::Size->new(-1, 190)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->Wrap(550);

        return $v;
    }#}}}
    sub _build_lbl_instructions_box {#{{{
        my $self = shift;
        my $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
        $sizer->Add($self->lbl_instructions, 0, 0, 0);
        return $sizer;
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "Proposition Voting", wxDefaultPosition, 
            Wx::Size->new(-1, 40)
        );
        $v->SetFont( wxTheApp->get_font('header_1') );
        return $v;
    }#}}}
    sub _build_planet_id {#{{{
        my $self = shift;
        return wxTheApp->game_client->planet_id( $self->planet_name );
    }#}}}
    sub _build_planet_name {#{{{
        my $self = shift;
        return wxTheApp->game_client->planet_name( $self->planet_id );
    }#}}}
    sub _build_szr_header {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Header');
    }#}}}
    sub _build_szr_embassy_planet {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Embassy Planet');
    }#}}}
    sub _build_szr_close_status {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Close Status Window?', 0);
    }#}}}
    sub _set_events {
        my $self = shift;
        EVT_BUTTON( $self->parent, $self->btn_embassy_planet->GetId, sub{$self->OnSaveEmbassyPlanet(@_)});
    }

    sub create_szr_props {#{{{
        my $self = shift;

        my $szr_props = wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Props');

        my $header = LacunaWaX::MainSplitterWindow::RightPane::NewPropositionsPane::PropRow->new(
            ancestor    => $self,
            parent      => $self->parent,
            planet_id   => $self->planet_id,
            is_header   => 1,
        );
        $szr_props->Add($header->main_sizer, 0, 0, 0);

        foreach my $prop( @{$self->props} ) {
            my $row = LacunaWaX::MainSplitterWindow::RightPane::NewPropositionsPane::PropRow->new(
                ancestor    => $self,
                parent      => $self->parent,
                planet_id   => $self->planet_id,
                parl        => $self->parl,
                prop        => $prop,
            );
            push @{$self->rows}, $row;
            $szr_props->Add( $row->main_sizer, 0, 0, 0 );
            $szr_props->AddSpacer( $self->row_spacer_size );
            wxTheApp->Yield;
        }

        $szr_props->AddSpacer( $self->row_spacer_size * 10 );

        if( @{ $self->rows } ) {
            my $footer = LacunaWaX::MainSplitterWindow::RightPane::NewPropositionsPane::PropRow->new(
                app         => wxTheApp,
                ancestor    => $self,
                parent      => $self->parent,
                planet_id   => $self->planet_id,
                rows        => $self->rows,
                is_footer   => 1,
            );
            $szr_props->Add($footer->main_sizer, 0, 0, 0);
        }

        return $szr_props;
    }#}}}
    sub parl_exists_here {#{{{
        my $self = shift;

        ### Calls parl's lazy builder if needed, which returns undef if no parl
        my $v = $self->parl;

        ### Yeah, we could just test if $v is undef.  Calling the auto-generated 
        ### has_parl() is just more Moosey.
        return unless $self->has_parl;
        return 1;
    };#}}}
    sub validate_embassy_on_planet {#{{{
        my $self = shift;
        my $pid  = shift;

        my $retval = try {
            my $emb = wxTheApp->game_client->get_building($pid, 'Embassy');
            $self->embassy( $emb );
        }
        catch {
            return;
        };

        return $retval;
    }#}}}

    sub OnClose {#{{{
        my $self    = shift;

        foreach my $row( @{$self->rows} ) {
            $row->OnClose if $row->can('OnClose');
        }
        return 1;
    }#}}}
    sub OnSaveEmbassyPlanet {#{{{
        my $self    = shift;
        my $dialog  = shift;    # Wx::ScrolledWindow
        my $event   = shift;    # CommandEvent

        my $pname = $self->chc_embassy_planet->GetStringSelection;
        my $pid   = wxTheApp->game_client->planet_id($pname);

        unless( $self->validate_embassy_on_planet($pid) ) {
            wxTheApp->poperr( "No embassy was found on your chosen planet!" );
            return;
        }

        $self->planet_id( $pid );
        $self->planet_name( $pname );

        my $schema = wxTheApp->main_schema;
        my $rec = $schema->resultset('EmpirePrefsKeystore')->find_or_create({
            name => 'EmbassyPlanetID',
        });
        $rec->value( $self->planet_id );
        $rec->update;

        wxTheApp->popmsg('Embassy planet saved');

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
