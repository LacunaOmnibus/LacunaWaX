
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

    has [qw( lbl_instructions lbl_name lbl_description lbl_net19_head lbl_net19_complete )] => (
        is          => 'rw',
        isa         => 'Wx::StaticText',
        lazy_build  => 1,
    );

    has 'cmbo_name' => (
        is          => 'rw',
        isa         => 'Wx::ComboBox',
        lazy_build  => 1,
    );

    has [qw( txt_width txt_height )] => (
        is          => 'rw',
        isa         => 'Int',
        lazy_build  => 1,
    );

    has [qw( txt_description txt_net19_head txt_net19_complete )] => (
        is          => 'rw',
        isa         => 'Wx::TextCtrl',
        lazy_build  => 1,
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

        $self->update_cmbo_name();

        $self->szr_data_grid->Add( $self->lbl_name );
        $self->szr_data_grid->Add( $self->cmbo_name );
        $self->szr_data_grid->Add( $self->lbl_description );
        $self->szr_data_grid->Add( $self->txt_description );
        $self->szr_data_grid->Add( $self->lbl_net19_head );
        $self->szr_data_grid->Add( $self->txt_net19_head );
        $self->szr_data_grid->Add( $self->lbl_net19_complete );
        $self->szr_data_grid->Add( $self->txt_net19_complete );

        $self->szr_main->AddSpacer(20);
        $self->szr_main->Add( $self->lbl_instructions );
        $self->szr_main->Add( $self->szr_data_grid );
        $self->szr_main->AddSpacer(20);
        $self->szr_main->Add( $self->szr_button_grid );

        $self->pnl_main->SetSizer( $self->szr_main );
        $self->_set_events;

        ### SetFocus on cmbo_name is happening in our parent MissionEditor.

        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_COMBOBOX(   $self->pnl_main,  $self->cmbo_name->GetId,    sub{$self->OnNameCombo(@_)}       );
        return 1;
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
    sub _build_lbl_net19_complete {#{{{
        my $self = shift;

        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            "Network 19\nCompletion:",
            wxDefaultPosition, 
            Wx::Size->new(-1,-1)
        );
        $v->SetFont( wxTheApp->get_font('header_4') );
        $v->SetToolTip('Text to be broadcast on Network 19 upon completion of mission');
        return $v;
    }#}}}
    sub _build_lbl_net19_head {#{{{
        my $self = shift;

        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            "Network 19\nHeadline:",
            wxDefaultPosition, 
            Wx::Size->new(-1,-1)
        );
        $v->SetFont( wxTheApp->get_font('header_4') );
        $v->SetToolTip('Network 19 headline');
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

        my $v = Wx::ComboBox->new(
            $self->pnl_main, -1,
            q{},
            wxDefaultPosition, Wx::Size->new($self->txt_width,-1),
            [],
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
            wxDefaultPosition, Wx::Size->new($self->txt_width,$self->txt_height),
            wxTE_MULTILINE
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_txt_net19_complete {#{{{
        my $self = shift;

        my $v = Wx::TextCtrl->new(
            $self->pnl_main, -1,
            q{},
            wxDefaultPosition, Wx::Size->new($self->txt_width,$self->txt_height),
            wxTE_MULTILINE
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->SetToolTip('Text to be broadcast on Network 19 upon completion of mission');
        return $v;
    }#}}}
    sub _build_txt_net19_head {#{{{
        my $self = shift;

        my $v = Wx::TextCtrl->new(
            $self->pnl_main, -1,
            q{},
            wxDefaultPosition, Wx::Size->new($self->txt_width,$self->txt_height),
            wxTE_MULTILINE
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        $v->SetToolTip('Network 19 headline');
        return $v;
    }#}}}
    sub _build_txt_width {#{{{
        return 400;
    }#}}}
    sub _build_txt_height {#{{{
        return 150;
    }#}}}

    sub clear_all {#{{{
        my $self = shift;
        $self->cmbo_name->SetValue(q{});
        $self->txt_description->SetValue(q{});
        $self->txt_net19_head->SetValue(q{});
        $self->txt_net19_complete->SetValue(q{});
        return 1;
    }#}}}
    sub update_cmbo_name {#{{{
        my $self = shift;

        ### Fills the combo box with mission names as they exist in the 
        ### database right now.

        $self->cmbo_name->Clear;

        my $schema = wxTheApp->main_schema;
        my $rs = $schema->resultset('Mission')->search({}, {order_by => 'name'});
        $self->cmbo_name->Append( $self->new_rec_str );
        while( my $r = $rs->next ) {
            $self->cmbo_name->Append( $r->name );
        }

        return 1;
    }#}}}

    sub OnNameCombo {#{{{
        my $self = shift;

        my $name  = $self->cmbo_name->GetValue;
        my $desc  = $self->txt_description->GetValue;
        my $net19 = $self->txt_net19_head->GetValue;

        $self->parent->reset();
        return if $name eq $self->new_rec_str;

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
