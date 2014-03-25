

### This now works using GridSizer, but I think it should work with GridSizer.  
### And if it does, a lot of the stupid can be removed from here.


package LacunaWax::Dialog::MissionEditor::ResourceRow {
    use v5.14;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHOICE EVT_SPINCTRL);

    has 'parent' => (
        is          => 'rw',
        isa         => 'Moose::Object',
        required    => 1,
        documentation => q{
            parent should be either a TabObjective or TabReward.
        }
    );

    has 'type' => (
        is          => 'rw',
        isa         => 'Str',
        required    => 1,
        documentation => q{
            must be either 'objective' or 'reward'
        }
    );

    #################################

    has [qw( ctrl_width ctrl_height )] => (
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
        isa         => 'Maybe[DBIx::Class::Core]',
        predicate   => 'has_record',
        documentation => q{
            If passed in, control values will be set to the values in the record.
            This can be either a LacunaWaX::Model::Schema::MissionMaterialObjective 
            or a LacunaWaX::Model::Schema::MissionReward. 
        }
    );

    has [qw( chc_entity_name chc_entity_type )] => (
        is          => 'rw',
        isa         => 'Wx::Choice',
        lazy_build  => 1,
    );

    has [qw(
        spin_quantity spin_extra_level
        spin_min_berth spin_min_cargo spin_min_combat spin_min_occupants spin_min_speed spin_min_stealth
    )] => (
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
        $self->update_to_record();

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
        EVT_CHOICE(   $self->pnl_main,  $self->chc_entity_type->GetId,    sub{$self->OnChangeType(@_)}   );
        return 1;
    }#}}}

    sub _build_chc_entity_type {#{{{
        my $self = shift;

        my $types = [qw(SELECT essentia glyphs happiness plans resources ships)];

        my $v = Wx::Choice->new(
            $self->pnl_main, -1,
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            $types,
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        if( $self->record ) { $v->SetStringSelection( $self->record->type ); }

        return $v;
    }#}}}
    sub _build_chc_entity_name {#{{{
        my $self = shift;

        my $v = Wx::Choice->new(
            $self->pnl_main, -1,
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            []
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        if( $self->record ) { $v->SetStringSelection( $self->record->name ); }

        return $v;
    }#}}}
    sub _build_ctrl_height {#{{{
        return 25;
    }#}}}
    sub _build_ctrl_width {#{{{
        return 100;
    }#}}}
    sub _build_spin_quantity {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 0, 0  # min, max, initial
        );
        if( $self->record ) { $v->SetValue( $self->record->quantity ); }

        return $v;
    }#}}}
    sub _build_spin_extra_level {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 30, 0  # min, max, initial
        );
        $v->SetToolTip("Extra build level");
        if( $self->record ) { $v->SetValue( $self->record->extra_level ); }
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_berth {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 30, 0  # min, max, initial
        );
        my $text = ($self->type eq 'objective') ? 'Minimum ' : q{};
        $text .= 'Berth Level';
        $v->SetToolTip($text);
        if( $self->record ) { $v->SetValue( $self->record->berth ); }
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_cargo {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 200000000, 0  # min, max, initial
        );
        my $text = ($self->type eq 'objective') ? 'Minimum ' : q{};
        $text .= 'Cargo Hold Size';
        $v->SetToolTip($text);
        if( $self->record ) { $v->SetValue( $self->record->cargo ); }
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_combat {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 100000, 0  # min, max, initial
        );
        my $text = ($self->type eq 'objective') ? 'Minimum ' : q{};
        $text .= 'Combat Rating';
        $v->SetToolTip($text);
        if( $self->record ) { $v->SetValue( $self->record->combat ); }
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_occupants {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 1000000, 0  # min, max, initial
               
        );
        my $text = ($self->type eq 'objective') ? 'Minimum ' : q{};
        $text .= 'Occupants';
        $v->SetToolTip($text);
        if( $self->record ) { $v->SetValue( $self->record->occupants ); }
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_speed {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 50000, 0  # min, max, initial
               
        );
        my $text = ($self->type eq 'objective') ? 'Minimum ' : q{};
        $text .= 'Speed';
        $v->SetToolTip($text);
        if( $self->record ) { $v->SetValue( $self->record->speed ); }
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_stealth {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, Wx::Size->new( $self->ctrl_width, $self->ctrl_height ),
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 100000, 0  # min, max, initial
               
        );
        my $text = ($self->type eq 'objective') ? 'Minimum ' : q{};
        $text .= 'Stealth Rating';
        $v->SetToolTip($text);
        if( $self->record ) { $v->SetValue( $self->record->stealth ); }
        $v->Hide();

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
        ###     entity type (choice)
        ###     entity name (choice)
        ###     entity quantity (spinner)
        ###     entity extra level (spinner; starts out hidden)
        ### Cols, row 2:
        ###     spin_min berth
        ###     spin_min_cargo
        ###     spin_min_combat
        ###     spin_min_occupants
        ###     spin_min_speed
        ###     spin_min_stealth
        my $v = Wx::GridSizer->new( 2, 6, 5, 5 );   # r, c, vgap, hgap

        return $v;
    }#}}}

    sub initialize_grid_data {#{{{
        my $self = shift;

        ### Add the type and quantity controls, which always appear, then add 
        ### spacers into the rest of the cells, which is needed to keep the 
        ### second row from collapsing the first.
        $self->szr_grid_data->Add( $self->chc_entity_type );
        $self->szr_grid_data->Add( $self->spin_quantity );
        for(3..6) { $self->szr_grid_data->Add( 0,0,0 ); }
        for(1..6) { $self->szr_grid_data->Add( 0,0,0 ); }
        $self->szr_grid_data->Layout();
    }#}}}
    sub update_to_record {#{{{
        my $self = shift;

        if( $self->has_record ) {
            $self->chc_entity_type->SetStringSelection( $self->record->type );
            $self->chc_entity_type->Layout();
            $self->OnChangeType();
        }
    }#}}}

    sub OnChangeType {#{{{
        my $self = shift;

        my $type = $self->chc_entity_type->GetStringSelection;
        return if $type eq 'SELECT';

        ### When the user individually changes the type, we want to throb.  
        ### Especially for ships and plans, which take a second or two to 
        ### populate.
        ### However, if the user is loading a previous mission from the 
        ### database, that load process itself will already be running the 
        ### throbber.  Restarting and stopping it here will only make it look 
        ### choppy.
        my $do_local_throb = ( wxTheApp->is_throbbing ) ? 0 : 1;
        wxTheApp->throb() if $do_local_throb;

        ### Clear the sizer, then re-add controls that appear for every 
        ### resource
        $self->szr_grid_data->Clear();
        $self->szr_grid_data->Add( $self->chc_entity_type );
        $self->szr_grid_data->Add( $self->spin_quantity );

        ### Hide any inputs that might be showing
        $self->chc_entity_name->Hide();
        $self->spin_extra_level->Hide();
        $self->spin_min_berth->Hide();
        $self->spin_min_cargo->Hide();
        $self->spin_min_combat->Hide();
        $self->spin_min_occupants->Hide();
        $self->spin_min_speed->Hide();
        $self->spin_min_stealth->Hide();

        ### CHECK
        ### All values for $max below are arbitrary and almost certainly 
        ### wrong.

        if( $type =~ /(essentia|happiness)/ ) {#{{{
            my $max = ( $type eq 'essentia' ) ? 100 : 1_000_000;
            $self->spin_quantity->SetRange(0, $max);
            $self->spin_quantity->SetValue( $self->record->quantity ) if $self->has_record;
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_quantity->SetToolTip("Quantity - maximum is $cmax");
            $self->szr_grid_data->Layout();
        }#}}}
        elsif( $type eq 'glyphs' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->ore_types }) {
                wxTheApp->Yield();
                $self->chc_entity_name->Append($t);
            }
            my $max = 100;
            $self->spin_quantity->SetRange(0, $max);
            $self->spin_quantity->SetToolTip("Quantity - maximum is $max");

            if( $self->has_record ) {
                $self->chc_entity_name->SetStringSelection( $self->record->name );
                $self->spin_quantity->SetValue( $self->record->quantity );
            }

            $self->szr_grid_data->Add( $self->chc_entity_name );
            $self->chc_entity_name->Show(1);
            $self->szr_grid_data->Layout();
        }#}}}
        elsif( $type eq 'plans' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->building_types('human') }) {
                wxTheApp->Yield();
                $self->chc_entity_name->Append($t);
            }
            my $max = 10;
            $self->spin_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_quantity->SetToolTip("Quantity - maximum is $cmax");

            $self->szr_grid_data->Add( $self->chc_entity_name );
            $self->szr_grid_data->Add( $self->spin_extra_level );

            if( $self->has_record ) {
                $self->chc_entity_name->SetStringSelection( $self->record->name );
                $self->spin_quantity->SetValue( $self->record->quantity );
                $self->spin_extra_level->SetValue( $self->record->extra_level );
            }

            $self->chc_entity_name->Show(1);
            $self->spin_extra_level->Show(1);
            $self->szr_grid_data->Layout();
            wxTheApp->Yield();
        }#}}}
        elsif( $type eq 'resources' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->food_types }, @{ wxTheApp->ore_types} ) {
                wxTheApp->Yield();
                $self->chc_entity_name->Append($t);
            }
            my $max = 1_000_000;
            $self->spin_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_quantity->SetToolTip("Quantity - maximum is $cmax");
            $self->szr_grid_data->Add( $self->chc_entity_name );

            if( $self->has_record ) {
                $self->chc_entity_name->SetStringSelection( $self->record->name );
                $self->spin_quantity->SetValue( $self->record->quantity );
            }
            $self->chc_entity_name->Show(1);
            $self->szr_grid_data->Layout();
            wxTheApp->Yield();
        }#}}}
        elsif( $type eq 'ships' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->ship_types('human') }) {
                wxTheApp->Yield();
                $self->chc_entity_name->Append($t);
            }
            my $max = 10;
            $self->spin_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_quantity->SetToolTip("Quantity - maximum is $cmax");

            ### Finish up row 1
            $self->szr_grid_data->Add( $self->chc_entity_name );
            $self->szr_grid_data->Add( 0,0,0 );
            $self->szr_grid_data->Add( 0,0,0 );
            $self->szr_grid_data->Add( 0,0,0 );

            ### Row 2
            $self->szr_grid_data->Add( $self->spin_min_berth );
            $self->szr_grid_data->Add( $self->spin_min_cargo );
            $self->szr_grid_data->Add( $self->spin_min_combat );
            $self->szr_grid_data->Add( $self->spin_min_occupants );
            $self->szr_grid_data->Add( $self->spin_min_speed );
            $self->szr_grid_data->Add( $self->spin_min_stealth );

            if( $self->has_record ) {
                $self->chc_entity_name->SetStringSelection( $self->record->name );
                $self->spin_quantity->SetValue( $self->record->quantity );

                $self->spin_min_berth->SetValue( $self->record->berth );
                $self->spin_min_cargo->SetValue( $self->record->cargo );
                $self->spin_min_combat->SetValue( $self->record->combat );
                $self->spin_min_occupants->SetValue( $self->record->occupants );
                $self->spin_min_speed->SetValue( $self->record->speed );
                $self->spin_min_stealth->SetValue( $self->record->stealth );
            }

            $self->chc_entity_name->Show(1);
            $self->spin_min_berth->Show(1);
            $self->spin_min_cargo->Show(1);
            $self->spin_min_combat->Show(1);
            $self->spin_min_occupants->Show(1);
            $self->spin_min_speed->Show(1);
            $self->spin_min_stealth->Show(1);

            $self->szr_grid_data->Layout();

            wxTheApp->Yield();
        }#}}}

        #$self->parent->pnl_main->Layout;
        $self->parent->swin_main->Layout;
        wxTheApp->endthrob() if $do_local_throb;
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

