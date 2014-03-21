
package LacunaWaX::Dialog::MissionEditor {
    use v5.14;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_CLOSE EVT_NOTEBOOK_PAGE_CHANGED);

    extends 'LacunaWaX::Dialog::NonScrolled';

    use LacunaWaX::Dialog::MissionEditor::TabOverview;
    use LacunaWaX::Dialog::MissionEditor::TabObjective;
    #use LacunaWaX::Dialog::MissionEditor::TabReward;

    has [qw(width height)] => (
        is          => 'rw',
        isa         => 'Int',
        lazy_build  => 1
    );

    has 'current_mission' => (
        is          => 'rw',
        isa         => 'Maybe[LacunaWaX::Model::Schema::Mission]',
        clearer     => 'clear_current_mission',
        predicate   => 'has_current_mission',
        trigger     => sub{ my $self = shift; $self->update_current_mission },
    );

    has 'notebook' => (
        is          => 'rw',
        isa         => 'Wx::Notebook',
        lazy_build  => 1
    );

    has 'tab_overview' => (
        is              => 'rw', 
        isa             => 'LacunaWax::Dialog::MissionEditor::TabOverview',
        lazy_build      => 1,
    );

    has 'tab_objective' => (
        is          => 'rw', 
        isa         => 'LacunaWax::Dialog::MissionEditor::TabObjective',
        lazy_build  => 1,
    );

    has 'tab_reward' => (
        is          => 'rw', 
        isa         => 'LacunaWax::Dialog::MissionEditor::TabReward',
        lazy_build  => 1,
    );

    sub BUILD {
        my $self = shift;
    
        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers
        $self->SetTitle( $self->title );
        $self->SetSize( $self->size );

        $self->notebook->AddPage( $self->tab_overview->pnl_main, "Overview" );
        $self->notebook->AddPage( $self->tab_objective->pnl_main, "Objectives" );

        $self->main_sizer->AddSpacer(5);
        $self->main_sizer->Add($self->notebook, 1, wxEXPAND, 0);

        $self->_set_events();
        $self->init_screen();
        return $self;
    };
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE(                  $self,                          sub{$self->OnClose(@_)}     );
        EVT_NOTEBOOK_PAGE_CHANGED(  $self, $self->notebook->GetId,  sub{$self->OnTabChange(@_)} );
        return 1;
    }#}}}

    sub _build_height {#{{{
        return 750;
    }#}}}
    sub _build_width {#{{{
        return 700;
    }#}}}
    sub _build_notebook {#{{{
        my $self = shift;
        my $v = Wx::Notebook->new(
            $self->dialog, -1, 
            wxDefaultPosition, 
            Wx::Size->new( $self->width - 10, $self->height - 10 ),
            0
        );
        return $v;
    }#}}}
    sub _build_tab_overview {#{{{
        my $self = shift;

        my $v = LacunaWax::Dialog::MissionEditor::TabOverview->new(
            parent => $self
        );
        return $v;
    }#}}}
    sub _build_tab_objective {#{{{
        my $self = shift;

        my $v = LacunaWax::Dialog::MissionEditor::TabObjective->new(
            parent => $self
        );
        return $v;
    }#}}}
    sub _build_tab_reward {#{{{
        my $self = shift;

        my $v = LacunaWax::Dialog::MissionEditor::TabReward->new(
            parent => $self
        );
        return $v;
    }#}}}
    sub _build_size {#{{{
        my $self = shift;
        my $s = wxDefaultSize;
        $s->SetWidth( $self->width );
        $s->SetHeight( $self->height );
        return $s;
    }#}}}
    sub _build_title {#{{{
        my $self = shift;
        return 'Sitter Manager';
    }#}}}

    sub reset {#{{{
        my $self = shift;

        ### Clear everything; user wants to start creating a new mission.

        $self->clear_current_mission;

        $self->tab_overview->cmbo_name->SetValue(q{});
        $self->tab_overview->txt_description->SetValue(q{});
        $self->tab_overview->txt_net19->SetValue(q{});
        $self->tab_overview->btn_delete->Enable(0);
    }#}}}
    sub update_current_mission {#{{{
        my $self = shift;

        ### A new mission has been selected.  Set all of the text boxes with 
        ### data from that mission.

        $self->tab_overview->cmbo_name->SetValue( $self->current_mission->name );
        $self->tab_overview->txt_description->SetValue( $self->current_mission->description );
        $self->tab_overview->txt_net19->SetValue( $self->current_mission->net19 );
        $self->tab_overview->btn_delete->Enable(1);
    }#}}}

    sub OnClose {#{{{
        my($self, $dialog, $event) = @_;
        $self->Destroy;
        $event->Skip();
        return 1;
    }#}}}
    sub OnDelete {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;

        return unless $self->has_current_mission;
        $self->current_mission->delete;
        $self->tab_overview->update_cmbo_name();
        $self->reset;
        return 1;
    }#}}}
    sub OnSave {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;

        my $schema = wxTheApp->main_schema;

        ### CHECK
        ### all 3 of those columns are required, so sanity checking needs to 
        ### happen first, and the "|| q{}" need to all go away.
        $schema->resultset('Mission')->find_or_create(
            {
                name            => $self->tab_overview->cmbo_name->GetValue         || q{},
                description     => $self->tab_overview->txt_description->GetValue   || q{},
                net19           => $self->tab_overview->txt_net19->GetValue         || q{},
            },
            { key => 'mission_name' }
        );
        $self->tab_overview->update_cmbo_name();

        wxTheApp->popmsg("Mission Saved.");
        return 1;
    }#}}}
    sub OnTabChange {#{{{
        my $self    = shift;
        my $dialog  = shift;    # Wx::Dialog
        my $event   = shift;    # Wx::NotebookEvent

        ### Hits when the user switches tabs

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
