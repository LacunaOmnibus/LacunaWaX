
package LacunaWaX::MainFrame::StatusBar::Gauge {
    use v5.14;
    use DateTime;
    use DateTime::TimeZone;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_TIMER);

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainFrame::StatusBar',
        required    => 1,
    );

    has 'position' => (
        is          => 'rw', 
        isa         => 'Wx::Point',
        required    => 1,
    );

    has 'size' => (
        is          => 'rw', 
        isa         => 'Wx::Size',
        required    => 1,
    );

    #########################################

    has 'gauge' => (
        is          => 'rw', 
        isa         => 'Wx::Gauge',
        lazy_build  => 1,
        handles     => {
            GetRange => 'GetRange',
            GetValue => 'GetValue',
            Pulse    => 'Pulse',
            SetRange => 'SetRange',
            SetValue => 'SetValue',
            Update   => 'Update',
        }
    );

    has 'timer' => (
        is          => 'rw', 
        isa         => 'Wx::Timer',
        lazy_build  => 1,
        handles => {
            start => 'Start',
            stop  => 'Stop',
        }
    );

    sub BUILD {
        my $self = shift;

        $self->_set_events();
        return $self;
    }
    sub _build_gauge {#{{{
        my $self = shift;
        my $g = Wx::Gauge->new(
            $self->parent->status_bar, -1, 100,
            $self->position, $self->size,
            wxGA_HORIZONTAL
        );
        $g->SetValue(0);
        return $g;
    }#}}}
    sub _build_timer {#{{{
        my $self = shift;
        my $t = Wx::Timer->new();
        $t->SetOwner( $self->gauge );
        return $t;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_TIMER(  $self->gauge, $self->timer->GetId, sub{$self->OnTimer(@_)} );
        return 1;
    }#}}}

    sub OnTimer {#{{{
        my $self = shift;

        $self->Pulse();
        wxTheApp->Yield;

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
