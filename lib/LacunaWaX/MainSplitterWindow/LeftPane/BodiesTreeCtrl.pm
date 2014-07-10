
package LacunaWaX::MainSplitterWindow::LeftPane::BodiesTreeCtrl {
    use v5.14;
    use utf8;
    use open qw(:std :utf8);
    use Data::Dumper;
    use Moose;
    use MIME::Base64;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_TREE_ITEM_ACTIVATED EVT_ENTER_WINDOW);
    use Wx::Perl::TreeView;
    use Wx::Perl::TreeView::SimpleModel;

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::Panel',
        required    => 1,
        documentation => q{
            The left pane of the main splitter window.
        }
    );

    #########################################

    has 'planets_item_id' => (
        is              => 'rw', 
        isa             => 'Wx::TreeItemId',
        lazy_build      => 1,
        documentation   => q{
            The 'Planets' leaf
        }
    );

    has 'dispatch' => (
        is          => 'rw',
        isa         => 'HashRef',
        lazy_build  => 1,
        documentation => q{
            dispatch table for leaf click actions
        }
    );

    has 'expand_state' => (
        is              => 'rw',
        isa             => 'Str',
        lazy            => 1,
        default         => 'collapsed', 
        documentation   => q{
            Starts out 'collapsed', the other option is 'expanded'.  Used to keep track of what we should
            do (expand or collapse) on a double-click on the visible root item.
        }
    );

    has 'root_item_id' => (
        is              => 'rw',
        isa             => 'Wx::TreeItemId',
        lazy_build      => 1,
        documentation   => q{
            The true root item.  Not visisble because of the wxTR_HIDE_ROOT style.
        }
    );

    has 'treectrl' => (
        is          => 'rw',
        isa         => 'Wx::TreeCtrl',
        lazy_build  => 1,
    );

    has 'treemodel' => (
        is          => 'rw',
        isa         => 'Wx::Perl::TreeView::SimpleModel',
        lazy_build  => 1,
    );

    has 'treeview' => (
        is          => 'rw',
        isa         => 'Wx::Perl::TreeView',
        lazy_build  => 1,
    );


    sub BUILD {
        my $self = shift;
        $self->fill_tree;

        $self->_set_events();
        return $self;
    };
    sub _build_szr_main {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Main Sizer');
    }#}}}
    sub _build_dispatch {#{{{
        my $self    = shift;

        my $dispatch = {
            planets => sub{ $self->toggle_expansion_state() },
            default => sub {
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::DefaultPane'
                );
            },
            rearrange => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane', $planet
                );
            },
            name => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::SummaryPane', $planet
                );
            },
            glyphs => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::GlyphsPane',
                    $planet,
                    { required_buildings  => {'Archaeology Ministry' => undef}, }
                );
            },
            repair => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::RepairPane',
                    $planet,
                );
            },
            spies => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::SpiesPane',
                    $planet,
                    { required_buildings => {'Intelligence Ministry' => undef} } 
                );
            },
            bfg => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::BFGPane',
                    $planet,
                    { required_buildings => {'Parliament' => 25} } 
                );
            },
            incoming => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::SSIncoming',
                    $planet,
                    { required_buildings => {'Police' => undef} } 
                );
            },
            propositions => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::PropositionsPane',
                    $planet,
                    { 
                        required_buildings  => {'Parliament' => undef}, 
                        nothrob             => 1,
                    } 
                );
            },
            sshealth => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::SSHealth',
                    $planet,
                );
            },
            voting => sub {
                my $planet  = shift;
                wxTheApp->right_pane->show_right_pane(
                    'LacunaWaX::MainSplitterWindow::RightPane::PropositionsPane',
                    $planet,
                );
            },

        };
        return $dispatch;
    }#}}}
    sub _build_treectrl {#{{{
        my $self = shift;
        my $v = Wx::TreeCtrl->new(
            $self->parent, -1, wxDefaultPosition, wxDefaultSize, 
            wxTR_DEFAULT_STYLE
            |wxTR_HAS_BUTTONS
            |wxTR_LINES_AT_ROOT
            |wxSUNKEN_BORDER
            |wxTR_HIDE_ROOT
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_treemodel {#{{{
        my $self = shift;
        my $b64_planets     = encode_base64(join q{:}, ('planets'));
        my $b64_stations    = encode_base64(join q{:}, ('stations'));
        my $b64_alliance    = encode_base64(join q{:}, ('alliance'));
        my $tree_data = {
            node    => 'Root',
            childs  => [
                { 
                    node => 'Planets',
                    data => $b64_planets,
                },
                { 
                    node => 'Stations',
                    data => $b64_stations,
                },
                { 
                    node => 'Alliance',
                    data => $b64_alliance,
                },
            ],
        };
        my $v = Wx::Perl::TreeView::SimpleModel->new( $tree_data );
        return $v;
    }#}}}
    sub _build_treeview {#{{{
        my $self = shift;
        my $model;
        my $v = Wx::Perl::TreeView->new(
            $self->treectrl, $self->treemodel
        );

        return $v;
    }#}}}
    sub _build_root_item_id {#{{{
        my $self = shift;
        return $self->treeview->treectrl->GetRootItem;
    }#}}}
    sub _build_planets_item_id {#{{{
        my $self = shift;
        my($body_id, $cookie) = $self->treeview->treectrl->GetFirstChild($self->root_item_id);
        return $body_id;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_TREE_ITEM_ACTIVATED(    $self->treeview->treectrl, $self->treeview->treectrl->GetId,    sub{$self->OnTreeClick(@_)}     );
        EVT_ENTER_WINDOW(           $self->treeview->treectrl,                                      sub{$self->OnMouseEnter(@_)}    );
        return 1;
    }#}}}

    sub bold_planet_names_orig {#{{{
        my $self = shift;

        my( $planet_id, $cookie ) = $self->treeview->treectrl->GetFirstChild( $self->planets_item_id );
        my $cnt = 1;
        $self->treectrl->SetItemFont( $planet_id, wxTheApp->get_font('bold_para_text_1') );

        while( $planet_id = $self->treeview->treectrl->GetNextSibling($planet_id) ) {
            last unless $planet_id->IsOk;
            $cnt++;
            $self->treectrl->SetItemFont( $planet_id, wxTheApp->get_font('bold_para_text_1') );
        }
        return $cnt;
    }#}}}
    sub bold_planet_names {#{{{
        my $self = shift;

        ### Bolds the "Planets" and "Stations" branches themselves.  The 
        ### actual named planets and stations sub-leaves stay un-bolded.

        my($planets_id, $cookie) = $self->treeview->treectrl->GetFirstChild($self->root_item_id);
        $self->treectrl->SetItemFont( $planets_id, wxTheApp->get_font('bold_para_text_1') );

        my $stations_id;
        ($stations_id, $cookie) = $self->treeview->treectrl->GetNextChild($self->root_item_id, $cookie);
        $self->treectrl->SetItemFont( $stations_id, wxTheApp->get_font('bold_para_text_1') );

        my $voting_id;
        ($voting_id, $cookie) = $self->treeview->treectrl->GetNextChild($self->root_item_id, $cookie);
        $self->treectrl->SetItemFont( $stations_id, wxTheApp->get_font('bold_para_text_1') );
    }#}}}
    sub fill_tree {#{{{
        my $self = shift;

        return unless( wxTheApp->game_client and wxTheApp->game_client->ping );

        my $schema      = wxTheApp->main_schema;
        my $planets     = [];
        my $stations    = [];
        my $alliance    = [];
        foreach my $pname( sort{lc $a cmp lc $b} keys %{wxTheApp->game_client->planets} ) {#{{{

            my $pid = wxTheApp->game_client->planet_id($pname);
            my $planet_node = {
                node    => $pname,
                data    => encode_base64(join q{:}, ('name', $pid)),
                childs  => [],
            };

            ### Both Planet and Station
            my $b64_rearrange   = encode_base64(join q{:}, ('rearrange', $pid));
            ### Planet only
            my $b64_glyphs      = encode_base64(join q{:}, ('glyphs', $pid));
            my $b64_repair      = encode_base64(join q{:}, ('repair', $pid));
            my $b64_spies       = encode_base64(join q{:}, ('spies', $pid));

            push @{ $planet_node->{'childs'} }, { node => 'Glyphs',     data => $b64_glyphs };
            push @{ $planet_node->{'childs'} }, { node => 'Rearrange',  data => $b64_rearrange };
            push @{ $planet_node->{'childs'} }, { node => 'Repair',     data => $b64_repair };
            push @{ $planet_node->{'childs'} }, { node => 'Spies',      data => $b64_spies };

            push @{$planets}, $planet_node;
        }#}}}
        foreach my $sname( sort{lc $a cmp lc $b} keys %{wxTheApp->game_client->stations} ) {#{{{

            my $sid = wxTheApp->game_client->station_id($sname);
            my $station_node = {
                node    => $sname,
                data    => encode_base64(join q{:}, ('name', $sid)),
                childs  => [],
            };

            ### Both Planet and Station
            my $b64_rearrange   = encode_base64(join q{:}, ('rearrange', $sid));
            ### Station only
            my $b64_bfg         = encode_base64(join q{:}, ('bfg', $sid));
            my $b64_inc         = encode_base64(join q{:}, ('incoming', $sid));
            my $b64_sshealth    = encode_base64(join q{:}, ('sshealth', $sid));

            ### IMPORTANT!
            ### SummaryPane::fix_tree_for_stations() is expecting the 
            ### first child of a SS leaf to be "Fire the BFG".
            ###
            ### I'm no longer sure if that's true with the new station stuff.
            ###
            ### If you change the first child, or even just change the 
            ### label on that BFG leaf, be sure to update 
            ### fix_tree_for_stations as well.
            push @{ $station_node->{'childs'} }, { node => 'Fire the BFG',   data => $b64_bfg };
            push @{ $station_node->{'childs'} }, { node => 'Health Alerts',  data => $b64_sshealth };
            push @{ $station_node->{'childs'} }, { node => 'Incoming',       data => $b64_inc };
            push @{ $station_node->{'childs'} }, { node => 'Rearrange',      data => $b64_rearrange };

            push @{$stations}, $station_node;
        }#}}}
        {### Alliance #{{{

            my $b64_voting   = encode_base64('voting');

            my $voting_node = {
                node    => 'Voting',
                data    => $b64_voting,
                childs  => [],
            };

            push @{$alliance}, $voting_node;


            ### Add some empty nodes at the bottom, or the last item will be 
            ### obscured by the bottom of the frame.
            for(1..2) {
                my $empty_node = {
                    node    => q{},
                    childs  => [],
                };
                push @{$alliance}, $empty_node;
            }

        }#}}}

        my $model_data = $self->treeview->model->data;
        $model_data->{'childs'}[0]{'childs'} = $planets;
        $model_data->{'childs'}[1]{'childs'} = $stations;
        $model_data->{'childs'}[2]{'childs'} = $alliance;
        $self->treeview->model->data( $model_data );
        $self->treeview->reload();

        $self->clear_root_item_id;
        $self->clear_planets_item_id;

        $self->treeview->treectrl->Expand( $self->planets_item_id );
        $self->bold_planet_names();
        $self->expand_state('collapsed');

        return 1;
    }#}}}
    sub toggle_expansion_state {#{{{
        my $self = shift;

        ### Collapsing and expanding provides a bit of animation.
        ###
        ### Hiding the tree before doing anything, then showing it afterwards, 
        ### removes that animation, but it makes the state toggle happen much 
        ### more quickly.
        ### 
        ### The animation is vaguely pretty, but it's also clunky-looking and 
        ### slow.  Hiding it toggles the state almost instantly and looks more 
        ### solid.

        $self->treectrl->Show(0);
        if( $self->expand_state eq 'collapsed' ) {
            $self->treectrl->ExpandAllChildren( $self->planets_item_id );
            ### Expanding everything auto-scrolls us to the bottom, and 
            ### nobody wants that.  Rescroll back up to the top.
            $self->treectrl->ScrollTo( $self->planets_item_id );
            $self->expand_state('expanded');
        }
        else {
            my($child, $cookie) = $self->treectrl->GetFirstChild($self->planets_item_id);
            $self->treectrl->CollapseAllChildren( $child );

            COLLAPSE:
            while( 1 ) {
                ($child, $cookie) = $self->treectrl->GetNextChild($self->planets_item_id, $cookie); 
                last COLLAPSE unless $child->IsOk;
                $self->treectrl->CollapseAllChildren( $child );
            }
            $self->expand_state('collapsed');
            $self->treectrl->ScrollTo( $self->planets_item_id );
        }
        $self->treectrl->Show(1);

        $self->bold_planet_names();

        return 1;
    }#}}}

    sub OnTreeClick {#{{{
        my $self        = shift;
        my $tree_ctrl   = shift;
        my $tree_event  = shift;

        my $leaf = $tree_event->GetItem();
        my $root = $tree_ctrl->GetRootItem();

        if( $leaf == $tree_ctrl->GetRootItem ) {
            wxTheApp->poperr("Selected item is root item.");
            return;
        }

        my $text = $tree_ctrl->GetItemText($leaf);
        if( my $data = $tree_ctrl->GetItemData($leaf) ) {#{{{


            my $hr = $data->GetData;
=pod

 $hr = {
  'cookie' => {
    'data' => base64-encoded cookie data that we don't care about
    'node' => 'Glyphs'
  },
  'data' => base64-encoded leaf data that we _do_ care about
 };

=cut


            my ($action, $pid, @args)   = split /:/, decode_base64($hr->{'data'} || q{});
            my $planet                  = wxTheApp->game_client->planet_name($pid);

            $action ||= q{};    
            if( defined $self->dispatch->{$action} ) {
                &{ $self->dispatch->{$action} }($planet);
            }
        }#}}}
        else {
            say "got no data.";
        }


        return 1;
    }#}}}
    sub OnMouseEnter {#{{{
        my $self    = shift;
        my $control = shift;    # Wx::TreeCtrl
        my $event   = shift;    # Wx::MouseEvent

        ### Set focus on the treectrl when the mouse enters to allow 
        ### scrollwheel events to affect the tree rather than whatever they'd 
        ### been affecting previously.
        unless( wxTheApp->main_frame->splitter->left_pane->has_focus ) {
            $control->SetFocus;
            wxTheApp->main_frame->splitter->focus_left();
        }

        $event->Skip();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

