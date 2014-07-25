
### See CHECK for where I left off.

package LacunaWaX::MainSplitterWindow::RightPane::BuildShips {
    use v5.14;
    use Data::Dumper;
    use DateTime;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHECKBOX EVT_CHOICE EVT_CLOSE EVT_TIMER);
    with 'LacunaWaX::Roles::MainSplitterWindow::RightPane';

    has 'ancestor' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow::RightPane',
        required    => 1,
        documentation => q{
            this is one of the rare times we do need an ancestor; it's keeping track
            of whether we've got a build happening or not.
        }
    );

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
    );

    has 'planet_name' => (
        is          => 'rw',
        isa         => 'Str',
        required    => 1,
    );

    #########################################

    has 'all_shipyards' => (
        is          => 'rw',
        isa         => 'HashRef',
        lazy_build  => 1,
        documentation => q{
            All shipyards on the planet.
                building_id => hashref

            The hashref contains a key called 'object', which is the shipyard's full GLC object.
        }
    );

    ### These are for keeping track of a build queue once it starts.
    has 'build_complete_num' => (
        is          => 'rw',
        isa         => 'Int',
        default     => 0,
        lazy        => 1,
    );
    has 'build_max' => (
        is          => 'rw',
        isa         => 'Int',
        default     => 0,
        lazy        => 1,
    );
    has 'build_type' => (
        is          => 'rw',
        isa         => 'Str',
        default     => q{},
        lazy        => 1,
    );

    has 'buildable_ships' => (
        is          => 'rw',
        isa         => 'HashRef',
        clearer     => 'clear_buildable_ships',
        predicate   => 'has_buildable_ships',
        lazy        => 1,
        default     => sub{{}},
        documentation => q{#{{{
            Includes only ships we can build here.  This gets populated only after the user
            first choses a minumum shipyard level.

            eg:
            'snark2' => {
            'type' => 'snark3',
            'type_human' => 'Snark II',
            'attributes' => {
                'speed' => '4510',
                'stealth' => '11726',
                'max_occupants' => 0,
                'combat' => '18880',
                'berth_level' => 1,
                'hold_size' => '0'
            },
            'tags' => [
                'War'
            ],
            'can' => 1,
            'cost' => {
                'seconds' => '78',
                'energy' => '502460',
                'ore' => '653276',
                'food' => '95830',
                'waste' => '220150',
                'water' => '167314'
            },
            'reason' => ''
            },
        }#}}}
    );

    has 'docks_available' => (
        is          => 'rw',
        isa         => 'Int',
        default     => 0,
        lazy        => 1,
    );

    has 'max_w' => (
        is          => 'rw',
        isa         => 'Int',
        default     => 600,
        documentation => q{
            max width for various controls.
        }
    );

    has 'planet_id' => (
        is          => 'rw',
        isa         => 'Int',
        lazy_build  => 1,
    );

    has 'spaceport' => (
        is          => 'rw',
        isa         => 'Games::Lacuna::Client::Buildings::SpacePort',
        lazy_build  => 1,
    );

    has 'tags' => (
        is          => 'rw',
        isa         => 'ArrayRef[Str]',
        lazy        => 1,
        default     => sub{ [] },
        documentation => q{
            Contains any tags the user wants to filter the ships list by.  Starts out
            containing all tags; user can filter by un-checking checkboxen.
        }
    );

    has 'timer' => (
        is          => 'rw', 
        isa         => 'Wx::Timer',
        lazy_build  => 1,
        handles => {
            start_ticking => 'Start',
            stop_ticking  => 'Stop',
        }
    );

    has 'usable_shipyards' => (
        is          => 'rw',
        isa         => 'HashRef',
        clearer     => 'clear_usable_shipyards',
        lazy        => 1,
        default     => sub {{}},
        documentation => q{
            A subset of 'all_shipyards'.  This is set after the user choses a 
            minimum level; the shipyards here will not include those yards lower 
            than the chosen minimum level.
        }
    );

    has 'btn_build'             => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1);
    has 'chc_min_level'         => (is => 'rw', isa => 'Wx::Choice',        lazy_build => 1);
    has 'chc_shiptype'          => (is => 'rw', isa => 'Wx::Choice',        lazy_build => 1);
    has 'chk_tag_colonization'  => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'chk_tag_exploration'   => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'chk_tag_intelligence'  => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'chk_tag_mining'        => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'chk_tag_trade'         => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'chk_tag_war'           => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'lbl_header'            => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_instructions'      => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_min_level'         => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_num_to_build'      => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_shiptype'          => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_summary'           => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'spn_num_to_build'      => (is => 'rw', isa => 'Wx::SpinCtrl',      lazy_build => 1);
    has 'szr_build_button'      => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_header'            => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_instructions'      => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_min_level'         => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_num_to_build'      => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_shiptype'          => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_summary'           => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_tags'              => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);

    sub BUILD {
        my $self = shift;
    
        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers
        #wxTheApp->borders_on();    # Change to borders_on to see borders around sizers

        $self->szr_instructions->Add($self->lbl_instructions, 0, 0, 0);
        if( $self->ancestor_has_build ) {
            $self->update_instructions_for_build;
        }

        $self->szr_header->Add($self->lbl_header, 0, 0, 0);
        $self->szr_header->AddSpacer(10);
        $self->szr_header->Add($self->szr_instructions, 0, 0, 0);
        $self->szr_header->AddSpacer(10);

        $self->lbl_summary->Show(0);    # it'll become viewable after the user choses a level
        $self->szr_summary->Add($self->lbl_summary, 0, 0, 0);

        my $checkbox_spacer = 10;
        $self->szr_tags->Add($self->chk_tag_colonization, 0, 0, 0);
        $self->szr_tags->AddSpacer($checkbox_spacer);
        $self->szr_tags->Add($self->chk_tag_exploration, 0, 0, 0);
        $self->szr_tags->AddSpacer($checkbox_spacer);
        $self->szr_tags->Add($self->chk_tag_intelligence, 0, 0, 0);
        $self->szr_tags->AddSpacer($checkbox_spacer);
        $self->szr_tags->Add($self->chk_tag_mining, 0, 0, 0);
        $self->szr_tags->AddSpacer($checkbox_spacer);
        $self->szr_tags->Add($self->chk_tag_trade, 0, 0, 0);
        $self->szr_tags->AddSpacer($checkbox_spacer);
        $self->szr_tags->Add($self->chk_tag_war, 0, 0, 0);

        $self->szr_min_level->Add($self->lbl_min_level, 0, 0, 0);
        $self->szr_min_level->Add($self->chc_min_level, 0, 0, 0);

        $self->szr_shiptype->Add($self->lbl_shiptype, 0, 0, 0);
        $self->szr_shiptype->Add($self->chc_shiptype, 0, 0, 0);

        $self->szr_num_to_build->Add($self->lbl_num_to_build, 0, 0, 0);
        $self->szr_num_to_build->Add($self->spn_num_to_build, 0, 0, 0);

        $self->szr_build_button->Add($self->btn_build, 0, 0, 0);

        $self->content_sizer->AddSpacer(4);    # a little top margin
        $self->content_sizer->Add($self->szr_header, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_summary, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_min_level, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_tags, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_shiptype, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_num_to_build, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_build_button, 0, 0, 0);

        $self->_set_events();
        return $self;
    };
    sub _build_all_shipyards {#{{{
        my $self = shift;

=pod

{
 integer id => {
    'x' => '4',
    'url' => '/shipyard',
    'level' => '30',
    'id' => '2111705',
    'efficiency' => '100',
    'image' => 'shipyard9',
    'y' => '-5',
    'name' => 'Shipyard'

    'object' => Games::Lacuna::Client::Buildings::Shipyard object
 },
 ...repeat for rest of shipyards...
}

=cut

        my $yards = wxTheApp->game_client->get_buildings( $self->planet_id, 'Shipyard' );

        foreach my $id( keys %$yards ) {
            my $hr = $yards->{$id};
            $yards->{$id}{'object'} = wxTheApp->game_client->get_building_object( $self->planet_id, $hr );
        }

        return $yards;
    }#}}}
    sub _build_btn_build {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->parent, -1, "Build!");
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->Enable(0);
        return $v;
    }#}}}
    sub _build_chc_min_level {#{{{
        my $self = shift;

        my $v = Wx::Choice->new(
            $self->parent, -1, 
            wxDefaultPosition, 
            Wx::Size->new(50, 25), 
            ["Choose a level", 0..30],
            ### If you change that text from "Choose a level" to something 
            ### else, fix the conditional in OnChooseLevel as well.
        );
        $v->SetStringSelection('0');
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        if( $self->ancestor_has_build ) {
            $v->Enable(0);
        }

        return $v;
    }#}}}
    sub _build_chc_shiptype {#{{{
        my $self = shift;

        my $v = Wx::Choice->new(
            $self->parent, -1, 
            wxDefaultPosition, 
            Wx::Size->new(200, 25), 
            [],
        );
        $v->Enable(0);
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_chk_tag_colonization {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Colonization',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( 1 );
        $v->Enable(0);

        return $v;
    }#}}}
    sub _build_chk_tag_exploration {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Exploration',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( 1 );
        $v->Enable(0);

        return $v;
    }#}}}
    sub _build_chk_tag_intelligence {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Intelligence',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( 1 );
        $v->Enable(0);

        return $v;
    }#}}}
    sub _build_chk_tag_mining {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Mining',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( 1 );
        $v->Enable(0);

        return $v;
    }#}}}
    sub _build_chk_tag_trade {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Trade',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( 1 );
        $v->Enable(0);

        return $v;
    }#}}}
    sub _build_chk_tag_war {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'War',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( 1 );
        $v->Enable(0);

        return $v;
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;
        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            "Ship Builder",
            wxDefaultPosition, 
            Wx::Size->new(600, 35)
        );
        $y->SetFont( wxTheApp->get_font('header_1') );
        return $y;
    }#}}}
    sub _build_lbl_instructions {#{{{
        my $self = shift;

        my $text = "This is where we build ships.";
        my $size = Wx::Size->new(-1, -1);

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition, $size
        );
        $y->Wrap( $self->parent->GetSize->GetWidth - 100 ); # Subtract to account for the vertical scrollbar
        $y->SetFont( wxTheApp->get_font('para_text_1') );

        return $y;
    }#}}}
    sub _build_lbl_min_level {#{{{
        my $self = shift;

        my $text = "Minimum level spaceport at which to build ships:";

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition,
            Wx::Size->new(270, 25),
        );
        #$y->Wrap( $self->parent->GetSize->GetWidth - 100 ); # Subtract to account for the vertical scrollbar
        $y->SetFont( wxTheApp->get_font('para_text_1') );

        return $y;
    }#}}}
    sub _build_lbl_num_to_build {#{{{
        my $self = shift;

        my $text = "Total number of ships to build:";

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition,
            Wx::Size->new(170, 25),
        );
        $y->SetFont( wxTheApp->get_font('para_text_1') );

        return $y;
    }#}}}
    sub _build_lbl_shiptype {#{{{
        my $self = shift;

        my $text = "Type of ship to build:";

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition,
            Wx::Size->new(120, 25),
        );
        $y->SetFont( wxTheApp->get_font('para_text_1') );

        return $y;
    }#}}}
    sub _build_lbl_summary {#{{{
        my $self = shift;

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            q{},
            wxDefaultPosition,
            Wx::Size->new(10, 10),
            wxEXPAND,
        );
        $y->SetMaxSize( Wx::Size->new($self->max_w, -1) );  # 130
        $y->SetFont( wxTheApp->get_font('modern_text_3') );

        return $y;
    }#}}}
    sub _build_planet_id {#{{{
        my $self = shift;
        return wxTheApp->game_client->planet_id( $self->planet_name );
    }#}}}
    sub _build_spaceport {#{{{
        my $self = shift;
        my $bldg = wxTheApp->game_client->get_building( $self->planet_id, 'Space Port' );
        return $bldg;
    }#}}}
    sub _build_spn_num_to_build {#{{{
        my $self = shift;
        my $v = Wx::SpinCtrl->new(
            $self->parent, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(50, 25), 
            wxSP_ARROW_KEYS, 
            0, 5000, 0
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->Enable(0);
        return $v;
    }#}}}
    sub _build_szr_build_button {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Build Button');
        return $v;
    }#}}}
    sub _build_szr_header {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Header Sizer');
        return $v;
    }#}}}
    sub _build_szr_instructions {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Instructions');
        return $v;
    }#}}}
    sub _build_szr_min_level {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Min Level');
        return $v;
    }#}}}
    sub _build_szr_num_to_build {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Num to build');
        return $v;
    }#}}}
    sub _build_szr_shiptype {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Ship Type');
        return $v;
    }#}}}
    sub _build_szr_summary {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Docks/Ships Summary');
        return $v;
    }#}}}
    sub _build_szr_tags {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Tags');
        return $v;
    }#}}}
    sub _build_timer {#{{{
        my $self = shift;
        my $t = Wx::Timer->new();
        $t->SetOwner( $self->parent );
        return $t;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON(     $self->parent, $self->btn_build->GetId,             sub{$self->OnBuild(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_colonization->GetId,  sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_exploration->GetId,   sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_intelligence->GetId,  sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_mining->GetId,        sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_trade->GetId,         sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_war->GetId,           sub{$self->OnTagCheck(@_)} );
        EVT_CHOICE(     $self->parent, $self->chc_min_level->GetId,         sub{$self->OnChooseLevel(@_)} );
        EVT_TIMER(      $self->parent, $self->timer->GetId,                 sub{$self->OnBuildTimer(@_)} );
        return 1;
    }#}}}

    sub add_build_on_ancestor {#{{{
        my $self = shift;
        $self->ancestor->ship_builds->{ $self->planet_name } = 1;
    }#}}}
    sub end_build_on_ancestor {#{{{
        my $self = shift;
        $self->ancestor->ship_builds->{ $self->planet_name } = 0;
    }#}}}
    sub ancestor_has_build {#{{{
        my $self = shift;
        return $self->ancestor->ship_builds->{ $self->planet_name } // 0;
    }#}}}
    sub assign_shiptypes {#{{{
        my $self = shift;

        ### Fills the chc_shiptype with ships we can actually build on this 
        ### planet.
        ### Called after the user first choses a minimum shipyard level.

        ### Create hashref of currently 'on' (user-chosen) tags
        my $tags_hr = {};
        grep{ $tags_hr->{$_} = 1 }$self->get_tags;

        $self->chc_shiptype->Clear();
        foreach my $type( sort keys %{$self->buildable_ships} ) {
            wxTheApp->Yield();
            my $hr = $self->buildable_ships->{$type};
            my $tags_match = grep( $tags_hr->{$_}, @{$hr->{'tags'}} );
            $self->chc_shiptype->Append( $hr->{'type_human'}, $hr ) if $tags_match;
        };
        $self->chc_shiptype->Update;
        $self->enable_all();

        return 1;
    }#}}}
    sub enable_all {#{{{
        my $self = shift;

        $self->chc_shiptype->Enable(1);
        $self->spn_num_to_build->Enable(1);
        $self->chk_tag_colonization->Enable(1);
        $self->chk_tag_exploration->Enable(1);
        $self->chk_tag_intelligence->Enable(1);
        $self->chk_tag_mining->Enable(1);
        $self->chk_tag_trade->Enable(1);
        $self->chk_tag_war->Enable(1);
        $self->btn_build->Enable(1);
        return 1;
    }#}}}
    sub disable_all {#{{{
        my $self = shift;

        $self->chc_shiptype->Enable(0);
        $self->spn_num_to_build->Enable(0);
        $self->chk_tag_colonization->Enable(0);
        $self->chk_tag_exploration->Enable(0);
        $self->chk_tag_intelligence->Enable(0);
        $self->chk_tag_mining->Enable(0);
        $self->chk_tag_trade->Enable(0);
        $self->chk_tag_war->Enable(0);
        $self->btn_build->Enable(0);
        return 1;
    }#}}}
    sub get_tags {#{{{
        my $self = shift;

        my @tags = ();
        foreach my $tag( qw(colonization exploration intelligence mining trade war) ) {
            my $box = "chk_tag_" . $tag;
            if( $self->$box->IsChecked ) {
                push @tags, ucfirst $tag;
            }
        }

        return @tags;
    }#}}}
    sub set_summary_text {#{{{
        my $self = shift;

        my $text = 'You appear not to have any shipyards on this planet.';

        my($id, $hr) = each %{$self->all_shipyards};
        values %{$self->all_shipyards}; # reset the iterator
        if( $id ) {
            my $v = $self->spaceport->view();

            $self->docks_available( $v->{'docks_available'} );

            $text = "Docks: $v->{'docks_available'} available of $v->{'max_ships'} total.\n\nCurrent Ships\n=============\n";
            foreach my $shiptype( sort keys %{$v->{'docked_ships'}} ) {
                my $show_shiptype = $shiptype . q{ };
                my $dots = '.' x(30 - (length($show_shiptype)));
                $show_shiptype .= $dots;
                $text .= sprintf("%-30s %05d\n", $show_shiptype, $v->{'docked_ships'}{$shiptype});
            }
        }

        $self->lbl_summary->SetLabel($text);
        $self->wrap_summary;
        $self->szr_summary->SetItemMinSize( $self->lbl_summary, $self->max_w, -1 ); # 130

        return 1;
    }#}}}
    sub update_instructions_for_build {#{{{
        my $self = shift;
        $self->lbl_instructions->SetLabel("BUILD PROCESS WORKING RIGHT NOW");
        $self->lbl_instructions->SetForegroundColour( Wx::Colour->new(255, 0, 0) );
    }#}}}
    sub update_instructions_for_build_end {#{{{
        my $self = shift;
        ### CHECK - need to variableize the label string.
        $self->lbl_instructions->SetLabel("This is where we build shipss.");
        $self->lbl_instructions->SetForegroundColour( Wx::Colour->new(0, 0, 0) );
    }#}}}
    sub wrap_summary {#{{{
        my $self = shift;
        $self->lbl_summary->Wrap($self->max_w);
    }#}}}

    sub OnBuild {#{{{
        my $self        = shift;
        my $dialog      = shift;    # Wx::ScrolledWindow
        my $event       = shift;    # Wx::CommandEvent

        my $data = $self->chc_shiptype->GetClientData( $self->chc_shiptype->GetSelection );
        unless( ref $data eq 'HASH' ) {
            wxTheApp->poperr(
                "Please chose a ship type to build.",
                "No type selected"
            );
            return;
        }

        my $num = $self->spn_num_to_build->GetValue;
        my $num_msg = q{};
        if( not $num ) {
            $num_msg = "Please indicate how many ships to build.",
        }
        elsif( $num > $self->docks_available ) {
            $num_msg = "You're trying to build $num ships but have only " . $self->docks_available . " docks open - you'll have to try building fewer ships.",
        }
        if( $num_msg ) {
            wxTheApp->poperr( $num_msg, "Incorrect ship number" );
            return;
        }

        $self->update_instructions_for_build;
        $self->add_build_on_ancestor();
        $self->build_type(  $data->{'type'} );
        $self->build_max(   $num            );

        ### Set the timer for 10ms to start our first batch of builds.
        $self->timer->Start( 10, wxTIMER_ONE_SHOT );

        return 1;
    }#}}}
    sub OnBuildTimer {#{{{
        my $self = shift;
        my $bar  = shift;   # Wx::StatusBar
        my $evt  = shift;   # Wx::TimerEvent


        my $orig_alarm_seconds = my $alarm_seconds = 99999999999999;
        SHIPYARD:
        foreach my $sy_id( keys %{$self->usable_shipyards} ) {
            my $hr  = $self->usable_shipyards->{$sy_id};
            my $sy  = $hr->{'object'};

            ### Make sure this sy isn't already at work.
            my $queue = $sy->view_build_queue();
            next SHIPYARD if( $queue->{'number_of_ships_building'} );

            ### How many to queue up at this SY this time around?
            my $num_to_build = $hr->{'level'};
            my $left_to_build = $self->build_max - $self->build_complete_num;
            $num_to_build = $left_to_build if $num_to_build > $left_to_build;
$num_to_build = 1;
            if( not $num_to_build or $num_to_build > $self->docks_available ) {
                $self->end_build_on_ancestor();
                $self->chc_min_level->Enable(1);
                $self->update_instructions_for_build_end();
                return;
            }

            ### Add to queue, update counts.
            my $rv = $sy->build_ship( $self->build_type, $num_to_build );
            $self->build_complete_num( $self->build_complete_num + $num_to_build );
            $self->docks_available( $self->docks_available - $num_to_build );

            my $seconds     = $rv->{'building'}{'work'}{'seconds_remaining'};
            $alarm_seconds  = $seconds if $seconds < $alarm_seconds;
say "-$seconds- -$alarm_seconds-";
        }

        ### All shipyards were busy, so we're not going to do anything.
        if( $alarm_seconds == $orig_alarm_seconds ) {
            return;
        }

        if( $self->build_complete_num < $self->build_max ) {
say "-" . $self->build_complete_num . "-";
say "-" . $self->build_max . "-";

            my $ms = ($alarm_seconds + 5) * 1000;    # 5 buffer seconds
            $self->timer->Start( $ms, wxTIMER_ONE_SHOT );
        }
        else {
            ### We're done.
say "Done, at end.";
    ### CHECK
    ### some part of this is segfaulting, not sure which yet.
            $self->end_build_on_ancestor();
            $self->update_instructions_for_build_end();
            $self->chc_min_level->Enable(1);
        }

        return 1;
    }#}}}
    sub OnChooseLevel {#{{{
        my $self    = shift;
        my $dialog  = shift;    # Wx::ScrolledWindow
        my $event   = shift;    # Wx::CommandEvent

        ### This starts out as the only labeled control.  When the user choses 
        ### a level, we go out and gather all the data needed to populate the 
        ### other controls.
        ### This way, the pane itself can show up quickly.  After chosing a 
        ### level, the user has to wait for everything to complete, but 
        ### they're expecting a bit of a wait after the action of making that 
        ### choice, which is better than making them wait for the pane to show 
        ### up at all.

        $self->set_summary_text();

        my $reqd_level = $self->chc_min_level->GetStringSelection;
        return if $reqd_level =~ /Choose a level/;

        wxTheApp->throb();
        
        ### Keep just the yards matching the user's requirement.
        $self->clear_usable_shipyards();
        wxTheApp->Yield();
        foreach my $id( keys %{$self->all_shipyards} ) {
            wxTheApp->Yield();
            my $yard_hash = $self->all_shipyards->{$id};
            if( $yard_hash->{'level'} >= $reqd_level ) {
                $self->usable_shipyards->{$id} = $yard_hash;
            }
        }

        ### There's no need to ever re-calc this after the first time; no ship 
        ### depends on the shipyard being a certain level, so if the user 
        ### first choses 30, then backs off to 1, the buildable ships list 
        ### won't change.
        unless( $self->has_buildable_ships ) {
            wxTheApp->Yield();
            my( $id, $hashref ) = each %{$self->usable_shipyards};
            my $sy = wxTheApp->game_client->get_building_object( $self->planet_id, $hashref );
            my $rv = $sy->get_buildable;
            foreach my $type( keys %{$rv->{'buildable'}} ) {
                wxTheApp->Yield();
                my $hr = $rv->{'buildable'}{$type};
                $hr->{'type'} = $type;
                $self->buildable_ships->{$type} = $hr if $hr->{'can'};
            }
            $self->assign_shiptypes();
        }

        ### Now that everything's recalced, be sure the summary text is shown.  
        ### The first time the user choses a level, it won't be yet.
        $self->lbl_summary->Show(1);

        wxTheApp->endthrob();
        return 1;
    }#}}}
    sub OnTagCheck {#{{{
        my $self        = shift;
        my $dialog      = shift;    # Wx::ScrolledWindow
        my $event       = shift;    # Wx::CommandEvent

        $self->assign_shiptypes();

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
