
=pod

The $text being displayed here is a single StaticText label, and it's a big ugly 
unweildy schmear and should be refactored.

=cut

package LacunaWaX::MainSplitterWindow::RightPane::SummaryPane {
    use v5.14;
    use utf8;
    use open qw(:std :utf8);
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    with 'LacunaWaX::Roles::MainSplitterWindow::RightPane';

    has 'ancestor' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow::RightPane',
        required    => 1,
    );

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
    );

    #########################################

    has 'planet_name'   => (is => 'rw', isa => 'Str',       required => 1     );
    has 'planet_id'     => (is => 'rw', isa => 'Str',       lazy_build => 1   );
    has 'status'        => (is => 'rw', isa => 'HashRef',   lazy_build => 1   );
    has 'type'          => (is => 'rw', isa => 'Str',       lazy_build => 1   );
    has 'text'          => (is => 'rw', isa => 'Str',       lazy_build => 1   );
    has 'owner'         => (is => 'rw', isa => 'Str',       lazy_build => 1   );

    has 'szr_header'    => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1   );
    has 'szr_res_grid' => (
        is          => 'rw', 
        isa         => 'Wx::FlexGridSizer',     
        lazy_build  => 1,
    );
    has 'lbl_header'    => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1   );
    has 'lbl_text'      => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1   );

    has 'refocus_window_name' => (is => 'rw', isa => 'Str', lazy => 1, default => 'lbl_header');

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->fill_res_grid();

        $self->szr_header->Add($self->lbl_header, 0, 0, 0);
        $self->content_sizer->Add($self->szr_header, 0, 0, 0);
        $self->content_sizer->AddSpacer(20);
        $self->content_sizer->Add($self->lbl_text, 0, 0, 0);
        $self->content_sizer->AddSpacer(20);
        $self->content_sizer->Add($self->szr_res_grid, 0, 0, 0);

        $self->fix_tree_for_stations();

        $self->_set_events();
        return $self;
    }
    sub _build_szr_res_grid {#{{{
        my $self = shift;

        ### 7 rows (5 data, 1 header, 1 spacer), 4 cols, 2px vgap, 50px hgap.
        my $szr_res_grid = Wx::FlexGridSizer->new(7, 4, 2, 50);

        return $szr_res_grid;
    }#}}}
    sub _build_szr_header {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Header');
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $self->planet_name,
            wxDefaultPosition, 
            Wx::Size->new(-1, 30)
        );
        $v->SetFont( wxTheApp->get_font('header_1') );
        return $v;
    }#}}}
    sub _build_lbl_text {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $self->text, 
            wxDefaultPosition, 
            ### If you start changing the height on this, check the result on 
            ### both a station and on a planet.  Station text is bigger.  
            ### Also, stations with warning text ("OMG we haven't seize our 
            ### own star!") will need even more height here.
            Wx::Size->new(400,220)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_owner {#{{{
        my $self = shift;
        return $self->status->{'empire'}{'name'} // 'Owner name unknown';
    }#}}}
    sub _build_planet_id {#{{{
        my $self = shift;
        return wxTheApp->game_client->planet_id( $self->planet_name );
    }#}}}
    sub _build_status {#{{{
        my $self = shift;

        my $s = try {
            wxTheApp->game_client->get_body_status( $self->planet_id );
        }
        catch {
            my $msg = (ref $_) ? $_->text : $_;
            wxTheApp->poperr("$msg");
            return;
        };
        return $s;
    }#}}}
    sub _build_text {#{{{
        my $self  = shift;
        my $owner = $self->owner;
        
        my $s = $self->status;

        my $text = $self->type . " $s->{name} ($s->{x}, $s->{y}) (ID $s->{id})
Owned by $owner
Orbit $s->{orbit} around $s->{star_name} (ID $s->{star_id}), in zone $s->{zone}\n";
        if( $self->type eq 'Station' ) {
            if( defined $s->{station} ) {
                if( $s->{'station'}{'name'} ne $s->{'name'} ) {
                    $text .= "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n";
                    $text .= "THIS STATION IS CURRENTLY UNDER CONTROL OF ANOTHER STATION ($s->{'station'}{'name'}) - THIS MIGHT BE A PROBLEM!\n";
                    $text .= "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n";
                }
            }
            else {
                $text .= "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n";
                $text .= "THIS STATION HAS NOT SEIZED ITS OWN STAR AND IS VULNERABLE - PLEASE GO FIX THAT!\n";
                $text .= "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n";
            }
        }
        elsif( defined $s->{'station'} ) {
            $text .= "Under control of station $s->{station}{name} (ID $s->{station}{id})\n";
        }
        $text .= "Size $s->{size}\n";
        $text .= "$s->{plots_available} plots available\n";
        $text .= "$s->{building_count} buildings\n";
        $text .= "\n";

        if( $self->type eq 'Station' ) {
            my($spent, $total) = @{$s->{'influence'}}{qw(spent total)};
            my $diff = $total - $spent;
            my $pl_star = ($diff == 1) ? 'star' : 'stars';
            $text .= "Influence: $spent/$total";
            if( $diff ) {
                $text .= " - this station can seize $diff more $pl_star.";
            }
            $text .= "\n";

            my $parl = try { wxTheApp->game_client->get_building($self->planet_id, 'Parliament') };
            my $laws = try { $parl->view_laws($self->planet_id) } if $parl;

            my @non_seizure_laws = ();
            LAW:
            foreach my $hr(@{$laws->{'laws'}}) {
                next LAW if $hr->{'name'} =~ /^Seize /;
                push @non_seizure_laws, $hr;
            }

            if( @non_seizure_laws ) {
                $text .= "\nLaws (other than star seizures):\n";
                $text .= "-------------------------------\n";
                foreach my $l(sort {$a->{'name'} cmp $b->{'name'}}@non_seizure_laws) {
                    $text .= "$l->{'name'}\n";
                }
            }
        }

        return $text;
    }#}}}
    sub _build_type {#{{{
        my $self  = shift;
        return ($self->status->{'type'} eq 'space station') ? 'Station' : 'Planet';
    }#}}}
    sub _set_events {}

    sub fill_res_grid {#{{{
        my $self = shift;

        foreach my $number_name(qw(
            food_stored food_capacity food_hour
            ore_stored ore_capacity ore_hour
            water_stored water_capacity water_hour
            energy_stored energy_capacity energy_hour
            happiness happiness_hour
        )) {
            my $commaized_field_name = "c_" . $number_name;
            my $val = wxTheApp->commaize_number($self->status->{$number_name});
            $self->status->{$commaized_field_name} = $val;
        }

        my @grid = (
            'Type',     'Stored',               'Capacity',             'Production/hour',
            '----',     '------',               '--------',             '---------------',
            'Food:',    'c_food_stored',        'c_food_capacity',      'c_food_hour',
            'Ore:',     'c_ore_stored',         'c_ore_capacity',       'c_ore_hour',
            'Water:',   'c_water_stored',       'c_water_capacity',     'c_water_hour',
            'Energy:',  'c_energy_stored',      'c_energy_capacity',    'c_energy_hour',
            'Happy:',   'c_happiness',          q{},                    'c_happiness_hour',
        );

        foreach my $add_this_to_grid( @grid ) {
            ### The alignments will only work when wxEXPAND is _not_ included.
            my( $text, $font, $style );
            if( defined $self->status->{$add_this_to_grid} ) { ### Data
                $text   = sprintf "%s", $self->status->{$add_this_to_grid};
                $font   = wxTheApp->get_font('modern_text_2');
                $style  = wxALIGN_RIGHT;
            }
            else { ### Header
                $text   = $add_this_to_grid;
                $font   = wxTheApp->get_font('bold_modern_text_2');
                $style  = ($add_this_to_grid =~ /:/) 
                    ? wxALIGN_LEFT            # left column header
                    : wxALIGN_CENTRE;         # top row header
            }

            my $v = Wx::StaticText->new( $self->parent, -1, $text, wxDefaultPosition, Wx::Size->new(-1, -1) );
            $v->SetFont( $font );
            $self->szr_res_grid->Add($v, 0, $style);
        }
    }#}}}

    sub fix_tree_for_stations {#{{{
        my $self = shift;

        return unless defined $self->status->{'influence'};

        my $bodies_tree             = wxTheApp->left_pane->bodies_tree;
        my $treectrl                = $bodies_tree->treeview->treectrl;

        ### Get the first planet listed under 'Bodies'
        my( $planet_id, $cookie )   = $treectrl->GetFirstChild( $bodies_tree->bodies_item_id );
        my $data                    = $treectrl->GetItemData( $planet_id );
        my $hr                      = $data->GetData;
        my $planet_name             = $hr->{'cookie'}{'node'};

        ### If that first planet listed is not our current planet, iterate 
        ### through all of that first planet's siblings until we find our 
        ### current planet
        unless( $planet_name eq $self->planet_name ) {
            PLANET_NAME_CHECK:
            while( $planet_id = $treectrl->GetNextSibling($planet_id) ) {
                last unless $planet_id->IsOk;
                my $data        = $treectrl->GetItemData($planet_id);
                my $hr          = $data->GetData;
                $planet_name    = $hr->{'cookie'}{'node'};
                last PLANET_NAME_CHECK if $planet_name eq $self->planet_name;
            }
        }

        unless( $planet_name eq $self->planet_name ) {
            ### Should never happen.
            say "No leaf on the tree matches our current planet.  Wat?";
            return;
        }
            
        my( $planet_child_id, $planet_child_cookie ) = $treectrl->GetFirstChild( $planet_id );
        my $planet_child_name = $treectrl->GetItemText( $planet_child_id );
        if( $planet_child_name eq 'Fire the BFG' ) {
            ### Our current leaf is already set up as a station, so we don't 
            ### have to do anything.
            return;
        }

        ### Still here?  The current leaf is a new-to-this-user Space Station, 
        ### and it's currently displaying the child leaves of a Planet.  
        ### Update the tree.

        wxTheApp->left_pane->bodies_tree->fill_tree;
        return 1;

    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

