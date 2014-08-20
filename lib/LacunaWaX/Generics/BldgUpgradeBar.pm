
package LacunaWaX::Generics::BldgUpgradeBar {
    use v5.14;
    use Data::Dumper;
    use Moose;
    use Number::Format;
    use Try::Tiny;
    use Wx qw(:everything);

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::Window',
        required    => 1,
    );

    has 'bldg_obj' => (
        is          => 'rw',
        isa         => 'Object',
        required    => 1,
    );

    has 'bldg_view' => (
        is          => 'rw',
        isa         => 'HashRef',
        required    => 1,
    );

    #########################################

    has 'num_formatter' => (
        is      => 'rw',
        isa     => 'Number::Format',
        lazy    => 1,
        default => sub{ Number::Format->new },
        handles => {
            format_num => 'format_number',
        }
    );

    has 'hdr_w' => (is => 'rw', isa => 'Int', lazy => 1, default => 150 );
    has 'hdr_h' => (is => 'rw', isa => 'Int', lazy => 1, default =>  20 );
    has 'col_w' => (is => 'rw', isa => 'Int', lazy => 1, default => 160 );

    has 'szr_main'      => (is => 'rw', isa => 'Wx::BoxSizer', lazy_build => 1, documentation => 'horizontal'   );

    ### These cannot be generically built by make_res_box.  Each of the images 
    ### has a slightly different width (grrr), and the labels need to be 
    ### attributes so they can be updated later.
    has 'img_food'      => (is => 'rw', isa => 'Wx::StaticBitmap',  lazy_build => 1     );
    has 'img_ore'       => (is => 'rw', isa => 'Wx::StaticBitmap',  lazy_build => 1     );
    has 'img_water'     => (is => 'rw', isa => 'Wx::StaticBitmap',  lazy_build => 1     );
    has 'img_energy'    => (is => 'rw', isa => 'Wx::StaticBitmap',  lazy_build => 1     );
    has 'img_waste'     => (is => 'rw', isa => 'Wx::StaticBitmap',  lazy_build => 1     );
    has 'img_happiness' => (is => 'rw', isa => 'Wx::StaticBitmap',  lazy_build => 1     );
    has 'img_time'      => (is => 'rw', isa => 'Wx::StaticBitmap',  lazy_build => 1     );

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        my $szr_box = $self->make_res_box();

        $self->szr_main->AddStretchSpacer(1);
        $self->szr_main->Add($szr_box, 0, wxALIGN_CENTER, 0);
        $self->szr_main->AddStretchSpacer(1);

        return $self;
    }
    sub _build_img_food {#{{{
        my $self = shift;

        my $img  = wxTheApp->get_image('res_s/food.png');
        my $bmp  = Wx::Bitmap->new($img);
        return Wx::StaticBitmap->new(
            $self->parent, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($img->GetWidth, $img->GetHeight),
            wxFULL_REPAINT_ON_RESIZE
        );

    }#}}}
    sub _build_img_ore {#{{{
        my $self = shift;

        my $img  = wxTheApp->get_image('res_s/ore.png');
        my $bmp  = Wx::Bitmap->new($img);
        return Wx::StaticBitmap->new(
            $self->parent, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($img->GetWidth, $img->GetHeight),
            wxFULL_REPAINT_ON_RESIZE
        );
    }#}}}
    sub _build_img_water {#{{{
        my $self = shift;

        my $img  = wxTheApp->get_image('res_s/water.png');
        my $bmp  = Wx::Bitmap->new($img);
        return Wx::StaticBitmap->new(
            $self->parent, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($img->GetWidth, $img->GetHeight),
            wxFULL_REPAINT_ON_RESIZE
        );
    }#}}}
    sub _build_img_energy {#{{{
        my $self = shift;

        my $img  = wxTheApp->get_image('res_s/energy.png');
        my $bmp  = Wx::Bitmap->new($img);
        return Wx::StaticBitmap->new(
            $self->parent, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($img->GetWidth, $img->GetHeight),
            wxFULL_REPAINT_ON_RESIZE
        );
    }#}}}
    sub _build_img_waste {#{{{
        my $self = shift;

        my $img  = wxTheApp->get_image('res_s/waste.png');
        my $bmp  = Wx::Bitmap->new($img);
        return Wx::StaticBitmap->new(
            $self->parent, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($img->GetWidth, $img->GetHeight),
            wxFULL_REPAINT_ON_RESIZE
        );
    }#}}}
    sub _build_img_happiness {#{{{
        my $self = shift;

        my $img  = wxTheApp->get_image('res_s/happiness.png');
        my $bmp  = Wx::Bitmap->new($img);
        return Wx::StaticBitmap->new(
            $self->parent, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($img->GetWidth, $img->GetHeight),
            wxFULL_REPAINT_ON_RESIZE
        );
    }#}}}
    sub _build_img_time {#{{{
        my $self = shift;

        my $img  = wxTheApp->get_image('res_s/time.png');
        my $bmp  = Wx::Bitmap->new($img);
        return Wx::StaticBitmap->new(
            $self->parent, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($img->GetWidth, $img->GetHeight),
            wxFULL_REPAINT_ON_RESIZE
        );
    }#}}}
    sub _build_planet_id {#{{{
        my $self = shift;
        return wxTheApp->game_client->planet_id( $self->planet_name );
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Res Outside');
    }#}}}

    sub make_res_box {#{{{
        my $self = shift;

=pod

szr_main (horiz)
    szr_current (vert)
        szr_row (horiz) (1 cell; header label)
        szr_row (horiz) (2 cells; food img/value)
        szr_row (horiz) (2 cells; ore img/value)
        szr_row (horiz) (2 cells; h2o img/value)
        szr_row (horiz) (2 cells; nrg img/value)
        szr_row (horiz) (2 cells; waste img/value)
        szr_row (horiz) (2 cells; happy img/value)
    szr_prod (vert)
        same setup as szr_current
    szr_cost (vert)
        same setup as szr_current EXCEPT instead of happy for the last row, 
        we have time.

=cut

        my $szr_main    = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, "Main");
        my $szr_current = wxTheApp->build_sizer($self->parent, wxVERTICAL, "Current");
        my $szr_prod    = wxTheApp->build_sizer($self->parent, wxVERTICAL, "Prod");
        my $szr_cost    = wxTheApp->build_sizer($self->parent, wxVERTICAL, "Cost");


        { ### CURRENT {#{{{
            ### Header
            my $lbl_header = Wx::StaticText->new(
                $self->parent, -1, "Current Production",
                wxDefaultPosition, Wx::Size->new($self->hdr_w, $self->hdr_h)
            );
            $szr_current->Add($lbl_header, 0, wxALIGN_CENTER, 0);

            foreach my $restype(qw(food ore water energy waste happiness)) {
                ### Sizer
                my $szr = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, "C res");
                $szr->SetMinSize( $self->col_w, 20 );

                ### Image
                my $img_builder_name = "_build_img_$restype";
                my $img = $self->$img_builder_name;
                $szr->Add($img, 0, wxALIGN_CENTER, 0);

                ### Spacer between image and label
                $szr->AddStretchSpacer( 10 );

                ### Label
                my $val = $self->format_num( ($self->bldg_view->{'building'}{"${restype}_hour"} // '0') ) . "/hr";
                my $lbl = Wx::StaticText->new(
                    $self->parent, -1, $val,
                    wxDefaultPosition, Wx::Size->new(-1,-1)
                );
                $lbl->SetFont( wxTheApp->get_font('modern_text_1') );
                $szr->Add($lbl, 0, wxALIGN_RIGHT, 0);

                $szr_current->Add($szr, 0, 0, 0);
            }
        } ### }#}}}
        { ### UPGRADE_PRODUCTION {#{{{
            ### Header
            my $lbl_header = Wx::StaticText->new(
                $self->parent, -1, "Upgrade Production",
                wxDefaultPosition, Wx::Size->new($self->hdr_w, $self->hdr_h)
            );
            $szr_prod->Add($lbl_header, 0, wxALIGN_CENTER, 0);

            foreach my $restype(qw(food ore water energy waste happiness)) {
                ### Sizer
                my $szr = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, "C res");
                $szr->SetMinSize( $self->col_w, 20 );

                ### Image
                my $img_builder_name = "_build_img_$restype";
                my $img = $self->$img_builder_name;
                $szr->Add($img, 0, wxALIGN_CENTER, 0);

                ### Spacer between image and label
                $szr->Add( 10, 0, 1 );

                ### Label
                my $val = $self->format_num( ($self->bldg_view->{'building'}{'upgrade'}{'production'}{"${restype}_hour"} // '0') ) . "/hr";
                my $lbl = Wx::StaticText->new(
                    $self->parent, -1, $val,
                    wxDefaultPosition, Wx::Size->new(-1, -1)
                );
                $lbl->SetFont( wxTheApp->get_font('modern_text_1') );
                $szr->Add($lbl, 0, wxALIGN_RIGHT, 0);

                $szr_prod->Add($szr, 0, 0, 0);
            }
        } ### }#}}}
        { ### UPGRADE_COST {#{{{
            ### Header
            my $lbl_header = Wx::StaticText->new(
                $self->parent, -1, "Upgrade Cost",
                wxDefaultPosition, Wx::Size->new($self->hdr_w, $self->hdr_h)
            );
            $szr_cost->Add($lbl_header, 0, wxALIGN_CENTER, 0);

            foreach my $restype(qw(food ore water energy waste time)) {
                ### Sizer
                my $szr = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, "C res");
                $szr->SetMinSize( $self->col_w, 20 );

                ### Image
                my $img_builder_name = "_build_img_$restype";
                my $img = $self->$img_builder_name;
                $szr->Add($img, 0, wxALIGN_CENTER, 0);

                ### Spacer between image and label
                $szr->Add( 10, 0, 1 );

                ### Label
                my $val = $self->format_num( $self->bldg_view->{'building'}{'upgrade'}{'cost'}{$restype} // '0' );
                my $lbl = Wx::StaticText->new(
                    $self->parent, -1, $val,
                    wxDefaultPosition, Wx::Size->new(-1, -1)
                );
                $lbl->SetFont( wxTheApp->get_font('modern_text_1') );
                $szr->Add($lbl, 0, wxALIGN_RIGHT, 0);

                $szr_cost->Add($szr, 0, 0, 0);
            }
        } ### }#}}}

        $szr_main->Add($szr_current, 2, 0, 0);
        $szr_main->AddSpacer(20);
        $szr_main->Add($szr_prod, 2, 0, 0);
        $szr_main->AddSpacer(20);
        $szr_main->Add($szr_cost, 2, 0, 0);

        return $szr_main;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__


=head1 NAME LacunaWaX::Generics::ResBar

Produces a sizer containing images for the four res types, and reports the 
number of each res currently onsite.

=head1 SYNOPSIS

 my $res = LacunaWaX::Generics::ResBar->new(
  parent      => $self->parent,
  planet_name => $self->planet_name,
 );

 $self->content_sizer->Add($res->szr_main, 0, 0, 0);

 ...do something that changes the amount of res stored (eg repair a bunch of buildings)...

=cut

