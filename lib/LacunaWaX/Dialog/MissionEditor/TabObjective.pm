
package LacunaWax::Dialog::MissionEditor::TabObjective {
    use v5.14;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_COMBOBOX);

    use LacunaWaX::Dialog::MissionEditor::ResourceRow;

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::Dialog::MissionEditor',
        required    => 1,
    );

    #################################

    has [qw( lbl_instructions )] => (
        is          => 'rw',
        isa         => 'Wx::StaticText',
        lazy_build  => 1
    );

    has 'pnl_main' => (
        is          => 'rw',
        isa         => 'Wx::Panel',
        lazy_build  => 1,
    );

    has 'szr_data_grid' => (
        is          => 'rw',
        isa         => 'Wx::FlexGridSizer',
        lazy_build  => 1
    );

    has 'szr_main' => (
        is          => 'rw',
        isa         => 'Wx::Sizer',
        lazy_build  => 1
    );

    has 'rows' => (
        is          => 'rw',
        isa         => 'ArrayRef[LacunaWaX::Dialog::MissionEditor::ResourceRow]',
        default     => sub{ [] },
    );

    sub BUILD {
        my $self = shift;

### Force a single bogus resource row until the ResourceRow class is properly 
### figured out.
push @{$self->rows}, LacunaWax::Dialog::MissionEditor::ResourceRow->new( parent => $self );
$self->szr_data_grid->Add( $self->rows->[0]->pnl_main );

        $self->szr_main->AddSpacer(20);
        $self->szr_main->Add( $self->lbl_instructions );
        $self->szr_main->Add( $self->szr_data_grid );

        $self->pnl_main->SetSizer( $self->szr_main );

        $self->_set_events;
        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        return 1;
    }#}}}

    sub _build_lbl_instructions {#{{{
        my $self = shift;

        my $inst = "OBJECTIVE INSTRUCTIONS GO HERE.";

        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            $inst, 
            wxDefaultPosition, 
            Wx::Size->new(365,25)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_pnl_main {#{{{
        my $self = shift;
        my $v = Wx::Panel->new($self->parent->notebook, -1, wxDefaultPosition, wxDefaultSize);
        return $v;
    }#}}}
    sub _build_szr_data_grid {#{{{
        my $self = shift;
        my $v = Wx::FlexGridSizer->new( 1, 1, 0, 5 );   # r, c, vgap, hgap
        return $v;
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;
        my $v = Wx::BoxSizer->new(wxVERTICAL);
        return $v;
    }#}}}

    sub add_row {
        my $self = shift;
        push @{$self->rows}, LacunaWax::Dialog::MissionEditor::ResourceRow->new( parent => $self );
        $self->szr_data_grid->Add( $self->rows->[0]->pnl_main );
    }


    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
