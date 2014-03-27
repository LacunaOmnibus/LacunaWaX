
package LacunaWax::Dialog::MissionEditor::FleetRow {
    use v5.14;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHOICE EVT_SPINCTRL EVT_RADIOBOX);

    has 'parent' => (
        is          => 'rw',
        isa         => 'Moose::Object',
        required    => 1,
        documentation => q{
            parent should be either a TabObjective or TabReward.
        }
    );

    #################################

    has [qw( ctrl_width ctrl_height ctrl_height_rdo )] => (
        is          => 'rw',
        isa         => 'Int',
        lazy_build  => 1,
    );

    has 'pnl_main' => (
        is          => 'rw',
        isa         => 'Wx::Panel',
        lazy_build  => 1,
    );

    has 'record' => (
        is          => 'rw',
        isa         => 'Maybe[LacunaWaX::Model::Schema::MissionFleetObjective]',
        predicate   => 'has_record',
        documentation => q{
            If passed in, control values will be set to the values in the record.
        }
    );

    has [qw( chc_ship_type chc_target_color chc_target_type )] => (
        is          => 'rw',
        isa         => 'Wx::Choice',
        lazy_build  => 1,
    );

    has [qw( rdo_in_zone rdo_inhabited rdo_isolationist )] => (
        is          => 'rw',
        isa         => 'Wx::RadioBox',
        lazy_build  => 1,
    );

    has [qw( spin_size_min spin_size_max )] => (
        is          => 'rw',
        isa         => 'Wx::SpinCtrl',
        lazy_build  => 1,
    );

    has 'szr_grid_data' => (
        is          => 'rw',
        isa         => 'Wx::GridSizer',
        lazy_build  => 1
    );

    sub BUILD {
        my $self = shift;

        $self->initialize_grid_data();

        ### If we were handed a record, we need to display the correct inputs.  
        ### In that case, force a call to OnChangeType.
        #$self->update_to_record();

        $self->pnl_main->SetSizer( $self->szr_grid_data );
        $self->_set_events;
        return $self;
    }
    sub clearme {#{{{
        my $self = shift;
        ### Destroys all windows for the current row.
        $self->pnl_main->Destroy();
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CHOICE(     $self->pnl_main,  $self->chc_target_type->GetId,   sub{$self->OnChangeType(@_)}   );
        EVT_SPINCTRL(   $self->pnl_main,  $self->spin_size_min->GetId,    sub{$self->OnChangeMinSize(@_)}   );
        EVT_SPINCTRL(   $self->pnl_main,  $self->spin_size_max->GetId,    sub{$self->OnChangeMaxSize(@_)}   );
        return 1;
    }#}}}

    sub _build_ctrl_height {#{{{
        return 25;
    }#}}}
    sub _build_ctrl_height_rdo {#{{{
        return 35;
    }#}}}
    sub _build_ctrl_width {#{{{
        return 100;
    }#}}}
    sub _build_chc_ship_type {#{{{
        my $self = shift;

        my $types = [];
        for my $t(@{ wxTheApp->ship_types('human') }) {
            wxTheApp->Yield();
            push @{$types}, $t;
        }

        my $v = Wx::Choice->new(
            $self->pnl_main, -1,
            wxDefaultPosition, 
            Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            $types,
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->SetToolTip("Ship type to send");
        if( $self->record ) { $v->SetStringSelection( $self->record->ship_type ); }

        return $v;
    }#}}}
    sub _build_chc_target_color {#{{{
        my $self = shift;

        my $colors = wxTheApp->star_colors;
        unshift @{$colors}, 'any';

        my $v = Wx::Choice->new(
            $self->pnl_main, -1,
            wxDefaultPosition, 
            Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            $colors,
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->SetToolTip("Color of star");
        if( $self->record ) { $v->SetStringSelection( $self->record->targ_color ); }

        if( $self->chc_target_type->GetStringSelection =~ /star/i ) {
            $v->Enable(1);
        }
        else {
            $v->Enable(0);
        }

        return $v;
    }#}}}
    sub _build_chc_target_type {#{{{
        my $self = shift;

        my $v = Wx::Choice->new(
            $self->pnl_main, -1,
            wxDefaultPosition, 
            Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            [ 'Asteroid', 'Habitable', 'Gas Giant', 'Star' ],
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->SetToolTip("Type of body to target");
        if( $self->record ) { $v->SetStringSelection( wxTheApp->titlecase($self->record->targ_type) ); }

        return $v;
    }#}}}
    sub _build_spin_size_min {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 121, 0  # min, max, initial
        );
        $v->SetToolTip("Minimum size of target");
        if( $self->record ) { $v->SetValue( $self->record->targ_size_min ); }

        return $v;
    }#}}}
    sub _build_spin_size_max {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 121, 121  # min, max, initial
        );
        if( $self->record ) { $v->SetValue( $self->record->targ_size_max ); }
        $v->SetToolTip("Maximum size of target");

        return $v;
    }#}}}
    sub _build_rdo_in_zone {#{{{
        my $self = shift;

        my $v = Wx::RadioBox->new(
            $self->pnl_main, -1, 
            "In Current Zone?", 
            wxDefaultPosition, 
            Wx::Size->new($self->ctrl_width,$self->ctrl_height_rdo), 
            ['Yes', 'No'],
            1, 
            wxRA_SPECIFY_ROWS
        );
        $v->SetFont( wxTheApp->get_font('para_text_sub') );
        if( $self->record ) { $v->SetSelection( ($self->record->targ_in_zone) ? 0 : 1 ); }

        return $v;
    }#}}}
    sub _build_rdo_inhabited {#{{{
        my $self = shift;

        my $v = Wx::RadioBox->new(
            $self->pnl_main, -1, 
            "Inhabited?", 
            wxDefaultPosition, 
            Wx::Size->new($self->ctrl_width,$self->ctrl_height_rdo), 
            ['Yes', 'No'],
            1, 
            wxRA_SPECIFY_ROWS
        );
        $v->SetFont( wxTheApp->get_font('para_text_sub') );
        if( $self->record ) {
            $v->SetSelection( ($self->record->targ_inhabited) ? 0 : 1 );
        }
        else {
            $v->SetSelection( 1 );  # default to 'not inhabited'
        }

        return $v;
    }#}}}
    sub _build_rdo_isolationist {#{{{
        my $self = shift;

        my $v = Wx::RadioBox->new(
            $self->pnl_main, -1, 
            "Isolationist?", 
            wxDefaultPosition, 
            Wx::Size->new($self->ctrl_width,$self->ctrl_height_rdo), 
            ['Yes', 'No'],
            1, 
            wxRA_SPECIFY_ROWS
        );
        $v->SetFont( wxTheApp->get_font('para_text_sub') );
        if( $self->record ) {
            $v->SetSelection( ($self->record->targ_isolationist) ? 0 : 1 );
        }
        else {
            $v->SetSelection( 1 ); # default to "No, don't target iso empires".
        }

        return $v;
    }#}}}
    sub _build_pnl_main {#{{{
        my $self = shift;
        #my $v = Wx::Panel->new($self->parent->pnl_main, -1, wxDefaultPosition, wxDefaultSize);
        my $v = Wx::Panel->new($self->parent->swin_main, -1, wxDefaultPosition, wxDefaultSize);
        return $v;
    }#}}}
    sub _build_szr_grid_data {#{{{
        my $self = shift;
        ### Cols, row 1:
        ###     chc_ship_type
        ###     chc_target_type
        ###     spin_size_min
        ###     spin_size_max
        ### Cols, row 2:
        ###     rdo_in_zone
        ###     rdo_inhabited
        ###     rdo_isolationist
        my $v = Wx::GridSizer->new( 2, 4, 1, 5 );   # r, c, vgap, hgap

        return $v;
    }#}}}
    sub initialize_grid_data {#{{{
        my $self = shift;

        $self->szr_grid_data->Add( $self->chc_ship_type );
        $self->szr_grid_data->Add( $self->chc_target_type );
        $self->szr_grid_data->Add( $self->spin_size_min );
        $self->szr_grid_data->Add( $self->spin_size_max );

        $self->szr_grid_data->Add( $self->rdo_in_zone );
        $self->szr_grid_data->Add( $self->rdo_inhabited );
        $self->szr_grid_data->Add( $self->rdo_isolationist );
        $self->szr_grid_data->Add( $self->chc_target_color );

        $self->szr_grid_data->Layout();
    }#}}}

    sub OnChangeMinSize {#{{{
        my $self = shift;

        my $min = $self->spin_size_min->GetValue;
        my $max = $self->spin_size_max->GetValue;

        if( $min > $max ) {
            $self->spin_size_max->SetValue( $min );
        }

        return 1;
    }#}}}
    sub OnChangeMaxSize {#{{{
        my $self = shift;

        my $min = $self->spin_size_min->GetValue;
        my $max = $self->spin_size_max->GetValue;

        if( $min > $max ) {
            $self->spin_size_min->SetValue( $max );
        }

        return 1;
    }#}}}
    sub OnChangeType {#{{{
        my $self = shift;

        my $type = $self->chc_target_type->GetStringSelection;
        
        if( $type =~ /star/i ) {
            $self->chc_target_color->Enable(1);
        }
        else {
            $self->chc_target_color->Enable(0);
        }

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

