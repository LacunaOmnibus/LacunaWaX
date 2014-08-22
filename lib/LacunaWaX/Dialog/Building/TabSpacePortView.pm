
package LacunaWaX::Dialog::Building::TabSpacePortView {
    use v5.14;
    use Data::Dumper;
    use DateTime::TimeZone;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHOICE);

    use LacunaWaX::Generics::BldgUpgradeBar;

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::Dialog::Building',
        required    => 1,
    );

    has 'bldg_obj' => (
        is          => 'ro', 
        isa         => 'Object', 
        lazy_build  => 1,
    );

    has 'bldg_view' => (
        is          => 'ro', 
        isa         => 'HashRef', 
        lazy_build  => 1,
    );

    #################################

    has 'bldg_id' => (
        is          => 'ro', 
        isa         => 'Int', 
        lazy_build  => 1,
    );

    has 'pnl_main' => (
        is          => 'rw',
        isa         => 'Wx::Panel',
        lazy_build  => 1,
        documentation => q{
            The main wxwindow used as a parent for all our widgets.
        }
    );

    has 'tab_name' => (
        is  => 'rw', 
        isa => 'Str', 
    ### CHECK
        documentation => q{
            This MUST be set, and should really be part of either a Role or Parent from which we inherit.
        }
    );

    has 'btn_get_ships' => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1);
    has 'chc_tag'       => (is => 'rw', isa => 'Wx::Choice',        lazy_build => 1);
    has 'chc_task'      => (is => 'rw', isa => 'Wx::Choice',        lazy_build => 1);
    has 'chc_type'      => (is => 'rw', isa => 'Wx::Choice',        lazy_build => 1);
    has 'list_ships'    => (is => 'rw', isa => 'Wx::ListCtrl',      lazy_build => 1);
    has 'szr_main'      => (is => 'rw', isa => 'Wx::BoxSizer',      lazy_build => 1);
    has 'szr_filter'    => (is => 'rw', isa => 'Wx::BoxSizer',      lazy_build => 1);
    has 'pnl_main'      => (is => 'rw', isa => 'Wx::Panel',         lazy_build => 1);

    sub BUILD {
        my $self = shift;

        $self->tab_name( 'View' );

        $self->szr_filter->Add( $self->chc_tag, 0, 0, 0 );
        $self->szr_filter->AddSpacer(10);
        $self->szr_filter->Add( $self->chc_task, 0, 0, 0 );
        $self->szr_filter->AddSpacer(10);
        $self->szr_filter->Add( $self->chc_type, 0, 0, 0 );
        $self->szr_filter->AddSpacer(10);
        $self->szr_filter->Add( $self->btn_get_ships, 0, 0, 0 );

        ### Set the types choice to contain ships of whatever tag we've 
        ### decided to default to.
        $self->OnChangeTag();

        $self->szr_main->AddSpacer(10);
        $self->szr_main->Add( $self->szr_filter, 0, 0, 0 );
        $self->szr_main->AddSpacer(10);
        $self->szr_main->Add( $self->list_ships, 0, 0, 0 );

        $self->pnl_main->SetSizer( $self->szr_main );
        $self->_set_events;
        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON( $self->pnl_main, $self->btn_get_ships->GetId,   sub{$self->OnGetShips(@_)}  );
        EVT_CHOICE( $self->pnl_main, $self->chc_tag->GetId,         sub{$self->OnChangeTag(@_)}  );
        return 1;
    }#}}}

    sub _build_bldg_id {#{{{
        my $self = shift;
        return $self->bldg_hr->{'bldg_id'};
    }#}}}
    sub _build_btn_get_ships {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->pnl_main, -1, "Get Ships");
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_pnl_main {#{{{
        my $self = shift;
        return Wx::Panel->new($self->parent->ntbk_features, -1, wxDefaultPosition, wxDefaultSize);
    }#}}}
    sub _build_chc_tag {#{{{
        my $self = shift;
        my $v = Wx::Choice->new(
            $self->pnl_main, -1, 
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
            [qw(Colonization Exploration Intelligence Mining Trade War) ],
        );
        $v->SetStringSelection('Trade');
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_chc_task {#{{{
        my $self = shift;
        my $v = Wx::Choice->new(
            $self->pnl_main, -1, 
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
            [ 
                'Building', 'Defend', 'Docked', 'Mining', 'Orbiting', 
                'Supply Chain', 'Travelling', 'Waiting on Trade', 'Waste',
            ],
        );
        $v->SetStringSelection('Docked');
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_chc_type {#{{{
        my $self = shift;
        my $v = Wx::Choice->new(
            $self->pnl_main, -1, 
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
            [ q{} ],
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_list_ships {#{{{
        my $self = shift;
        wxTheApp->Yield;

        my $list_ctrl = Wx::ListCtrl->new(
            $self->pnl_main, -1, 
            wxDefaultPosition, 
            Wx::Size->new( 600, 400 ), 
            wxLC_REPORT
            |wxSUNKEN_BORDER
            |wxLC_SINGLE_SEL
        );
        $list_ctrl->InsertColumn(0, 'Type');
        $list_ctrl->InsertColumn(1, 'Name');
        $list_ctrl->InsertColumn(2, 'Speed');
        $list_ctrl->InsertColumn(3, 'Combat');
        $list_ctrl->InsertColumn(4, 'Hold');
        $list_ctrl->InsertColumn(5, 'Stealth');
        $list_ctrl->InsertColumn(6, 'Task');

        $list_ctrl->SetColumnWidth(0,75);
        $list_ctrl->SetColumnWidth(1,75);
        $list_ctrl->SetColumnWidth(2,75);
        $list_ctrl->SetColumnWidth(3,75);
        $list_ctrl->SetColumnWidth(4,75);
        $list_ctrl->SetColumnWidth(5,75);
        $list_ctrl->SetColumnWidth(6,75);
        $list_ctrl->Arrange(wxLIST_ALIGN_TOP);
        wxTheApp->Yield;

        $list_ctrl->SetFont( wxTheApp->get_font('modern_text_1') );

        return $list_ctrl;
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->pnl_main, wxVERTICAL, 'Main');
    }#}}}
    sub _build_szr_filter {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->pnl_main, wxHORIZONTAL, 'Filter');
    }#}}}

    sub populate_list_ships {#{{{
        my $self = shift;
        wxTheApp->Yield;

        ### Set our filters
        my $paging  = { no_paging => 1 };
        my $filter  = { task => $self->chc_task->GetStringSelection };
        my $tag     = $self->chc_tag->GetStringSelection;
        ### Including both type and tag performs an 'and' search.  Since we 
        ### already know that the type in question is a member of the tag in 
        ### question, doing that would be useless.  So be sure to only include 
        ### one.
        if( my $type_human = $self->chc_type->GetStringSelection ) {
            $filter->{'type'} = wxTheApp->api_ship_name($type_human);
        }
        else {
            $filter->{'tag'} = $tag;
        }

say Dumper $self->bldg_view;
say Dumper $self->bldg_obj;

        ### Get the ships
        my $ships_hr = try {
            ### Don't bother getting clever and adding a $sort.  See below.
            #$self->bldg_obj->view_all_ships( $paging, $filter );
        }
        catch {
            my $msg = (ref $_) ? $_->text : $_;
            wxTheApp->poperr($msg);
            return;
        };
        return unless defined $ships_hr->{'ships'};
        return unless( scalar @{ $ships_hr->{'ships'} } );

        ### afaict, 'sort' simply doesn't work.  The returned ships are not 
        ### sorted at all.
        my @ships = sort{ $a->{'type_human'} cmp $b->{'type_human'} } @{ $ships_hr->{'ships'} };

        ### Add them to the list.
        my $row = 0;
        foreach my $hr( @ships ) {
            my $row_idx = $self->list_ships->InsertStringItem($row, $hr->{'type_human'});
            $self->list_ships->SetItem($row_idx, 1, $hr->{'name'}      || $hr->{'type_human'});
            $self->list_ships->SetItem($row_idx, 2, $hr->{'speed'}     || 0);
            $self->list_ships->SetItem($row_idx, 3, $hr->{'combat'}    || 0);
            $self->list_ships->SetItem($row_idx, 4, $hr->{'hold_size'} || 0);
            $self->list_ships->SetItem($row_idx, 5, $hr->{'stealth'}   || 0);
            $self->list_ships->SetItem($row_idx, 6, $hr->{'task'}      || 'Task Unknown');
            $row++;
            wxTheApp->Yield;
        }

        return $row;
    }#}}}

    sub OnChangeTag {#{{{
        my $self    = shift;
        my $parent  = shift;    # Wx::Panel
        my $event   = shift;    # Wx::CommandEvent

        my $tag         = $self->chc_tag->GetStringSelection;
        my @tag_ships   = sort{
            $a->{'type_human'} cmp $b->{'type_human'}
        }@{wxTheApp->game_client->get_ship_types_by_tag->{$tag}}; 

        $self->chc_type->Clear;
        $self->chc_type->Append( q{} );
        foreach my $ship( @tag_ships ) {
            $self->chc_type->Append( $ship->{'type_human'} );
        }
        $self->szr_filter->Layout();

    }#}}}
    sub OnGetShips {#{{{
        my $self    = shift;
        my $parent  = shift;    # Wx::Panel
        my $event   = shift;    # Wx::CommandEvent

        $self->list_ships->Show(0);
        $self->list_ships->DeleteAllItems();
        my $cnt = $self->populate_list_ships;
        if( $cnt ) {
            wxTheApp->popmsg("Retrieved $cnt ships.");
        }
        else {
            wxTheApp->poperr("You don't have any ships matching your filter criteria.");
        }
        $self->list_ships->Show(1);
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
