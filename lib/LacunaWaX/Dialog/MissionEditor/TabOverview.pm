
package LacunaWax::Dialog::MissionEditor::TabOverview {
    use v5.14;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_COMBOBOX);

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::Dialog::MissionEditor',
        required    => 1,
    );

    #################################

    has 'pnl_main' => (
        is          => 'rw',
        isa         => 'Wx::Panel',
        lazy_build  => 1,
    );

    has [qw( lbl_instructions lbl_name lbl_description lbl_net19 )] => (
        is          => 'rw',
        isa         => 'Wx::StaticText',
        lazy_build  => 1
    );

    has 'cmbo_name' => (
        is          => 'rw',
        isa         => 'Wx::ComboBox',
        lazy_build  => 1
    );

    has [qw( txt_description txt_net19 )] => (
        is          => 'rw',
        isa         => 'Wx::TextCtrl',
        lazy_build  => 1
    );

    has [qw( btn_delete btn_save )] => (
        is          => 'rw',
        isa         => 'Wx::Button',
        lazy_build  => 1
    );

    has 'new_rec_str' => (
        is          => 'rw',
        isa         => 'Str',
        default     => 'NEW',
        documentation => q{
            The string displayed in the name combo box indicating "create a new record".
        }
    );

    has 'szr_main' => (
        is          => 'rw',
        isa         => 'Wx::Sizer',
        lazy_build  => 1
    );

    has [qw(szr_button_grid szr_data_grid) ] => (
        is          => 'rw',
        isa         => 'Wx::FlexGridSizer',
        lazy_build  => 1
    );

    sub BUILD {
        my $self = shift;

        $self->szr_data_grid->Add( $self->lbl_name );
        $self->szr_data_grid->Add( $self->cmbo_name );
        $self->szr_data_grid->Add( $self->lbl_description );
        $self->szr_data_grid->Add( $self->txt_description );
        $self->szr_data_grid->Add( $self->lbl_net19 );
        $self->szr_data_grid->Add( $self->txt_net19 );

        $self->szr_button_grid->Add( $self->btn_save );
        $self->szr_button_grid->Add( $self->btn_delete );

        $self->szr_main->AddSpacer(20);
        $self->szr_main->Add( $self->lbl_instructions );
        $self->szr_main->Add( $self->szr_data_grid );
        $self->szr_main->AddSpacer(20);
        $self->szr_main->Add( $self->szr_button_grid );

        $self->pnl_main->SetSizer( $self->szr_main );
        $self->_set_events;

        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON(     $self->pnl_main,  $self->btn_delete->GetId,   sub{$self->parent->OnDelete(@_)}  );
        EVT_BUTTON(     $self->pnl_main,  $self->btn_save->GetId,     sub{$self->parent->OnSave(@_)}    );
        EVT_COMBOBOX(   $self->pnl_main,  $self->cmbo_name->GetId,    sub{$self->OnNameCombo(@_)}       );
        return 1;
    }#}}}

    sub _build_btn_delete {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->pnl_main, -1, "Delete");
        $v->Enable(0);
        return $v;
    }#}}}
    sub _build_btn_save {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->pnl_main, -1, "Save");
        return $v;
    }#}}}
    sub _build_lbl_instructions {#{{{
        my $self = shift;

        my $inst = "INSTRUCTIONS GO HERE.";

        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            $inst, 
            wxDefaultPosition, 
            Wx::Size->new(365,25)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_lbl_name {#{{{
        my $self = shift;

        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            'Name:',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1)
        );
        $v->SetFont( wxTheApp->get_font('header_4') );
        return $v;
    }#}}}
    sub _build_lbl_description {#{{{
        my $self = shift;

        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            'Description:',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1)
        );
        $v->SetFont( wxTheApp->get_font('header_4') );
        return $v;
    }#}}}
    sub _build_lbl_net19 {#{{{
        my $self = shift;

        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            'Network 19:',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1)
        );
        $v->SetFont( wxTheApp->get_font('header_4') );
        $v->SetToolTip('Text to be broadcast on Network 19 upon completion of mission');
        return $v;
    }#}}}
    sub _build_pnl_main {#{{{
        my $self = shift;
        my $v = Wx::Panel->new($self->parent->notebook, -1, wxDefaultPosition, wxDefaultSize);
        return $v;
    }#}}}
    sub _build_szr_data_grid {#{{{
        my $self = shift;
        my $v = Wx::FlexGridSizer->new( 3, 2, 5, 5 );
        return $v;
    }#}}}
    sub _build_szr_button_grid {#{{{
        my $self = shift;
        my $v = Wx::FlexGridSizer->new( 1, 2, 5, 5 );
        return $v;
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;
        my $v = Wx::BoxSizer->new(wxVERTICAL);
        return $v;
    }#}}}
    sub _build_cmbo_name {#{{{
        my $self = shift;

        my $schema = wxTheApp->main_schema;
        my $rs = $schema->resultset('Mission')->search();
        my $names = [ $self->new_rec_str ];
        while( my $r = $rs->next ) {
            push @{$names}, $r->name;
        }

        my $v = Wx::ComboBox->new(
            $self->pnl_main, -1,
            q{},
            wxDefaultPosition, Wx::Size->new(300,-1),
            $names,
            wxCB_SORT
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );

        return $v;
    }#}}}
    sub _build_txt_description {#{{{
        my $self = shift;

        my $v = Wx::TextCtrl->new(
            $self->pnl_main, -1,
            q{},
            wxDefaultPosition, Wx::Size->new(300,150),
            wxTE_MULTILINE
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_txt_net19 {#{{{
        my $self = shift;

        my $v = Wx::TextCtrl->new(
            $self->pnl_main, -1,
            q{},
            wxDefaultPosition, Wx::Size->new(300,150),
            wxTE_MULTILINE
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->SetToolTip('Text to be broadcast on Network 19 upon completion of mission');
        return $v;
    }#}}}

    sub OnNameCombo {#{{{
        my $self = shift;

        my $name  = $self->cmbo_name->GetValue;
        my $desc  = $self->txt_description->GetValue;
        my $net19 = $self->txt_net19->GetValue;

        if( $desc or $net19 ) {
            ### Don't check if $name is set.  We got here by the user changing 
            ### it, so it definitely will be set.
            if( wxNO == wxTheApp->popconf('Start/open a new mission.  Unsaved progress will be lost; continue?') ) {
                return;
            }
        }

        if( $name eq $self->new_rec_str ) {
            $self->parent->reset();
            return;
        }

        my $schema  = wxTheApp->main_schema;
        my $rs      = $schema->resultset('Mission')->search({ name => $name });
        my $rec     = $rs->next;
        $self->parent->current_mission( $rec );
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
