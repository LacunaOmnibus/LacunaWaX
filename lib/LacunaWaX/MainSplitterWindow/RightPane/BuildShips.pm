
### This doesn't actually build anything yet, and the layout is fugly, but 
### what's there works.

package LacunaWaX::MainSplitterWindow::RightPane::BuildShips {
    use v5.14;
    use Data::Dumper;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHECKBOX EVT_CHOICE EVT_CLOSE);
    with 'LacunaWaX::Roles::MainSplitterWindow::RightPane';

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
        }
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

    has 'planet_id' => (
        is          => 'rw',
        isa         => 'Int',
        lazy_build  => 1,
    );

    has 'tags' => (
        is          => 'rw',
        isa         => 'ArrayRef',
        lazy        => 1,
        default     => sub{ [] },
        documentation => q{
            Contains the strings of any tags the user wants to filter the ships list by.
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
    has 'spn_num_to_build'      => (is => 'rw', isa => 'Wx::SpinCtrl',      lazy_build => 1);
    has 'szr_header'            => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => 'vertical'    );
    has 'szr_instructions'      => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1                                 );
    has 'szr_min_level'         => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1                                 );
    has 'szr_num_to_build'      => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1                                 );
    has 'szr_shiptype'          => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1                                 );
    has 'szr_tags'              => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1                                 );

    sub BUILD {
        my $self = shift;
    
        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->szr_instructions->Add($self->lbl_instructions, 0, 0, 0);
        $self->szr_header->Add($self->lbl_header, 0, 0, 0);
        $self->szr_header->AddSpacer(10);
        $self->szr_header->Add($self->szr_instructions, 0, 0, 0);
        $self->szr_header->AddSpacer(10);

        my $tag_space = 10;
        $self->szr_tags->Add($self->chk_tag_colonization, 0, 0, 0);
        $self->szr_tags->AddSpacer($tag_space);
        $self->szr_tags->Add($self->chk_tag_exploration, 0, 0, 0);
        $self->szr_tags->AddSpacer($tag_space);
        $self->szr_tags->Add($self->chk_tag_intelligence, 0, 0, 0);
        $self->szr_tags->AddSpacer($tag_space);
        $self->szr_tags->Add($self->chk_tag_mining, 0, 0, 0);
        $self->szr_tags->AddSpacer($tag_space);
        $self->szr_tags->Add($self->chk_tag_trade, 0, 0, 0);
        $self->szr_tags->AddSpacer($tag_space);
        $self->szr_tags->Add($self->chk_tag_war, 0, 0, 0);

        $self->szr_min_level->Add($self->lbl_min_level, 0, 0, 0);
        $self->szr_min_level->Add($self->chc_min_level, 0, 0, 0);

        $self->szr_shiptype->Add($self->lbl_shiptype, 0, 0, 0);
        $self->szr_shiptype->Add($self->chc_shiptype, 0, 0, 0);

        $self->szr_num_to_build->Add($self->lbl_num_to_build, 0, 0, 0);
        $self->szr_num_to_build->Add($self->spn_num_to_build, 0, 0, 0);

        $self->content_sizer->AddSpacer(4);    # a little top margin
        $self->content_sizer->Add($self->szr_header, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_min_level, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_tags, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_shiptype, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_num_to_build, 0, 0, 0);

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
 },
 ...repeat for rest of shipyards...
}

=cut

        my $yards = wxTheApp->game_client->get_buildings( $self->planet_id, 'Shipyard' );
        return $yards;
    }#}}}
    sub _build_chc_min_level {#{{{
        my $self = shift;

        my $v = Wx::Choice->new(
            $self->parent, -1, 
            wxDefaultPosition, 
            Wx::Size->new(50, 25), 
            ["Choose a level", 0..30],
        );
        $v->SetStringSelection('0');
        $v->SetFont( wxTheApp->get_font('para_text_1') );
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
    sub _build_planet_id {#{{{
        my $self = shift;
        return wxTheApp->game_client->planet_id( $self->planet_name );
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
    sub _build_szr_tags {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Tags');
        return $v;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CHOICE(     $self->parent, $self->chc_min_level->GetId,         sub{$self->OnChooseLevel(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_colonization->GetId,  sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_exploration->GetId,   sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_intelligence->GetId,  sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_mining->GetId,        sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_trade->GetId,         sub{$self->OnTagCheck(@_)} );
        EVT_CHECKBOX(   $self->parent, $self->chk_tag_war->GetId,           sub{$self->OnTagCheck(@_)} );
        return 1;
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
        foreach my $name( sort keys %{$self->buildable_ships} ) {
            my $hr = $self->buildable_ships->{$name};
            my $tags_match = grep( $tags_hr->{$_}, @{$hr->{'tags'}} );
            $self->chc_shiptype->Append( $hr->{'type_human'}, $hr ) if $tags_match;
        };
        $self->chc_shiptype->Update;

        $self->chc_shiptype->Enable(1);
        $self->spn_num_to_build->Enable(1);
        $self->chk_tag_colonization->Enable(1);
        $self->chk_tag_exploration->Enable(1);
        $self->chk_tag_intelligence->Enable(1);
        $self->chk_tag_mining->Enable(1);
        $self->chk_tag_trade->Enable(1);
        $self->chk_tag_war->Enable(1);

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

    sub OnChooseLevel {#{{{
        my $self    = shift;
        my $dialog  = shift;    # Wx::ScrolledWindow
        my $event   = shift;    # Wx::CommandEvent

        my $reqd_level = $self->chc_min_level->GetStringSelection;
        return if $reqd_level =~ /Choose a level/;
        
        ### Keep just the yards matching the user's requirement.
        $self->clear_usable_shipyards();
        foreach my $id( keys %{$self->all_shipyards} ) {
            my $y = $self->all_shipyards->{$id};
            if( $y->{'level'} >= $reqd_level ) {
                $self->usable_shipyards->{$id} = $y;
            }
        }

        ### There's no need to ever re-calc this after the first time; no ship 
        ### depends on the shipyard being a certain level, so if the user 
        ### first choses 30, then backs off to 1, the buildable ships list 
        ### won't change.
        ### We're only doing it here because it requires a request.  So doing 
        ### it in BUILD would cause the entire pane load to slow down.  Doing 
        ### it here, in response to the user chosing something from the 
        ### CHOICE, will make more sense to the user.
        unless( $self->has_buildable_ships ) {
            my( $id, $hashref ) = each %{$self->usable_shipyards};
            my $sy = wxTheApp->game_client->get_building_object( $self->planet_id, $hashref );
            my $rv = $sy->get_buildable;
            foreach my $name( keys %{$rv->{'buildable'}} ) {
                my $hr = $rv->{'buildable'}{$name};
                $self->buildable_ships->{$name} = $hr if $hr->{'can'};
            }
            $self->assign_shiptypes();
        }

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
