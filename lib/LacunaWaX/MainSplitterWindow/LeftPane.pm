
=pod

This absolutely must provide a main_panel as Wx::Panel for MainSplitterWindow to work.

=cut


package LacunaWaX::MainSplitterWindow::LeftPane {
    use v5.14;
    use English qw( -no_match_vars );
    use Moose;
    use Time::HiRes;
    use Try::Tiny;
    use Wx qw(:everything);

    use LacunaWaX::MainSplitterWindow::LeftPane::BodiesTreeCtrl;

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow',
        required    => 1,
    );

    #########################################

    has 'has_focus'     => (is => 'rw', isa => 'Int', lazy => 1, default => 0);
    has 'main_panel'    => (is => 'rw', isa => 'Wx::Panel', lazy_build => 1);
    has 'main_sizer'    => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1);

    has 'bodies_tree' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow::LeftPane::BodiesTreeCtrl',
        lazy_build  => 1,
    );

    sub BUILD {
        my $self = shift;

        $self->main_sizer->Add($self->bodies_tree->treeview->treectrl, 1, wxEXPAND, 0);
        $self->main_sizer->SetMinSize(200, -1);
        $self->main_panel->SetSizer($self->main_sizer, 1);

        return $self;
    }
    sub _build_bodies_tree {#{{{
        my $self = shift;

        $self->bodies_tree( 
            LacunaWaX::MainSplitterWindow::LeftPane::BodiesTreeCtrl->new( parent => $self->main_panel )
        );
    }#}}}
    sub _build_main_panel {#{{{
        my $self = shift;
        return Wx::Panel->new($self->parent->splitter_window, -1, wxDefaultPosition, wxDefaultSize);
    }#}}}
    sub _build_main_sizer {#{{{
        my $self = shift;
        return Wx::BoxSizer->new(wxHORIZONTAL);
    }#}}}
    sub _set_events { }

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
