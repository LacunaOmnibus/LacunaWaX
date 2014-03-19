
package LacunaWaX::MainFrame::StatusBar {
    use v5.14;
    use DateTime;
    use DateTime::TimeZone;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_SIZE EVT_TIMER);

    use LacunaWaX::MainFrame::StatusBar::Gauge;

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainFrame',
        required    => 1,
    );

    #########################################

    has 'caption' => (
        is          => 'rw',
        isa         => 'Str',
        lazy_build  => 1,
    );

    has 'gauge' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainFrame::StatusBar::Gauge',
        lazy_build  => 1,
    );

    has [ 'old_h', 'old_w' ] => (
        is      => 'rw',
        isa     => 'Int',
        lazy    => 1,
        default => 0,
    );

    has [ 'rect_caption', 'rect_clock', 'rect_gauge' ] => (
        is      => 'rw',
        isa     => 'Int',
        lazy    => 1,
        default => 0,
    );

    has 'status_bar' => (
        is          => 'rw',
        isa         => 'Wx::StatusBar',
        lazy_build => 1,
    );

    has 'timer' => (
        is          => 'rw', 
        isa         => 'Wx::Timer',
        lazy_build  => 1,
        handles => {
            start_ticking => 'Start',
            stop_ticking  => 'Stop',
        }
    );


    sub BUILD {
        my $self = shift;

        ### Set rectangle order
        $self->rect_caption(0);
        $self->rect_clock(1);
        $self->rect_gauge(2);

        ### Force the clock to show up immediately rather than waiting for the 
        ### first timer event to kick off, which will take a second.
        $self->update_time();

        ### Send 1-second timer events to ourself to update the clock.
        $self->start_ticking( 1000, wxTIMER_CONTINUOUS );

        ### Resets the whole bar, including the gauge.
        $self->bar_reset;

        $self->_set_events();

        return $self;
    }
    sub _build_status_bar {#{{{
        my $self = shift;

        my $y;
        unless( $y = $self->parent->GetStatusBar ) {
            ### Don't recreate the statusbar if it already exists, as in the 
            ### transition from the intro panel to the main splitter window.
            $y = $self->parent->CreateStatusBar(3);
        }
        return $y;
    }#}}}
    sub _build_caption {#{{{
        my $self = shift;
        return wxTheApp->GetAppName;
    }#}}}
    sub _build_gauge {#{{{
        my $self = shift;

        my $rect = $self->status_bar->GetFieldRect( $self->rect_gauge );
        my $pos  = Wx::Point->new( $rect->x, $rect->y ); 
        my $size = Wx::Size->new( $rect->width, $rect->height );

        my $g = LacunaWaX::MainFrame::StatusBar::Gauge->new(
            parent      => $self,
            position    => $pos,
            size        => $size,
        );
        return $g;
    }#}}}
    sub _build_timer {#{{{
        my $self = shift;
        my $t = Wx::Timer->new();
        $t->SetOwner( $self->status_bar );
        return $t;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_SIZE(   $self->status_bar,                      sub{$self->OnResize(@_)}    );
        EVT_TIMER(  $self->status_bar, $self->timer->GetId, sub{$self->OnClockTick(@_)} );
        return 1;
    }#}}}

    sub bar_reset {#{{{
        my $self = shift;
        $self->status_bar->DestroyChildren();
        $self->status_bar->SetStatusWidths(-5, -3, -2);
        $self->status_bar->SetStatusText( $self->caption, $self->rect_caption );

        my $rect = $self->status_bar->GetFieldRect( $self->rect_gauge );
        $self->gauge( $self->_build_gauge );
        wxTheApp->Yield;

        $self->status_bar->Update;
        return $self->status_bar;
    }#}}}
    sub change_caption {#{{{
        my $self = shift;
        my $new_text = shift;
        my $old_text = $self->status_bar->GetStatusText( $self->rect_caption );
        $self->caption($new_text);
        $self->status_bar->SetStatusText( $new_text, $self->rect_caption );
        return $old_text;
    }#}}}
    sub endthrob {#{{{
        my $self = shift;
        $self->gauge->stop();
        $self->bar_reset();
        $self->status_bar->GetParent->SendSizeEvent();
    }#}}}
    sub hms_12 {#{{{
        my $self = shift;
        my $dt   = shift;
        my $str = sprintf "%02d:%02d:%02d %s", $dt->hour_12, $dt->minute, $dt->second, $dt->am_or_pm;
        return $str;
    }#}}}
    sub hms_24 {#{{{
        my $self = shift;
        my $dt   = shift;
        return $dt->hms;
    }#}}}
    sub throb {#{{{
        my $self    = shift;
        my $pause   = shift || 50;    # milliseconds
        $self->gauge->start( $pause, wxTIMER_CONTINUOUS );
    }#}}}
    sub update_time {#{{{
        my $self = shift;

        ### wxTheApp->time_zone is not set yet on the very first tick, so pick
        ### a default.
        my $tz_loc  = wxTheApp->time_zone || DateTime::TimeZone->new( name => 'local' );
        my $gmt     = shift || DateTime->now( time_zone => 'GMT' );
        my $loc     = shift || DateTime->now( time_zone => $tz_loc );

        ### CHECK I should add an editable preference where the user can chose 
        ### between 12 and 24 hour time.  For now, I'm forcing 12.
        my $type = wxTheApp->clock_type || 12;
        my $status = ($type == 12)
            ? "Here: " . $self->hms_12($loc). " | GMT: " . $self->hms_12($gmt)
            : "Here: " . $self->hms_24($loc). " | GMT: " . $self->hms_24($gmt);

        $self->status_bar->SetStatusText( $status, $self->rect_clock );
        wxTheApp->Yield;

        return 1;
    }#}}}

    sub OnResize {#{{{
        my($self, $status_bar, $event) = @_;

        my $mf = $self->parent->frame;
        my $current_size = $mf->GetSize;
        if( $current_size->width != $self->old_w or $current_size->height != $self->old_h ) {
            $self->bar_reset;    # otherwise the throbber gauge gets all screwy
            $self->old_w( $current_size->width );
            $self->old_h( $current_size->height );
        } 

        return 1;
    }#}}}
    sub OnClockTick {#{{{
        my $self = shift;
        my $bar  = shift;   # Wx::StatusBar
        my $evt  = shift;   # Wx::TimerEvent

        $self->update_time;

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
