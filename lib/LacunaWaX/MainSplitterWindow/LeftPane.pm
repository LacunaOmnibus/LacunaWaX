
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
        isa         => 'Wx::SplitterWindow',
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
        handles => {
            empty_tree => 'clear_children',
        }
    );

    sub BUILD {
        my $self = shift;

        $self->add_fresh_tree;
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
        return Wx::Panel->new($self->parent, -1, wxDefaultPosition, wxDefaultSize);
    }#}}}
    sub _build_main_sizer {#{{{
        my $self = shift;
        return Wx::BoxSizer->new(wxHORIZONTAL);
    }#}}}
    sub _set_events { }

    sub add_fresh_tree {#{{{
        my $self = shift;

=pod

Destroys the navigation tree if one exists, and creates a new one using the 
latest available data.

Called initially to create the tree when the LeftPane itself is first 
generated, then called again when a body's summary screen is displayed and 
LacunaWaX realizes for the first time that the body in question is actually a 
Space Station, and is therefore displaying the wrong sub-leaves.  On tree 
re-creation, the correct leaves will be shown.

=cut

        ### empty_tree destroys the BodiesTreeCtrl's wxwidget children.
        ### clear_bodies_tree then removes the bodies_tree Moose object from 
        ### LeftPane.
        $self->empty_tree();
        $self->clear_bodies_tree;

        if( $self->has_main_sizer ) {
            ### Clear(1) is meant to clear the sizer and destroy its children. 
            ### It crashes on Windows but is required on Linux.
            my $arg = ($^O eq 'linux') ? 1 : 0;
            $self->main_sizer->Clear($arg);
            $self->clear_main_sizer;
        }

        $self->main_sizer->Add($self->bodies_tree->treectrl, 1, wxEXPAND, 0);
        $self->main_sizer->SetMinSize(200, -1);
        $self->main_panel->SetSizer($self->main_sizer, 1);
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
