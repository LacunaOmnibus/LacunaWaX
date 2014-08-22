
package LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane {
    use v5.14;
    use Data::Dumper;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE EVT_RADIOBOX EVT_SIZE);
    with 'LacunaWaX::Roles::MainSplitterWindow::RightPane';

    use LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::BitmapButton;
    use LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::Buildings;
    use LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::Buttons;
    use LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::SavedBuilding;

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
    );

    has 'planet_name'   => (
        is          => 'rw',
        isa         => 'Str',
        required => 1
    );

    #########################################

    has 'blank_image' => (
        is          => 'rw',
        isa         => 'Wx::Bitmap',
        lazy_build  => 1,
    );

    has 'buildings' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::Buildings', 
        lazy_build  => 1,
    );

    has 'buttons' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::Buttons', 
        lazy_build  => 1,
    );

    has 'dialogs' => (
        is          => 'rw',
        isa         => 'HashRef', 
        lazy        => 1,
        default     => sub{ {} },
        documentation => q{
            Hashref of building dialogs opened by this panel.
            id => LacunaWaX::Dialog::Building
        }
    );

    has 'gauge_value' => (
        is          => 'rw',
        isa         => 'Int',
        lazy        => 1,
        default     => 1,
    );

    has 'mode_choices' => (
        is          => 'rw',
        isa         => 'ArrayRef',
        lazy        => 1,
        default     => sub{ [qw(Buildings Rearrange)]},
    );

    has 'mode_current' => (
        is          => 'rw',
        isa         => 'Int',
        lazy        => 1,
        default     => 0,
    );

    has 'planet_id' => (
        is          => 'rw',
        isa         => 'Int',
        lazy_build  => 1
    );

    has 'saved_bldg' => (
        is          => 'rw', 
        isa         => 'LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::SavedBuilding', 
        lazy_build  => 1
    );



    has 'btn_rearrange'     => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1);
    has 'btn_reload'        => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1);
    has 'lbl_planet_name'   => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'rdo_mode'          => (is => 'rw', isa => 'Wx::RadioBox',      lazy_build => 1);

    has 'gridszr_buttons'       => (is => 'rw', isa => 'Wx::GridSizer', lazy_build => 1);
    has 'szr_bottom_buttons'    => (is => 'rw', isa => 'Wx::BoxSizer',  lazy_build => 1);
    has 'szr_mode'              => (is => 'rw', isa => 'Wx::BoxSizer',  lazy_build => 1);

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers


        $self->clear_saved_bldg;
        $self->reset_gauge();
        $self->set_surface_buttons;

        $self->szr_mode->Add($self->rdo_mode, 0, 0, 0);
        $self->szr_mode->AddSpacer(10);

        $self->szr_bottom_buttons->Add($self->btn_rearrange, 0, 0, 0);
        $self->szr_bottom_buttons->Add($self->btn_reload, 0, 0, 0);

        $self->content_sizer->Add($self->lbl_planet_name, 0, 0, 0);
        $self->content_sizer->Add($self->szr_mode, 0, 0, 0);
        $self->content_sizer->Add($self->gridszr_buttons, 0, 0, 0);
        $self->content_sizer->Add($self->szr_bottom_buttons, 0, 0, 0);
        $self->refocus_window_name( 'lbl_planet_name' );

        $self->set_mode(0);
        $self->_set_events();
        return $self;
    }
    sub _build_blank_image {#{{{
        my $self = shift;
        my $img = wxTheApp->get_image('planetside/blank.png');
        $img->Rescale(50, 50);
        return Wx::Bitmap->new($img);
    }#}}}
    sub _build_btn_rearrange {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->parent, -1, 'Rearrange');
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_btn_reload {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->parent, -1, 'Reload');
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_buildings {#{{{
        my $self = shift;
        my $force = shift || 0;

        my $bldgs = try {
            wxTheApp->game_client->get_buildings($self->planet_id, undef, $force);
        }
        catch {
            wxTheApp->poperr($_->text);
            return;
        };

        return LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::Buildings->new( $bldgs );
    }#}}}
    sub _build_buttons {#{{{
        my $self = shift;
        return LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::Buttons->new();
    }#}}}
    sub _build_gridszr_buttons {#{{{
        my $self = shift;
        return Wx::GridSizer->new(11, 11, 1, 1);
    }#}}}
    sub _build_lbl_planet_name {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            'Rearrange ' . $self->planet_name, 
            wxDefaultPosition, 
            Wx::Size->new(640, 40)
        );
        $v->SetFont( wxTheApp->get_font('header_1') );
        return $v;
    }#}}}
    sub _build_planet_id {#{{{
        my $self = shift;
        return wxTheApp->game_client->planet_id( $self->planet_name );
    }#}}}
    sub _build_rdo_mode {#{{{
        my $self = shift;
        my $v = Wx::RadioBox->new(
            $self->parent, -1, 
            "Mode", 
            wxDefaultPosition, 
            Wx::Size->new(225,50), 
            $self->mode_choices,
            1, 
            wxRA_SPECIFY_ROWS
        );
        #$v->SetSize( $v->GetBestSize );
        $v->SetSelection( $self->mode_current );    # 0-based
        return $v;
    }#}}}
    sub _build_saved_bldg {#{{{
        my $self = shift;

        return LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::SavedBuilding->new(
            name   => 'Empty',
            bitmap => $self->blank_image
        );
    }#}}}
    sub _build_szr_bottom_buttons {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Bottom Buttons');
    }#}}}
    sub _build_szr_mode {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Mode');
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        ### Events for individual plot buttons are set in set_surface_buttons
        EVT_BUTTON(     $self->parent,  $self->btn_rearrange->GetId,    sub{$self->OnRearrangeButtonClick(@_)}  );
        EVT_BUTTON(     $self->parent,  $self->btn_reload->GetId,       sub{$self->OnReloadButtonClick(@_)}     );
        EVT_CLOSE(      $self->parent,                                  sub{$self->OnClose(@_)}         );
        EVT_RADIOBOX(   $self->parent,  $self->rdo_mode->GetId,         sub{$self->OnRadio(@_)}         );
        EVT_SIZE(       $self->parent,                                  sub{$self->OnResize(@_)}                );
        return 1;
    }#}}}

    sub OnPlotButtonClick {#{{{
        my $self    = shift;
        my $id      = shift;
        my $panel   = shift;
        my $event   = shift;

        my $bitmap_button   = $self->buttons->by_id($id); 
        my $button          = $bitmap_button;
        my $image           = $button->GetBitmapLabel;
        my $label           = $button->GetLabel;

        my $mode_str = $self->rdo_mode->GetStringSelection;
        if( $mode_str eq 'Rearrange' ) {
            return if $bitmap_button->x == 0 and $bitmap_button->y == 0;    # PCC; can't be moved.
            $self->swap($bitmap_button);
        }
        elsif( $mode_str eq 'Buildings' ) {
            $self->catch_building_click( $button->bldg );
        }

        return 1;
    }#}}}
    sub OnRearrangeButtonClick {#{{{
        my $self    = shift;
        my $panel   = shift;
        my $event   = shift;

        $self->btn_rearrange->Enable(0);

        wxTheApp->throb();
        my $layout = [];
        foreach my $b( $self->buttons->all ) {
            next if $b->name eq 'Empty';
            unless( $b->x == $b->orig_x and $b->y == $b->orig_y) {
                my $loc = { 
                    id => $b->bldg_id, 
                    x  => $b->x, 
                    y  => $b->y,
                };
                $b->orig_x( $b->x );
                $b->orig_y( $b->y );
                push @{$layout}, $loc;
            }
        }

        my $rv = try {
            wxTheApp->game_client->rearrange($self->planet_id, $layout);
        }
        catch {
            wxTheApp->poperr($_->text);
            return;
        };
        wxTheApp->endthrob();

        if( ref $rv eq 'HASH' and defined $rv->{'moved'} and scalar @{$rv->{'moved'}} ) {
            my $n = scalar @{$rv->{'moved'}};
            my $plural = ($n == 1) ? ' was' : 's were';
            wxTheApp->popmsg(
                "$n building${plural} relocated.",
                'Success!'
            );
        }
        else {
            wxTheApp->popmsg(
                'Nothing changed position.',
                "What's wrong with you?"
            );
        }

        $self->btn_rearrange->Enable(1);
        return 1;
    }#}}}
    sub OnReloadButtonClick {#{{{
        my $self    = shift;
        my $panel   = shift;
        my $event   = shift;

        $self->clear_saved_bldg;
        $self->buildings( $self->_build_buildings($self->planet_id, undef, 1) );
        wxTheApp->main_frame->splitter->right_pane->show_right_pane(
            'LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane', $self->planet_name
        );
        return 1;
    }#}}}

    sub catch_building_click {#{{{
        my $self = shift;
        my $bldg = shift;   # hr

    ### I need a new Building dialog.  Pass it planet_id and the $bldg 
    ### hashref, then let it do whatever it's going to do.


=pod

$VAR1 = {
  'efficiency' => '100',
  'url' => '/geothermalvent',
  'level' => '30',
  'x' => '-2',
  'name' => 'Geo Thermal Vent',
  'bldg_id' => '3808421',
  'image' => 'geothermalvent1',
  'y' => '5'
};

=cut

        ### Don't try to display a building dialog if the user clicked an 
        ### empty plot.
        return unless keys %{$bldg};

        my $d = LacunaWaX::Dialog::Building->new(
            bldg_hr     => $bldg,
            caller      => $self,
            planet_id   => $self->planet_id,
        );
        $self->dialogs->{ $d->bldg_id } = $d;
        $d->Show(1);
    }#}}}
    sub building_dialog_closed {#{{{
        my $self    = shift;
        my $id      = shift;
        delete $self->dialogs->{ $id };
    }#}}}
    sub inc_gauge {#{{{
        my $self = shift;
        my $inc  = shift || 1;
        $self->gauge_value($self->gauge_value + $inc); 
        my $sb = wxTheApp->main_frame->status_bar;
        $sb->gauge->SetValue($self->gauge_value);
        $sb->gauge->Update();
        return $self->gauge_value;
    }#}}}
    sub reset_gauge {#{{{
        my $self = shift;
        my $sb = wxTheApp->main_frame->status_bar;
        $sb->gauge->SetRange(121);
        $self->gauge_value(0); 
        $sb->gauge->SetValue($self->gauge_value);
        return $self->gauge_value;
    }#}}}
    sub set_mode {#{{{
        my $self = shift;
        my $mode = shift;   # zero based offset
 
        my $mode_str = $self->rdo_mode->GetLabel( $mode );
        my $btn_show = ($mode_str eq 'Rearrange') ? 1 : 0;

        $self->btn_rearrange->Show($btn_show);
        $self->btn_reload->Show($btn_show);
        $self->parent->Layout();

        return 1;
    }#}}}
    sub set_surface_buttons {#{{{
        my $self = shift;

        ### button packing starts in the upper left corner (-5,5) and works in 
        ### reading order (left to right, CR, left to right, etc) through to 
        ### (5,-5)
        my $cnt = 0;
        for my $y(reverse(-5..5)) {
            for my $x(-5..5) {
                $cnt++;

                $self->inc_gauge;
                my $bldg_hr = $self->buildings->by_loc($x, $y);

                my $bitmap;
                if( defined $bldg_hr->{'image'} ) {
                    my $img = wxTheApp->get_image("planetside/$bldg_hr->{'image'}.png");
                    $img->Rescale(50, 50);
                    $bitmap = Wx::Bitmap->new($img);
                }
                else {
                    $bitmap = $self->blank_image;
                }

                my $bmp_butt = LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::BitmapButton->new( 
                        parent      => $self->parent,
                        bitmap      => $bitmap,
                        bldg        => $bldg_hr,
                        bldg_id     => $bldg_hr->{'bldg_id'}     || 0,
                        name        => $bldg_hr->{'name'}        || 'Empty',
                        level       => $bldg_hr->{'level'}       || 0,
                        efficiency  => $bldg_hr->{'efficiency'}  || 0,
                        x           => $x,
                        y           => $y,
                        orig_x      => $x,
                        orig_y      => $y,
                );
                $self->buttons->add($bmp_butt);
                EVT_BUTTON( $self->parent, $bmp_butt->GetId, sub{$self->OnPlotButtonClick($bmp_butt->GetId, @_)} );

                $self->gridszr_buttons->Add(
                    $bmp_butt->bitmap_button, 0, wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0
                );
            }
        }
        $self->reset_gauge;
        return 1;
    }#}}}
    sub swap {#{{{
        my $self   = shift;
        my $button = shift;

=pod

Takes the building on the button the user just clicked and replaces it with our currently-saved 
building, then makes the one the user just clicked out currently-saved.

=cut

        ### Grab the currently-saved building
        my $saved = $self->saved_bldg;

        ### Set the building represented by the just-clicked button as our new 
        ### saved building
        $self->saved_bldg(
            LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::SavedBuilding->new(
                bitmap      => $button->bitmap,
                bldg_id     => $button->bldg_id,
                efficiency  => $button->efficiency,
                id          => $button->GetId,
                level       => $button->level,
                name        => $button->name,
                orig_x      => $button->orig_x,
                orig_y      => $button->orig_y,
            )
        );

        ### Now put our old saved building on the just-clicked button.
        $button->bldg_id(     $saved->bldg_id    || 0        );
        $button->name(        $saved->name       || 'Empty'  );
        $button->level(       $saved->level      || 0        );
        $button->efficiency(  $saved->efficiency || 0        );
        $button->bitmap(      $saved->bitmap                 );
        $button->orig_x(      $saved->orig_x                 );
        $button->orig_y(      $saved->orig_y                 );

        $button->SetBitmapLabel( $button->bitmap );
        $button->update_button_tooltip;
        return 1;
    }#}}}

    sub OnClose {#{{{
        my $self    = shift;

        foreach my $dialog( values %{$self->dialogs} ) {
            $dialog->OnClose();
        }
        return 1;
    }#}}}
    sub OnRadio {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;    # Wx::CommandEvent

        my $mode = $self->rdo_mode->GetSelection();
        $self->set_mode($mode);


        return 1;
    }#}}}
    sub OnResize {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;    # Wx::SizeEvent

        ###
        ### Don't remove this handler!!!!!
        ### 
        ### Its existence appears to be stopping a segfault.  See 
        ### AllianceSummaryPane's OnResize for more info.
        ###

    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
