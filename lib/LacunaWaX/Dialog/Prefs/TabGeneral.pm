
package LacunaWax::Dialog::Prefs::TabGeneral {
    use v5.14;
    use DateTime::TimeZone;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHOICE EVT_RADIOBOX);

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::Dialog::Prefs',
        required    => 1,
    );

    #################################

    has 'pnl_main' => (
        is          => 'rw',
        isa         => 'Wx::Panel',
        lazy_build  => 1,
        documentation => q{
            The main wxwindow used as a parent for all our widgets.
        }
    );

    has 'szr_grid' => (
        is          => 'rw', 
        isa         => 'Wx::FlexGridSizer',     
        lazy_build  => 1,
    );

    has 'btn_save' => (
        is          => 'rw',
        isa         => 'Wx::Button',
        lazy_build  => 1,
    );

    has [ 'lbl_2412', 'lbl_tz' ] => (
        is          => 'rw',
        isa         => 'Wx::StaticText',
        lazy_build  => 1,
    );

    has [ 'chc_tz_category', 'chc_tz' ] => (
        is          => 'rw',
        isa         => 'Wx::Choice',
        lazy_build  => 1,
    );

    has 'rdo_2412' => (
        is          => 'rw',
        isa         => 'Wx::RadioBox',
        lazy_build  => 1
    );

    has 'current_category' => (
        is          => 'rw',
        isa         => 'Maybe[Str]',
        lazy_build  => 1,
        documentation => q{
            The category ("America" in "America/New_York") of the TZ currently in use by the application.
        }
    );
    has 'current_tz_name' => (
        is          => 'rw',
        isa         => 'Maybe[Str]',
        lazy_build  => 1,
        documentation => q{
            The zone ("New_York" in "America/New_York") of the TZ currently in use by the application.
        }
    );
    has 'tz_categories' => (
        is          => 'rw',
        isa         => 'ArrayRef',
        lazy_build  => 1,
        documentation => q{
            The contents of the time zone Categories select box - retval of 
            DateTime::TimeZone->categories() with "Select One" jammed in there first.
        }
    );

### Grid Layout {#{{{
=pod

The FlexGridSizer that lays out our elements has extra unseen columns and 
rows.

ROWS
    - The first row is a spacer.
    - There's another spacer row just before the save button
    - The save button is itself in a row; it's not outside the grid.

COLUMNS
    - The first column is a spacer
        - *** HEY READ THAT AGAIN ***
        - If you add a new row, make sure that the first item you add is a 
          spacer cell.
                $self->szr_grid->AddSpacer(10); # first cell - left margin column

=cut
### }#}}}

    sub BUILD {
        my $self = shift;

        ### Top margin row
        $self->szr_grid->AddSpacer(10); # left margin column
        $self->szr_grid->AddSpacer(10);
        $self->szr_grid->AddSpacer(10);
        $self->szr_grid->AddSpacer(10);

        ### 12- or 24- hour clock
        $self->szr_grid->AddSpacer(10); # left margin column
        $self->szr_grid->Add($self->lbl_2412, 0, 0, 0);
        $self->szr_grid->Add($self->rdo_2412, 0, 0, 0);
        $self->szr_grid->AddSpacer(10);

        ### Time zone
        $self->szr_grid->AddSpacer(10); # left margin column
        $self->szr_grid->Add($self->lbl_tz, 0, 0, 0);
        $self->szr_grid->Add($self->chc_tz_category, 0, 0, 0);
        $self->set_tzs_from_category;
        $self->szr_grid->Add($self->chc_tz, 0, 0, 0);

        ### Spacer row before save button
        $self->szr_grid->AddSpacer(10); # left margin column
        $self->szr_grid->AddSpacer(10);
        $self->szr_grid->AddSpacer(10);
        $self->szr_grid->AddSpacer(10);

        ### Save button
        $self->szr_grid->AddSpacer(10); # left margin column
        $self->szr_grid->Add($self->btn_save, 0, 0, 0);
        $self->szr_grid->AddSpacer(10);
        $self->szr_grid->AddSpacer(10);

        $self->pnl_main->SetSizer( $self->szr_grid );

        $self->_set_events;

        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON(     $self->pnl_main,    $self->btn_save->GetId,         sub{$self->OnSavePrefs(@_)}         );
        EVT_CHOICE(     $self->pnl_main,    $self->chc_tz_category->GetId,  sub{$self->OnChooseTZCategory()}    );
        EVT_CHOICE(     $self->pnl_main,    $self->chc_tz->GetId,           sub{$self->OnChooseTZ()}            );
        EVT_RADIOBOX(   $self->pnl_main,    $self->rdo_2412->GetId,         sub{$self->OnRadio2412(@_)}         );
        return 1;
    }#}}}

    sub _build_btn_save {#{{{
        my $self = shift;
        return Wx::Button->new($self->pnl_main, -1, "Save");
    }#}}}
    sub _build_chc_tz_category {#{{{
        my $self = shift;
        my $v = Wx::Choice->new(
            $self->pnl_main, -1, 
            wxDefaultPosition, 
            Wx::Size->new(75,40), 
            $self->tz_categories,
        );

        if( my $cat = $self->current_category ) {
            $v->SetStringSelection($cat);
        }

        return $v;
    }#}}}
    sub _build_chc_tz {#{{{
        my $self = shift;

        my $v = Wx::Choice->new(
            $self->pnl_main, -1, 
            wxDefaultPosition, 
            Wx::Size->new(150,40), 
            [ ],    # start empty
        );
        $v->SetSelection(0);

        return $v;
    }#}}}
    sub _build_lbl_2412 {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            "\nClock Type", # Leading newline so it lines up with the radiobox
            wxDefaultPosition, 
            Wx::Size->new(80,40)
        );
        $v->SetFont( wxTheApp->get_font('bold_para_text_1') );
        return $v;
    }#}}}
    sub _build_lbl_tz {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            "Time Zone",
            wxDefaultPosition, 
            Wx::Size->new(80,40)
        );
        $v->SetFont( wxTheApp->get_font('bold_para_text_1') );
        $v->SetToolTip("Your local time zone is probably already set correctly.  Leave this alone if the clock is correct.");
        return $v;
    }#}}}
    sub _build_pnl_main {#{{{
        my $self = shift;
        return Wx::Panel->new($self->parent->notebook, -1, wxDefaultPosition, wxDefaultSize);
    }#}}}
    sub _build_rdo_2412 {#{{{
        my $self = shift;
        my $v = Wx::RadioBox->new(
            $self->pnl_main, -1, 
            "Clock Hour", 
            wxDefaultPosition, 
            Wx::Size->new(100,40), 
            ['12', '24'],
            1, 
            wxRA_SPECIFY_ROWS
        );
        $v->SetSize( $v->GetBestSize );

        if( my $current_clock = wxTheApp->clock_type ) {
            $v->SetStringSelection($current_clock);
        }

        return $v;
    }#}}}
    sub _build_szr_grid {#{{{
        my $self = shift;

        ### 3 rows, 4 cols, 5px vgap and hgap.
        ###
        ### First entire row needs to be spacers (for top margin).  Each 
        ### individual row needs a spacer as the first column (for left 
        ### margin).
        my $szr_grid = Wx::FlexGridSizer->new(3, 4, 5, 5);

        return $szr_grid;
    }#}}}
    sub _build_tz_categories {#{{{
        my $self = shift;
        return [ "Select One", DateTime::TimeZone->categories ],
    }#}}}

    sub _parse_current_tz {#{{{
        my $self = shift;

        if( my $current_tz = wxTheApp->time_zone ) {
            my $current_tz_name = $current_tz->name;
            my( $cat, $tz ) = split '/', $current_tz_name, 2;
            $self->current_category( $cat );
            $self->current_tz_name( $tz || q{} );
        };
    }#}}}
    sub _build_current_category {#{{{
        my $self = shift;
        $self->_parse_current_tz();
        $self->current_category;
    }#}}}
    sub _build_current_tz_name {#{{{
        my $self = shift;
        $self->_parse_current_tz();
        $self->current_tz_name;
    }#}}}

    sub set_tzs_from_category {#{{{
        my $self    = shift;

        my $tz_cat = $self->chc_tz_category->GetStringSelection;
        my @names  = DateTime::TimeZone->names_in_category($tz_cat);

        $self->chc_tz->Clear();
        foreach my $n(@names) {
            $self->chc_tz->Append($n);
        }

        if( my $tz_name = $self->current_tz_name ) {
            $self->chc_tz->SetStringSelection($tz_name);
        }

        return 1;
    }#}}}

    sub OnChooseTZ {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;

        ### Nothing to do here.

        return 1;
    }#}}}
    sub OnChooseTZCategory {#{{{
        my $self    = shift;
        $self->set_tzs_from_category;
        return 1;
    }#}}}
    sub OnRadio2412 {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;

        ### Nothing to do here.

        return 1;
    }#}}}
    sub OnSavePrefs {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;

        my $schema = wxTheApp->main_schema;

        if( my $tz = $self->chc_tz->GetStringSelection ) {
            my $tz_cat  = $self->chc_tz_category->GetStringSelection;
            my $fqtz    = join '/', ($tz_cat, $tz);
            my $rec     = $schema->resultset('AppPrefsKeystore')->find_or_create({ name => 'TimeZone' });
            $rec->value( $fqtz );
            $rec->update;
            wxTheApp->time_zone( $fqtz );
        }

        if( my $type = $self->rdo_2412->GetString($self->rdo_2412->GetSelection) ) {
            my $rec = $schema->resultset('AppPrefsKeystore')->find_or_create({ name => 'ClockType' });
            $rec->value( $type );
            $rec->update;
            wxTheApp->clock_type( $type );
        }

        wxTheApp->popmsg("Your preferences have been saved.", 'Success!' );
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
