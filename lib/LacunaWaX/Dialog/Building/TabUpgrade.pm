
package LacunaWaX::Dialog::Building::TabUpgrade {
    use v5.14;
    use DateTime::TimeZone;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON);

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
    );

    has 'szr_main'  => (is => 'rw', isa => 'Wx::BoxSizer',  lazy_build => 1);
    has 'pnl_main'  => (is => 'rw', isa => 'Wx::Panel',     lazy_build => 1);

    sub BUILD {
        my $self = shift;

        $self->tab_name( 'Upgrade' );

        my $upgrade_bar = LacunaWaX::Generics::BldgUpgradeBar->new(
            parent      => $self->pnl_main,
            bldg_obj    => $self->bldg_obj,
            bldg_view   => $self->bldg_view,
        );
        $self->szr_main->Add($upgrade_bar->szr_main, 0, 0, 0);

        $self->pnl_main->SetSizer( $self->szr_main );
        $self->_set_events;
        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        return 1;
    }#}}}

    sub _build_bldg_id {#{{{
        my $self = shift;
        return $self->bldg_hr->{'bldg_id'};
    }#}}}
    sub _build_pnl_main {#{{{
        my $self = shift;
        return Wx::Panel->new($self->parent->ntbk_features, -1, wxDefaultPosition, wxDefaultSize);
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;

        return wxTheApp->build_sizer($self->pnl_main, wxVERTICAL, 'Header');
    }#}}}


    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
