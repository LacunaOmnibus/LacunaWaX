
=pod

Sample Missions (well, the public repo of all missions)
https://github.com/plainblack/Lacuna-Mission

The test code may help a bit with it, but they're all json files.

The old mission editor didn't deal with quantity, or berth levels. I had a quick json parser rebuild the missions for me to replace repetitive objectives with a version with the quantity field.

In the server code, insights can be found with bin/add_missions.pl and lib/Lacuna/DB/Result/Mission.pm

Hope that can get you started, I'll be on later today for any questions.

-N

=cut

package LacunaWaX::Dialog::MissionEditor {
    use v5.14;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE EVT_NOTEBOOK_PAGE_CHANGED);

    extends 'LacunaWaX::Dialog::NonScrolled';

    use LacunaWaX::Dialog::MissionEditor::TabOverview;
    use LacunaWaX::Dialog::MissionEditor::TabMateriel;
    use LacunaWaX::Dialog::MissionEditor::TabReward;

    has [qw(width height)] => (
        is          => 'rw',
        isa         => 'Int',
        lazy_build  => 1
    );

    has [qw( btn_delete btn_save )] => (
        is          => 'rw',
        isa         => 'Wx::Button',
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

    has 'szr_buttons' => (
        is          => 'rw',
        isa         => 'Wx::Sizer', # horizontal
        lazy_build  => 1
    );

    has 'tab_overview' => (
        is              => 'rw', 
        isa             => 'LacunaWax::Dialog::MissionEditor::TabOverview',
        lazy_build      => 1,
    );

    has 'tab_objective' => (
        is          => 'rw', 
        isa         => 'LacunaWax::Dialog::MissionEditor::TabMateriel',
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
        $self->notebook->AddPage( $self->tab_objective->pnl_main, "Objectives - Materiel" );
        $self->notebook->AddPage( $self->tab_reward->pnl_main, "Rewards" );

        $self->szr_buttons->Add( $self->btn_save );
        $self->szr_buttons->Add( $self->btn_delete );

        $self->main_sizer->AddSpacer(5);
        $self->main_sizer->Add($self->notebook, 1, wxEXPAND, 0);
        $self->main_sizer->AddSpacer(5);
        $self->main_sizer->Add($self->szr_buttons, 0, 0, 0);

        $self->_set_events();
        $self->init_screen();
        $self->tab_overview->cmbo_name->SetFocus();
        return $self;
    };
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON(                 $self->dialog,  $self->btn_delete->GetId,   sub{$self->OnDelete(@_)}    );
        EVT_BUTTON(                 $self->dialog,  $self->btn_save->GetId,     sub{$self->OnSave(@_)}      );
        EVT_CLOSE(                  $self->dialog,                              sub{$self->OnClose(@_)}     );
        EVT_NOTEBOOK_PAGE_CHANGED(  $self->dialog, $self->notebook->GetId,      sub{$self->OnTabChange(@_)} );
        return 1;
    }#}}}

    sub _build_btn_delete {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->dialog, -1, "Delete");
        $v->Enable(0);
        return $v;
    }#}}}
    sub _build_btn_save {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->dialog, -1, "Save");
        return $v;
    }#}}}
    sub _build_height {#{{{
        return 750;
    }#}}}
    sub _build_width {#{{{
        return 700;
    }#}}}
    sub _build_notebook {#{{{
        my $self = shift;

        ### Wx on Windows looks somewhat different from Wx on Linux, and needs 
        ### some more space to be sure everything is visible
        my($subw, $subh) = ($^O eq 'MSWin32') ? (17, 70) : (10, 50);
        my $v = Wx::Notebook->new(
            $self->dialog, -1, 
            wxDefaultPosition, 
            Wx::Size->new( $self->width - $subw, $self->height - $subh ),
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

        my $v = LacunaWax::Dialog::MissionEditor::TabMateriel->new(
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
    sub _build_szr_buttons {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->dialog, wxHORIZONTAL, 'Buttons');
        return $v;
    }#}}}
    sub _build_title {#{{{
        my $self = shift;
        return 'Sitter Manager';
    }#}}}

    sub reset {#{{{
        my $self = shift;

        ### Clear everything on all tabs; user wants to start creating a new 
        ### mission.

        $self->clear_current_mission;
        $self->btn_delete->Enable(0);

        $self->tab_overview->clear_all;
        $self->tab_objective->clear_all;
        $self->tab_reward->clear_all;
    }#}}}
    sub update_current_mission {#{{{
        my $self = shift;

        $self->notebook->Enable(0);
        wxTheApp->throb;

        ### A new mission has been selected.  Set all of the inputs on all 
        ### tabs with data from that mission.  Triggered when 
        ### $self->current_mission changes.

        $self->btn_delete->Enable(1);
        $self->main_sizer->Layout();
        wxTheApp->Yield();

        $self->tab_overview->cmbo_name->SetValue( $self->current_mission->name );
        $self->tab_overview->txt_description->SetValue( $self->current_mission->description );
        $self->tab_overview->txt_net19_head->SetValue( $self->current_mission->net19_head );
        $self->tab_overview->txt_net19_complete->SetValue( $self->current_mission->net19_complete );
        wxTheApp->Yield();

        my $mo_rs = $self->current_mission->material_objective( {}, {order_by => {-asc => 'type'}} );
        while( my $mo_rec = $mo_rs->next ) {
            wxTheApp->Yield();
            $self->tab_objective->add_material_row( $mo_rec );
        }
        $self->tab_objective->swin_main->FitInside();

        my $reward_rs = $self->current_mission->reward( {}, {order_by => {-asc => 'type'}} );
        while( my $reward_rec = $reward_rs->next ) {
            wxTheApp->Yield();
            $self->tab_reward->add_material_row( $reward_rec );
        }
        $self->tab_reward->swin_main->FitInside();

        wxTheApp->endthrob;
        $self->notebook->Enable(1);
        return 1;
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

        wxTheApp->throb;

        ### 
        ### Sanity-check inputs
        ### 

        ### Overview
        my %reqd = (
            tab_overview => {
                cmbo_name => 'Name',
                txt_description => 'Description',
                txt_net19_head => 'Network 19 Headline',
                txt_net19_complete => 'Network 19 Completion',
            },
        );
        while( my($pnl, $reqs) = each %reqd ) {
            while( my($input, $text) = each %{$reqs} ) {
                wxTheApp->Yield;
                unless( $self->$pnl->$input->GetValue ) {
                    wxTheApp->poperr( "$reqd{$pnl}->{$input} is required!", "Missing required field");
                    return;
                }
            }
        }

        ### Objective rows
        while( my($uuid, $res_row) = each %{ $self->tab_objective->res_rows } ) {
            my $type = $res_row->chc_entity_type->GetStringSelection;
            my $name = $res_row->chc_entity_name->GetStringSelection;
            my $quan = $res_row->spin_quantity->GetValue;
            if( grep{ $_ eq $type}qw(glyphs plans resources ships) ) {
                wxTheApp->Yield;
                unless( $name and $quan ) {
                    wxTheApp->poperr("Name and quantity are required when specifying $type");
                    return;
                }
            }
        }

        ### 
        ### Sanity checks complete; add the records
        ### 


        my $schema = wxTheApp->main_schema;

        ### Get our mission record (or create a new one)
        my $mission_rec = $schema->resultset('Mission')->find_or_create(
            { name => $self->tab_overview->cmbo_name->GetValue },
            { key => 'mission_name' }
        );
        $mission_rec->description(      $self->tab_overview->txt_description->GetValue      );
        $mission_rec->net19_head(       $self->tab_overview->txt_net19_head->GetValue       );
        $mission_rec->net19_complete(   $self->tab_overview->txt_net19_complete->GetValue   );

        ### Clear out all related records.
        $mission_rec->delete_related('material_objective');
        $mission_rec->delete_related('fleet_objective');
        $mission_rec->delete_related('reward');

        ### Add material objectives
        while( my($uuid, $res_row) = each %{ $self->tab_objective->res_rows } ) {
            wxTheApp->Yield;
            my $type = $res_row->chc_entity_type->GetStringSelection;
            next if $type eq 'SELECT';
            $mission_rec->create_related('material_objective', {
                type        => $type,
                name        => $res_row->chc_entity_name->GetStringSelection,
                quantity    => $res_row->spin_quantity->GetValue,
                extra_level => $res_row->spin_extra_level->GetValue,
                berth       => $res_row->spin_min_berth->GetValue,
                cargo       => $res_row->spin_min_cargo->GetValue,
                combat      => $res_row->spin_min_combat->GetValue,
                occupants   => $res_row->spin_min_occupants->GetValue,
                speed       => $res_row->spin_min_speed->GetValue,
                stealth     => $res_row->spin_min_stealth->GetValue,
            })
        }

        ### Need to add fleet objectives here

        ### Add rewards
        while( my($uuid, $res_row) = each %{ $self->tab_reward->res_rows } ) {
            wxTheApp->Yield;
            my $type = $res_row->chc_entity_type->GetStringSelection;
            next if $type eq 'SELECT';
            $mission_rec->create_related('reward', {
                type        => $type,
                name        => $res_row->chc_entity_name->GetStringSelection,
                quantity    => $res_row->spin_quantity->GetValue,
                extra_level => $res_row->spin_extra_level->GetValue,
                berth       => $res_row->spin_min_berth->GetValue,
                cargo       => $res_row->spin_min_cargo->GetValue,
                combat      => $res_row->spin_min_combat->GetValue,
                occupants   => $res_row->spin_min_occupants->GetValue,
                speed       => $res_row->spin_min_speed->GetValue,
                stealth     => $res_row->spin_min_stealth->GetValue,
            })
        }

        wxTheApp->Yield;
        $mission_rec->update();
        wxTheApp->Yield;
        $self->tab_overview->update_cmbo_name();
        wxTheApp->endthrob;
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
