
=pod

Sample Missions (well, the public repo of all missions)
https://github.com/plainblack/Lacuna-Mission

The test code may help a bit with it, but they're all json files.

The old mission editor didn't deal with quantity, or berth levels. I had a quick json parser rebuild the missions for me to replace repetitive objectives with a version with the quantity field.

In the server code, insights can be found with bin/add_missions.pl and lib/Lacuna/DB/Result/Mission.pm

Hope that can get you started, I'll be on later today for any questions.

-N

=cut

### CHECK
### Lists of ships and plans for the Wx::Choices may not be complete; revisit 
### those!

### CHECK
### Need to get exhaustive list of star color names

package LacunaWaX::Dialog::MissionEditor {
    use v5.14;
    use JSON;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE EVT_NOTEBOOK_PAGE_CHANGED);

    extends 'LacunaWaX::Dialog::NonScrolled';

    use LacunaWaX::Dialog::MissionEditor::TabOverview;
    use LacunaWaX::Dialog::MissionEditor::TabMateriel;
    use LacunaWaX::Dialog::MissionEditor::TabFleet;
    use LacunaWaX::Dialog::MissionEditor::TabReward;

    has [qw(width height)] => (
        is          => 'rw',
        isa         => 'Int',
        lazy_build  => 1
    );

    has [qw( btn_delete btn_export btn_save )] => (
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

    has 'tab_materiel' => (
        is          => 'rw', 
        isa         => 'LacunaWax::Dialog::MissionEditor::TabMateriel',
        lazy_build  => 1,
    );

    has 'tab_fleet' => (
        is          => 'rw', 
        isa         => 'LacunaWax::Dialog::MissionEditor::TabFleet',
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
        $self->notebook->AddPage( $self->tab_materiel->pnl_main, "Objectives - Materiel" );
        $self->notebook->AddPage( $self->tab_fleet->pnl_main, "Objectives - Fleet" );
        $self->notebook->AddPage( $self->tab_reward->pnl_main, "Rewards" );

        $self->szr_buttons->Add( $self->btn_save );
        $self->szr_buttons->Add( $self->btn_export );
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
        EVT_BUTTON(                 $self->dialog,  $self->btn_export->GetId,   sub{$self->OnExport(@_)}    );
        EVT_BUTTON(                 $self->dialog,  $self->btn_save->GetId,     sub{$self->OnSave(@_)}      );
        EVT_CLOSE(                  $self->dialog,                              sub{$self->OnClose(@_)}     );
        EVT_NOTEBOOK_PAGE_CHANGED(  $self->dialog, $self->notebook->GetId,      sub{$self->OnTabChange(@_)} );
        return 1;
    }#}}}

    sub _build_btn_delete {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->dialog, -1, "Delete");
        $v->SetToolTip("Permanently deletes the current mission.  Irreversable.");
        $v->Enable(0);
        return $v;
    }#}}}
    sub _build_btn_export {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->dialog, -1, "Export");
        $v->SetToolTip("Exports current mission to a file to be uploaded.");
        $v->Enable(0);
        return $v;
    }#}}}
    sub _build_btn_save {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->dialog, -1, "Save");
        $v->SetToolTip("Saves current mission to database so you can finish it later.");
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
    sub _build_tab_fleet {#{{{
        my $self = shift;

        my $v = LacunaWax::Dialog::MissionEditor::TabFleet->new( parent => $self );
        return $v;
    }#}}}
    sub _build_tab_overview {#{{{
        my $self = shift;

        my $v = LacunaWax::Dialog::MissionEditor::TabOverview->new( parent => $self );
        return $v;
    }#}}}
    sub _build_tab_materiel {#{{{
        my $self = shift;

        my $v = LacunaWax::Dialog::MissionEditor::TabMateriel->new( parent => $self );
        return $v;
    }#}}}
    sub _build_tab_reward {#{{{
        my $self = shift;

        my $v = LacunaWax::Dialog::MissionEditor::TabReward->new( parent => $self );
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
        $self->btn_export->Enable(0);

        $self->tab_overview->clear_all;
        $self->tab_materiel->clear_all;
        $self->tab_fleet->clear_all;
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
        $self->btn_export->Enable(1);
        $self->main_sizer->Layout();
        wxTheApp->Yield();

        $self->tab_overview->cmbo_name->SetValue( $self->current_mission->name );
        $self->tab_overview->txt_description->SetValue( $self->current_mission->description );
        $self->tab_overview->txt_net19_head->SetValue( $self->current_mission->net19_head );
        $self->tab_overview->txt_net19_complete->SetValue( $self->current_mission->net19_complete );
        $self->tab_overview->spin_max_university->SetValue( $self->current_mission->max_university );
        wxTheApp->Yield();

        ### Materiel
        my $mo_rs = $self->current_mission->materiel_objective( {}, {order_by => {-asc => 'type'}} );
        while( my $mo_rec = $mo_rs->next ) {
            wxTheApp->Yield();
            $self->tab_materiel->add_materiel_row( $mo_rec );
        }
        $self->tab_materiel->swin_main->FitInside();

        ### Fleet
        my $fo_rs = $self->current_mission->fleet_objective( {}, {order_by => {-asc => 'ship_type'}} );
        while( my $fo_rec = $fo_rs->next ) {
            wxTheApp->Yield();
            $self->tab_fleet->add_fleet_row( $fo_rec );
        }
        $self->tab_materiel->swin_main->FitInside();

        ### Reward
        my $reward_rs = $self->current_mission->reward( {}, {order_by => {-asc => 'type'}} );
        while( my $reward_rec = $reward_rs->next ) {
            wxTheApp->Yield();
            $self->tab_reward->add_reward_row( $reward_rec );
        }
        $self->tab_reward->swin_main->FitInside();

        wxTheApp->endthrob;
        $self->notebook->Enable(1);
        return 1;
    }#}}}
    sub materiel_hash_for_export {#{{{
        my $self    = shift;
        my $rec     = shift;
        my $rel     = shift;

        my $bldg_classes    = wxTheApp->building_types('human_to_class');
        my $ship_urls       = wxTheApp->ship_types('human_to_url');
        
        my $obj = {};
        my $mat_obj_rs = $rec->search_related($rel, {});
        while(my $m = $mat_obj_rs->next ) {
            wxTheApp->Yield();
            if( $m->type eq 'essentia' or $m->type eq 'happiness' ) {
                $obj->{$m->type} = $m->quantity;
            }
            elsif( $m->type eq 'glyphs' ) {
                push @{$obj->{'glyphs'}}, {
                    type => (lc $m->name),
                    quantity => $m->quantity,
                }
            }
            elsif( $m->type eq 'plans' ) {
                push @{$obj->{'plans'}}, {
                    level               => $m->level,
                    extra_build_level   => $m->extra_level,
                    quantity            => $m->quantity,
                    classname           => $bldg_classes->{$m->name},
                }
            }
            elsif( $m->type eq 'resources' ) {
                $obj->{'resources'}->{lc $m->name} = $m->quantity;
            }
            elsif( $m->type eq 'ships' ) {
                push @{$obj->{'ships'}}, {
                    ### 'name' is the name of the resource; bean, bauxite, 
                    ### Smuggler Ship, etc.  ship_name is the (wildly) 
                    ### optional name of the ship, usually used only for 
                    ### specific special reward ships (eg Andecui Smuggler)
                    ###
                    ### Ship type (again, $m->name), is coming to us as the 
                    ### human version ('Smuggler Ship').  The mission file 
                    ### needs the url version ('smuggler_ship').  Ugh.
                    ###
                    ### I can't find any example mission files that have an 
                    ### 'occupants' entry at all, but I'm including it anyway.  
                    ### I doubt that having it there will hurt anything if 
                    ### it's not expected.
                    name        => $m->ship_name || $m->name,
                    type        => $ship_urls->{$m->name},
                    berth_level => $m->berth,
                    combat      => $m->combat,
                    hold_size   => $m->cargo,
                    quantity    => $m->quantity,
                    speed       => $m->speed,
                    stealth     => $m->stealth,
                    occupants   => $m->occupants,
                }
            }
        }

        return $obj;
    }#}}}
    sub fleet_hash_for_export {#{{{
        my $self    = shift;
        my $rec     = shift;
        my $rel     = shift;

        my $ship_urls = wxTheApp->ship_types('human_to_url');

        my $fleet = [];
        my $fleet_obj_rs = $rec->search_related($rel, {});
        while(my $m = $fleet_obj_rs->next ) {
            wxTheApp->Yield();
            push @{$fleet}, {
                    ### $m->ship_type is human ('Smuggler Ship').
                    ship_type       => $ship_urls->{$m->ship_type},
                    ship_quantity   => $m->ship_quantity || 1,
                    target => {
                        color           => $m->targ_color || 'any',
                        in_zone         => $m->targ_in_zone,
                        inhabited       => $m->targ_inhabited,
                        isolationist    => $m->targ_isolationist,
                        size            => [ $m->targ_size_min, $m->targ_size_max ],
                        ### $m->targ_type is human ('Gas Giant')
                        type            => wxTheApp->underscore_case( $m->targ_type ),
                    },
            }
        }

        return $fleet;
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

        unless( wxYES == wxTheApp->popconf("Delete this mission - this is irreversable!  Are you sure?") ) {
            return;
        }

        $self->current_mission->delete;
        $self->tab_overview->update_cmbo_name();
        $self->reset;
        return 1;
    }#}}}
    sub OnExport {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;

        return unless $self->has_current_mission;
        wxTheApp->throb;

        my $rec = $self->current_mission;
        my $mission = {
            name                    => $rec->name,
            description             => $rec->description,
            max_university_level    => $rec->max_university,
            network_19_head         => $rec->net19_head,
            network_19_completion   => $rec->net19_complete,
        };

        my $mission_objective_hr    = $self->materiel_hash_for_export( $rec, 'materiel_objective' );
        my $reward_hr               = $self->materiel_hash_for_export( $rec, 'reward' );
        my $fleet_movement_ar       = $self->fleet_hash_for_export(    $rec, 'fleet_objective' );

        if( scalar @$fleet_movement_ar ) {
            ### Ack.  Materiel objectives and fleet movement objectives are 
            ### not separate; the one contains the other.
            $mission_objective_hr->{'fleet_movement'} = $fleet_movement_ar;
            wxTheApp->Yield();
        }

        $mission->{'mission_objective'} = $mission_objective_hr;
        $mission->{'mission_reward'} = $reward_hr;
        wxTheApp->endthrob;

        my $output_name = wxTheApp->underscore_case($rec->name) . ".mission";
        my $file_browser = Wx::FileDialog->new(
            $self->dialog,
            'Export mission to file',
            $ENV{'HOME'},       # default dir
            $output_name,       # default file
            q{*.mission},
            wxFD_SAVE|wxFD_OVERWRITE_PROMPT
        );
        if( $file_browser->ShowModal() == wxID_CANCEL ) {
            return;
        }

        my $json = JSON->new();
        $json->pretty(1);
        my $encoded = $json->encode($mission);
        my $dest_file = join '/', ($file_browser->GetDirectory, $file_browser->GetFilename);
        my $fh;
        try { open $fh, '>', $dest_file; }
        catch{ wxTheApp->poperr("Unable to open mission file: $_"); return };
        say $fh "# config-file-type: JSON 1";
        print $fh $encoded;
        close $fh;

        wxTheApp->popmsg("Mission saved in $dest_file.");

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
        while( my($uuid, $res_row) = each %{ $self->tab_materiel->res_rows } ) {
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

        ### Get our mission record (or create a new one); set overview values
        my $mission_rec = $schema->resultset('Mission')->find_or_create(
            { name => $self->tab_overview->cmbo_name->GetValue },
            { key => 'mission_name' }
        );
        $mission_rec->description(      $self->tab_overview->txt_description->GetValue      );
        $mission_rec->net19_head(       $self->tab_overview->txt_net19_head->GetValue       );
        $mission_rec->net19_complete(   $self->tab_overview->txt_net19_complete->GetValue   );
        $mission_rec->max_university(   $self->tab_overview->spin_max_university->GetValue  );

        ### Clear out all related records.
        $mission_rec->delete_related('materiel_objective');
        $mission_rec->delete_related('fleet_objective');
        $mission_rec->delete_related('reward');

        ### Add materiel objectives
        while( my($uuid, $res_row) = each %{ $self->tab_materiel->res_rows } ) {
            wxTheApp->Yield;
            my $type = $res_row->chc_entity_type->GetStringSelection;
            next if $type eq 'SELECT';
            $mission_rec->create_related('materiel_objective', {
                type        => $type,
                name        => $res_row->chc_entity_name->GetStringSelection,
                quantity    => $res_row->spin_quantity->GetValue,
                level       => $res_row->spin_level->GetValue,
                extra_level => $res_row->spin_extra_level->GetValue,
                ship_name   => $res_row->txt_ship_name->GetValue || q{},
                berth       => $res_row->spin_min_berth->GetValue,
                cargo       => $res_row->spin_min_cargo->GetValue,
                combat      => $res_row->spin_min_combat->GetValue,
                occupants   => $res_row->spin_min_occupants->GetValue,
                speed       => $res_row->spin_min_speed->GetValue,
                stealth     => $res_row->spin_min_stealth->GetValue,
            })
        }

        ### Add fleet objectives
        while( my($uuid, $fleet_row) = each %{ $self->tab_fleet->fleet_rows } ) {
            wxTheApp->Yield;

            my $type = $fleet_row->chc_ship_type->GetStringSelection;
            next if $type eq 'SELECT';

            my $targ_in_zone        = ( lc $fleet_row->rdo_in_zone->GetStringSelection      eq 'yes' ) ? 1 : 0;
            my $targ_inhabited      = ( lc $fleet_row->rdo_inhabited->GetStringSelection    eq 'yes' ) ? 1 : 0;
            my $targ_isolationist   = ( lc $fleet_row->rdo_isolationist->GetStringSelection eq 'yes' ) ? 1 : 0;

            $mission_rec->create_related('fleet_objective', {
                ship_type           => $type,
                ship_quantity       => $fleet_row->spin_ship_quantity->GetValue,
                targ_type           => $fleet_row->chc_target_type->GetStringSelection,
                targ_size_min       => $fleet_row->spin_size_min->GetValue,
                targ_size_max       => $fleet_row->spin_size_max->GetValue,
                targ_in_zone        => $targ_in_zone,
                targ_inhabited      => $targ_inhabited,
                targ_isolationist   => $targ_isolationist,
                targ_color          => $fleet_row->chc_target_color->GetStringSelection,
            })
        }

        ### Add rewards
        while( my($uuid, $res_row) = each %{ $self->tab_reward->res_rows } ) {
            wxTheApp->Yield;
            my $type = $res_row->chc_entity_type->GetStringSelection;
            next if $type eq 'SELECT';
            $mission_rec->create_related('reward', {
                type        => $type,
                name        => $res_row->chc_entity_name->GetStringSelection,
                quantity    => $res_row->spin_quantity->GetValue,
                level       => $res_row->spin_level->GetValue,
                extra_level => $res_row->spin_extra_level->GetValue,
                ship_name   => $res_row->txt_ship_name->GetValue || q{},
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
