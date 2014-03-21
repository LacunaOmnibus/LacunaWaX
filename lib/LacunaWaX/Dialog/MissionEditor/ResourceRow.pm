

### This now works using FlexGridSizer, but I think it should work with 
### GridSizer.  And if it does, a lot of the stupid can be removed from here.


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

    #################################

    has 'pnl_main' => (
        is          => 'rw',
        isa         => 'Wx::Panel',
        lazy_build  => 1,
    );

    has [qw( chc_entity_name chc_entity_type )] => (
        is          => 'rw',
        isa         => 'Wx::Choice',
        lazy_build  => 1,
    );

    has [qw(
        spin_entity_quantity 
        spin_extra_level
        spin_min_berth spin_min_cargo spin_min_combat spin_min_occupants spin_min_speed spin_min_stealth
    )] => (
        is          => 'rw',
        isa         => 'Wx::SpinCtrl',
        lazy_build  => 1,
    );

    has 'szr_grid_data' => (
        is          => 'rw',
        isa         => 'Wx::FlexGridSizer',
        lazy_build  => 1
    );

    has [qw(
        lbl_space_02 lbl_space_03 lbl_space_04 lbl_space_05
        lbl_space_10 lbl_space_11 lbl_space_12 lbl_space_13 lbl_space_14 lbl_space_15
    )] => (
        is          => 'rw',
        isa         => 'Wx::StaticText',
        lazy        => 1,
        default     => sub {
            my $self = shift;
            my $v = Wx::StaticText->new(
                $self->pnl_main, -1, q{test},
                wxDefaultPosition, Wx::Size->new(100,30)
            );
            return $v;
        }
    );

    sub BUILD {
        my $self = shift;

        ### Row 1
        $self->szr_grid_data->Add( $self->chc_entity_type );
        $self->szr_grid_data->Add( $self->spin_entity_quantity );
        $self->szr_grid_data->Add( $self->lbl_space_02 );
        $self->szr_grid_data->Add( $self->lbl_space_03 );
        $self->szr_grid_data->Add( $self->lbl_space_04 );
        $self->szr_grid_data->Add( $self->lbl_space_05 );

        ### Row 2
        $self->szr_grid_data->Add( $self->lbl_space_10 );
        $self->szr_grid_data->Add( $self->lbl_space_11 );
        $self->szr_grid_data->Add( $self->lbl_space_12 );
        $self->szr_grid_data->Add( $self->lbl_space_13 );
        $self->szr_grid_data->Add( $self->lbl_space_14 );
        $self->szr_grid_data->Add( $self->lbl_space_15 );

        $self->pnl_main->SetSizer( $self->szr_grid_data );
        $self->_set_events;
        return $self;
    }
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
            wxDefaultPosition, Wx::Size->new(100,-1),
            $types,
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        return $v;
    }#}}}
    sub _build_chc_entity_name {#{{{
        my $self = shift;

        my $v = Wx::Choice->new(
            $self->pnl_main, -1,
            wxDefaultPosition, Wx::Size->new(100,-1),
            []
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        return $v;
    }#}}}
    sub _build_spin_entity_quantity {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(100, -1), 
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 0, 0  # min, max, initial
        );

        return $v;
    }#}}}
    sub _build_spin_extra_level {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(100, -1), 
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 30, 0  # min, max, initial
        );
        $v->SetToolTip("Extra build level");
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_berth {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(100, -1), 
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 0, 0  # min, max, initial
        );
        $v->SetToolTip("Minimum berth level");
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_cargo {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(100, -1), 
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 0, 0  # min, max, initial
        );
        $v->SetToolTip("Minimum cargo hold size");
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_combat {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(100, -1), 
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 0, 0  # min, max, initial
        );
        $v->SetToolTip("Minimum combat rating");
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_occupants {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(100, -1), 
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 0, 0  # min, max, initial
        );
        $v->SetToolTip("Minimum occupants");
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_speed {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(100, -1), 
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 0, 0  # min, max, initial
        );
        $v->SetToolTip("Minimum speed");
        $v->Hide();

        return $v;
    }#}}}
    sub _build_spin_min_stealth {#{{{
        my $self = shift;

        my $v = Wx::SpinCtrl->new(
            $self->pnl_main, -1, q{}, 
            wxDefaultPosition, 
            Wx::Size->new(100, -1), 
            wxSP_ARROW_KEYS|wxSP_WRAP, 
            0, 0, 0  # min, max, initial
        );
        $v->SetToolTip("Minimum stealth rating");
        $v->Hide();

        return $v;
    }#}}}
    sub _build_pnl_main {#{{{
        my $self = shift;
        my $v = Wx::Panel->new($self->parent->pnl_main, -1, wxDefaultPosition, wxDefaultSize);
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
        my $v = Wx::FlexGridSizer->new( 2, 6, 5, 5 );   # r, c, vgap, hgap
        return $v;
    }#}}}

    sub OnChangeType {#{{{
        my $self = shift;
        my $a = shift;
        my $b = shift;

        ### Reset any conditional controls
        $self->chc_entity_name->Hide();
        $self->spin_extra_level->Hide();
        $self->spin_min_berth->Hide();
        $self->spin_min_cargo->Hide();
        $self->spin_min_combat->Hide();
        $self->spin_min_occupants->Hide();
        $self->spin_min_speed->Hide();
        $self->spin_min_stealth->Hide();

        my $type = $self->chc_entity_type->GetStringSelection;
        return if $type eq 'SELECT';

        ### CHECK
        ### All values for $max in here are arbitrary and almost certainly 
        ### wrong.

        if( $type =~ /(essentia|happiness)/ ) {#{{{
            $self->chc_entity_name->Show(0);
            my $max = ( $type eq 'essentia' ) ? 100 : 1_000_000;
            $self->spin_entity_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $cmax");
            return 1;
        }#}}}
        if( $type eq 'glyphs' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->ore_types }) {
                $self->chc_entity_name->Append($t);
            }
            my $max = 100;
            $self->spin_entity_quantity->SetRange(0, $max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $max");

            $self->chc_entity_name->Show(1);
            $self->szr_grid_data->Replace( $self->lbl_space_02, $self->chc_entity_name );
            $self->szr_grid_data->Layout();

            return 1;
        }#}}}
        if( $type eq 'plans' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->building_types('human') }) {
                $self->chc_entity_name->Append($t);
            }
            my $max = 10;
            $self->spin_entity_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $cmax");

            $self->chc_entity_name->Show(1);
            $self->spin_extra_level->Show(1);
            $self->szr_grid_data->Replace( $self->lbl_space_02, $self->chc_entity_name );
            $self->szr_grid_data->Replace( $self->lbl_space_03, $self->spin_extra_level );
            $self->szr_grid_data->Layout();

            return 1;
        }#}}}
        if( $type eq 'resources' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->food_types }, @{ wxTheApp->ore_types} ) {
                $self->chc_entity_name->Append($t);
            }
            my $max = 1_000_000;
            $self->spin_entity_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $cmax");

            $self->chc_entity_name->Show(1);
            $self->szr_grid_data->Replace( $self->lbl_space_02, $self->chc_entity_name );
            $self->szr_grid_data->Layout();

            return 1;
        }#}}}
        if( $type eq 'ships' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->ship_types('human') }) {
                $self->chc_entity_name->Append($t);
            }
            my $max = 10;
            $self->spin_entity_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $cmax");

            $self->chc_entity_name->Show(1);
            $self->spin_min_berth->Show(1);
            $self->spin_min_cargo->Show(1);
            $self->spin_min_combat->Show(1);
            $self->spin_min_occupants->Show(1);
            $self->spin_min_speed->Show(1);
            $self->spin_min_stealth->Show(1);
            $self->szr_grid_data->Replace( $self->lbl_space_02, $self->chc_entity_name );
            $self->szr_grid_data->Replace( $self->lbl_space_10, $self->spin_min_berth );
            $self->szr_grid_data->Replace( $self->lbl_space_11, $self->spin_min_cargo );
            $self->szr_grid_data->Replace( $self->lbl_space_12, $self->spin_min_combat );
            $self->szr_grid_data->Replace( $self->lbl_space_13, $self->spin_min_occupants );
            $self->szr_grid_data->Replace( $self->lbl_space_14, $self->spin_min_speed );
            $self->szr_grid_data->Replace( $self->lbl_space_15, $self->spin_min_stealth );
            $self->szr_grid_data->Layout();

            return 1;
        }#}}}

        return 1;
    }#}}}
    sub OnChangeTypeOrig {#{{{
        my $self = shift;
        my $a = shift;
        my $b = shift;

        ### Reset any conditional controls
        $self->spin_extra_level->Hide();
        $self->spin_min_berth->Hide();
        $self->spin_min_cargo->Hide();
        $self->spin_min_combat->Hide();
        $self->spin_min_occupants->Hide();
        $self->spin_min_speed->Hide();
        $self->spin_min_stealth->Hide();

        my $type = $self->chc_entity_type->GetStringSelection;
        return if $type eq 'SELECT';

        ### CHECK
        ### All values for $max in here are arbitrary and almost certainly 
        ### wrong.

        if( $type =~ /(essentia|happiness)/ ) {#{{{
            $self->chc_entity_name->Show(0);
            my $max = ( $type eq 'essentia' ) ? 100 : 1_000_000;
            $self->spin_entity_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $cmax");
            return 1;
        }#}}}
        if( $type eq 'glyphs' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->ore_types }) {
                $self->chc_entity_name->Append($t);
            }
            my $max = 100;
            $self->spin_entity_quantity->SetRange(0, $max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $max");
            $self->chc_entity_name->Show(1);
            return 1;
        }#}}}
        if( $type eq 'plans' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->building_types('human') }) {
                $self->chc_entity_name->Append($t);
            }
            my $max = 10;
            $self->spin_entity_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $cmax");
            $self->chc_entity_name->Show(1);
            $self->spin_extra_level->Show(1);
            wxTheApp->Yield;
            return 1;
        }#}}}
        if( $type eq 'resources' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->food_types }, @{ wxTheApp->ore_types} ) {
                $self->chc_entity_name->Append($t);
            }
            my $max = 1_000_000;
            $self->spin_entity_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $cmax");
            $self->chc_entity_name->Show(1);
            return 1;
        }#}}}
        if( $type eq 'ships' ) {#{{{
            $self->chc_entity_name->Clear();
            for my $t(@{ wxTheApp->ship_types('human') }) {
                $self->chc_entity_name->Append($t);
            }
            my $max = 10;
            $self->spin_entity_quantity->SetRange(0, $max);
            my $cmax = wxTheApp->commaize_number($max);
            $self->spin_entity_quantity->SetToolTip("Quantity - maximum is $cmax");
            $self->chc_entity_name->Show(1);
            $self->spin_min_berth->Show(1);
            $self->spin_min_cargo->Show(1);
            $self->spin_min_combat->Show(1);
            $self->spin_min_occupants->Show(1);
            $self->spin_min_speed->Show(1);
            $self->spin_min_stealth->Show(1);

            return 1;
        }#}}}

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

If a control gets put into a cell, and that control starts out hidden, the cell 
collapses such that it has no size:

        | ctrl_1 | ctrl_2 | ctrl_3 (hidden) | ctrl_4 |

With that setup, if you try to come along after the fact and show ctrl_3, the 
column it's in has no width, so the control doesn't have anywhere to display.

Yes, it's a _Flex_ grid sizer, and yes, I've tried calling every combo of 
Layout(), Refresh(), Update(), etc I can come up with.  The column refuses to 
resize.



OTOH, if you start out with all of the controls shown:

        | ctrl_1 | ctrl_2 | ctrl_3 | ctrl_4 |

...and then you hide one after the fact, the column's width is already set.  So 
at this point, you're fine to hide and re-show controls to your heart's content.


My problem here is that I want my grid size, but I also want many of the ctrls 
to start out hidden.


So what I'm doing here is starting with my grid (6 cols, 2 rows), each grid 
starts with StaticText ctrl.  These text ctrls have pre-set widths and heights, 
but all start out with the empty string.  So they're technically Shown, but 
there's nothing to see, but they occupy the correct amount of space.

From here, we can Replace any of those StaticText controls with the control we 
actually want to occupy that space.

Conveniently, we _can_ do this (this example uses a 2x2 grid):

    grid->Add( text_ctrl_00 );
    grid->Add( text_ctrl_01 );
    grid->Add( text_ctrl_10 );
    grid->Add( text_ctrl_11 );

    grid->Replace( text_ctrl_01, some_new_control_1 );
    grid->Layout();

    ...time passes...

    grid->Replace( text_ctrl_01, some_new_control_2 );
    grid->Layout();

That does work.  Even though the first Replace() call effectively removed the 
text_ctrl_01 in favor of some_new_control_1, the second call to Replace(), which 
is still replacing text_ctrl_01, works.

My guess is that text_ctrl_01 still occupies the same cell, it's just hidden.

