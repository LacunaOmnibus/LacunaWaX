
package LacunaWaX::MainSplitterWindow::RightPane::RearrangerPane::BitmapButton {
    use v5.14;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
    );

    ##########################################

    has 'bitmap_button' => (
        is          => 'rw',
        isa         => 'Wx::BitmapButton',
        lazy_build  => 1,
        handles     => {
            Enable          => "Enable",
            GetId           => "GetId",
            GetBitmapLabel  => "GetBitmapLabel",
            GetLabel        => "GetLabel",
            SetBitmapLabel  => "SetBitmapLabel",
            SetToolTip      => "SetToolTip",
        }
    );

    has 'bitmap'        => (is => 'rw', isa => 'Wx::Bitmap' );
    has 'bldg_id'       => (is => 'rw', isa => 'Maybe[Int]' );
    has 'name'          => (is => 'rw', isa => 'Maybe[Str]' );
    has 'level'         => (is => 'rw', isa => 'Maybe[Int]' );
    has 'efficiency'    => (is => 'rw', isa => 'Maybe[Int]' );
    has 'orig_x'        => (is => 'rw', isa => 'Maybe[Int]' );
    has 'orig_y'        => (is => 'rw', isa => 'Maybe[Int]' );
    has 'x'             => (is => 'rw', isa => 'Maybe[Int]' );
    has 'y'             => (is => 'rw', isa => 'Maybe[Int]' );

    sub BUILD {
        my($self, @params) = @_;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers
        $self->update_button_tooltip();

        return $self;
    };
    sub _build_bitmap_button {#{{{
        my $self = shift;
        return Wx::BitmapButton->new(
            $self->parent, -1,
            $self->bitmap,
        );
    }#}}}
    sub _set_events { }

    sub id_for_tooltip {#{{{
        my $self = shift;
        return $self->bldg_id;
    }#}}}
    sub level_for_label {#{{{
        my $self = shift;
        return sprintf "%02d", $self->level;
    }#}}}
    sub level_for_tooltip {#{{{
        my $self = shift;
        return $self->level;
    }#}}}
    sub name_for_tooltip {#{{{
        my $self = shift;
        return $self->name || 'Empty';
    }#}}}
    sub tooltip_contents {#{{{
        my $self = shift;
        return $self->name_for_tooltip . ' (level ' . $self->level_for_tooltip .  ', ID ' . $self->id_for_tooltip .')';
    }#}}}
    sub update_button_tooltip {#{{{
        my $self = shift;
        $self->SetToolTip( $self->tooltip_contents );
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
