
### Just opens a dialog displaying the name of the planet, the building in 
### question, and its coords on the planet.
###
### Segfaults if the app is closed while the dialog is still open; deal with 
### that.

package LacunaWaX::Dialog::Building {
    use v5.14;
    use Data::UUID;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE EVT_RADIOBOX EVT_SIZE);

    extends 'LacunaWaX::Dialog::NonScrolled';

    has 'building_hr' => (
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

    has 'id' => (
        is          => 'ro', 
        isa         => 'Str', 
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

        $self->main_sizer->Add($self->szr_header, 0, 0, 0);

        $self->_set_events();
        $self->init_screen();
        return $self;
    }

    sub _build_id {#{{{
        my $self = shift;

        my $g = Data::UUID->new();
        my $id = $g->create();
        return $g->to_string($id);
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;

        my $str = $self->building_hr->{'name'} . "\n";
          $str .= "On " . $self->planet_name . "\n";
          $str .= "At coords (" . $self->building_hr->{'x'} . ", " . $self->building_hr->{'y'} . ")";

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
        return $self->building_hr->{'name'};
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
        $self->caller->building_dialog_closed( $self->id );
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
