
### Search on CHECK

package LacunaWaX::Dialog::Building {
    use v5.14;
    use Data::Dumper;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE EVT_RADIOBOX EVT_SIZE);

    use LacunaWaX::Generics::BldgUpgradeBar;
    extends 'LacunaWaX::Dialog::NonScrolled';

    has 'bldg_hr' => (
        is      => 'rw',
        isa     => 'HashRef',
        required => 1,
    );

    has 'caller' => (
        is      => 'rw',
        isa     => 'Object',
        required => 1,
        documentation => q{
            The object that's calling us.  This object must provide a 
            "building_dialog_closed( $id )" method that we can call.
        }
    );

    has 'planet_id' => (
        is      => 'rw',
        isa     => 'Int',
        required => 1,
    );

    #####################

    has 'bldg_id' => (
        is          => 'ro', 
        isa         => 'Int', 
        lazy_build  => 1,
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

    has 'planet_name' => (
        is          => 'rw',
        isa         => 'Str',
        lazy_build  => 1,
    );

    has 'title' => (
        is          => 'rw',
        isa         => 'Str',
        lazy_build  => 1,
    );

    has 'lbl_header'          => (is => 'rw', isa => 'Wx::StaticText',      lazy_build => 1);
    has 'szr_header'          => (is => 'rw', isa => 'Wx::BoxSizer',        lazy_build => 1);

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->SetTitle( $self->title );
        $self->SetSize( $self->size );

        $self->szr_header->Add($self->lbl_header, 0, 0, 0);


my $upgrade_bar = LacunaWaX::Generics::BldgUpgradeBar->new(
    parent      => $self->dialog,
    bldg_obj    => $self->bldg_obj,
    bldg_view   => $self->bldg_view,

);
#say Dumper $self->bldg_obj;
#say Dumper $self->bldg_view;


        $self->main_sizer->Add($self->szr_header, 0, 0, 0);
        $self->main_sizer->Add($upgrade_bar->szr_main, 0, 0, 0);

        $self->_set_events();
        $self->init_screen();
        return $self;
    }

    sub _build_bldg_id {#{{{
        my $self = shift;
        return $self->bldg_hr->{'bldg_id'};
    }#}}}
    sub _build_bldg_obj {#{{{
        my $self = shift;
        my $obj = wxTheApp->game_client->get_building(
            $self->planet_id,
            $self->bldg_hr->{'name'},
            0,                          # Don't force a re-grab - CHECK this should be variablized to re-grab when we need a refresh.
            {
                id => $self->bldg_id
            }
        );
        return $obj;
    }#}}}
    sub _build_bldg_view {#{{{
        my $self = shift;
        my $view = wxTheApp->game_client->get_building_view(
            $self->bldg_id,
            $self->bldg_obj,
        );
        return $view;
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;

        my $str = $self->bldg_hr->{'name'} . "\n";
          $str .= "On " . $self->planet_name . "\n";
          $str .= "At coords (" . $self->bldg_hr->{'x'} . ", " . $self->bldg_hr->{'y'} . ")";

        my $v = Wx::StaticText->new( $self->dialog, -1, 
            $str,
            wxDefaultPosition, 
            Wx::Size->new(-1, 100)
        );
        $v->SetFont( wxTheApp->get_font('header_1') );

        return $v;
    }#}}}
    sub _build_planet_name {#{{{
        my $self = shift;
        return wxTheApp->game_client->planet_name( $self->planet_id );
    }#}}}
    sub _build_size {#{{{
        my $self = shift;
        my $s = Wx::Size->new(650, 700);
        return $s;
    }#}}}
    sub _build_title {#{{{
        my $self = shift;
        return $self->bldg_hr->{'name'};
    }#}}}
    sub _build_szr_header {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->dialog, wxHORIZONTAL, 'Header');
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE(      $self,                              sub{$self->OnClose(@_)}         );
        EVT_SIZE(       $self,                              sub{$self->OnResize(@_)}        );
        return 1;
    }#}}}

    sub OnClose {#{{{
        my $self = shift;
        $self->caller->building_dialog_closed( $self->bldg_id );
        $self->Destroy;
        return 1;
    }#}}}
    sub OnResize {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;    # Wx::SizeEvent

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
