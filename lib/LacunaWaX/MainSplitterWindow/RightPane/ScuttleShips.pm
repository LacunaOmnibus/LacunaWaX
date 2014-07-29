
package LacunaWaX::MainSplitterWindow::RightPane::ScuttleShips {
    use v5.14;
    use Data::Dumper;
    use DateTime;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHECKBOX EVT_CHOICE EVT_CLOSE EVT_TIMER);
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

    has 'docks_available' => (
        is          => 'rw',
        isa         => 'Int',
        default     => 0,
        lazy        => 1,
        documentation => q{
            Number of docks available on the planet right now.  Updated as ships
            are added to the queue.
            CAUTION - If the user goes and scuttles ships, or manually adds 
            ships to the queue, or does anything else ship-count-related 
            through another interface, this count will be off.
        }
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
        documentation => q{
            One of the spaceports on the planet.  Doesn't matter which one.
        }
    );


    has 'btn_scuttle'           => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1);
    has 'chc_scuttle'           => (is => 'rw', isa => 'Wx::Choice',        lazy_build => 1);
    has 'lbl_header'            => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_instructions'      => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_shiptype'          => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_scuttle'           => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_summary'           => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'spn_scuttle'           => (is => 'rw', isa => 'Wx::SpinCtrl',      lazy_build => 1);
    has 'szr_header'            => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_instructions'      => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_scuttle'           => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);
    has 'szr_summary'           => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1);

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->szr_instructions->Add($self->lbl_instructions, 0, 0, 0);

        $self->szr_header->Add($self->lbl_header, 0, 0, 0);
        $self->szr_header->AddSpacer(10);
        $self->szr_header->Add($self->szr_instructions, 0, 0, 0);
        $self->szr_header->AddSpacer(10);

        $self->szr_summary->Add($self->lbl_summary, 0, 0, 0);

        $self->szr_scuttle->Add($self->lbl_scuttle, 0, 0, 0);
        $self->szr_scuttle->AddSpacer(10);
        $self->szr_scuttle->Add($self->chc_scuttle, 0, 0, 0);
        $self->szr_scuttle->AddSpacer(10);
        $self->szr_scuttle->Add($self->spn_scuttle, 0, 0, 0);
        $self->szr_scuttle->AddSpacer(10);
        $self->szr_scuttle->Add($self->btn_scuttle, 0, 0, 0);

        $self->content_sizer->AddSpacer(4);    # a little top margin
        $self->content_sizer->Add($self->szr_header, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->szr_summary, 0, 0, 0);
        $self->content_sizer->AddSpacer(5);
        $self->content_sizer->Add($self->szr_scuttle, 0, 0, 0);

        $self->assign_shiptypes;

        $self->_set_events();
        return $self;
    };
    sub _build_btn_scuttle {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->parent, -1, "Scuttle Selected Ships");
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->Enable(1);
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
    sub _build_chc_scuttle {#{{{
        my $self = shift;

        my $v = Wx::Choice->new(
            $self->parent, -1, 
            wxDefaultPosition, 
            Wx::Size->new(200, 25), 
            [],
        );
        $v->Enable(1);
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;
        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            "Ship Scuttler",
            wxDefaultPosition, 
            Wx::Size->new(600, 35)
        );
        $y->SetFont( wxTheApp->get_font('header_1') );
        return $y;
    }#}}}
    sub _build_lbl_instructions {#{{{
        my $self = shift;

        my $text = "Scuttle unneeded ships.  Ships with lower stats will automatically be scuttled before ships with higher stats.";

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition,
            Wx::Size->new($self->max_w, -1),
        );
        $y->Wrap( $self->max_w );
        $y->SetFont( wxTheApp->get_font('para_text_1') );

        return $y;
    }#}}}
    sub _build_lbl_shiptype {#{{{
        my $self = shift;

        my $text = "Shiptype to scuttle:";

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition,
            Wx::Size->new($self->max_w, -1),
        );
        $y->SetFont( wxTheApp->get_font('para_text_1') );

        return $y;
    }#}}}
    sub _build_lbl_scuttle {#{{{
        my $self = shift;

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            q{Ships to scuttle},
            wxDefaultPosition,
            Wx::Size->new(-1, -1),
            wxEXPAND,
        );
        $y->SetFont( wxTheApp->get_font('para_text_1') );

        return $y;
    }#}}}
    sub _build_lbl_summary {#{{{
        my $self = shift;

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            q{Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.},
            wxDefaultPosition,
            Wx::Size->new(-1, -1),
            wxEXPAND,
        );
        $y->SetMaxSize( Wx::Size->new($self->max_w, -1) ); 
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
    sub _build_spn_scuttle {#{{{
        my $self = shift;
        my $v = Wx::SpinCtrl->new(
            $self->parent, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(50, 25), 
            wxSP_ARROW_KEYS, 
            0, 5000, 0
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->Enable(1);
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
    sub _build_szr_scuttle {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Scuttle');
        return $v;
    }#}}}
    sub _build_szr_summary {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Summary');
        return $v;
    }#}}}
    sub _build_szr_update_btn {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Update Button');
        return $v;
    }#}}}
    sub _set_events {
        my $self = shift;
        EVT_BUTTON( $self->parent, $self->btn_scuttle->GetId,   sub{$self->OnScuttle(@_)} );
        return 1;
    }

    sub assign_shiptypes {#{{{
        my $self = shift;

        ### Fills both the summary and the dropdown with scuttle-able ships.

        my $summary_text = 'You appear not to have any shipyards on this planet.';

        #my $v = $self->spaceport->view();
        my $v = wxTheApp->game_client->get_spaceport_view( $self->planet_name, $self->spaceport );
        foreach my $shiptype( sort keys %{$v->{'docked_ships'}} ) {
            wxTheApp->Yield();

            $self->chc_scuttle->Append( $shiptype );

            $summary_text = "Docks: $v->{'docks_available'} available of $v->{'max_ships'} total.\n\nCurrent Ships\n=============\n";
            foreach my $shiptype( sort keys %{$v->{'docked_ships'}} ) {
                wxTheApp->Yield();
                my $show_shiptype = $shiptype . q{ };
                my $dots = '.' x(30 - (length($show_shiptype)));
                $show_shiptype .= $dots;
                $summary_text .= sprintf("%-30s %05d\n", $show_shiptype, $v->{'docked_ships'}{$shiptype});
            }
        }

        wxTheApp->Yield();
        $self->lbl_summary->SetLabel($summary_text);
        $self->wrap_summary;
        $self->szr_summary->SetItemMinSize( $self->lbl_summary, $self->max_w, -1 );

        return 1;
    }#}}}
    sub wrap_summary {#{{{
        my $self = shift;
        $self->lbl_summary->Wrap($self->max_w);
    }#}}}

    sub OnScuttle {#{{{
        my $self        = shift;
        my $dialog      = shift;    # Wx::ScrolledWindow
        my $event       = shift;    # Wx::CommandEvent

        my $shiptype    = $self->chc_scuttle->GetStringSelection();
        my $num         = $self->spn_scuttle->GetValue;

        if( not $shiptype or not $num ) {
            wxTheApp->poperr("You must specify a shiptype and a number to scuttle");
            return;
        }

        unless( wxTheApp->popconf("Scuttle $num of $shiptype - are you sure?") == wxYES ) {
            wxTheApp->popmsg("OK, bailing out!");
            return;
        }

        wxTheApp->throb();

        my $paging          = {page_number => 1, items_per_page => $num};
        my $filter          = {type => $shiptype, task => 'Docked'};
        my $v               = $self->spaceport->view_all_ships( $paging, $filter );
        wxTheApp->Yield();

        my $scuttle_these_ids = [ map{ 
            wxTheApp->Yield();
            $_->{'id'} 
        }
        sort {
               $a->{'combat'}           <=> $b->{'combat'}
            || $a->{'speed'}            <=> $b->{'speed'}
            || $a->{'stealth'}          <=> $b->{'stealth'}
            || $a->{'hold_size'}        <=> $b->{'hold_size'}
            || $a->{'max_occupants'}    <=> $b->{'max_occupants'}

        }@{$v->{'ships'}} ];
        wxTheApp->Yield();

        $self->spaceport->mass_scuttle_ship( $scuttle_these_ids );
        wxTheApp->game_client->clear_spaceport_view_cache();
        wxTheApp->Yield();

        $self->assign_shiptypes;
        wxTheApp->Yield();

        wxTheApp->endthrob();

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
