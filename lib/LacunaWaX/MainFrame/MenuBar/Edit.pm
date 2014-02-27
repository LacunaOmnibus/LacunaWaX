
package LacunaWaX::MainFrame::MenuBar::Edit {
    use v5.14;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use LacunaWaX::Dialog::Prefs;

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainFrame',
        required    => 1,
    );

    #############################################

    has 'itm_prefs'   => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);

    sub FOREIGNBUILDARGS {#{{{
        return; # Wx::Menu->new() takes no arguments
    }#}}}
    sub BUILD {
        my $self = shift;
        $self->Append( $self->itm_prefs );
        $self->_set_events();
        return $self;
    }

    sub _build_itm_prefs {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Preferences',
            'Preferences',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU($self->parent,  $self->itm_prefs->GetId, sub{$self->OnPrefs(@_)});
        return 1;
    }#}}}

    sub OnPrefs {#{{{
        my $self = shift;

        ### Determine starting point of Prefs window
        my $tlc         = wxTheApp->get_top_left_corner;
        my $self_origin = Wx::Point->new( $tlc->x + 30, $tlc->y + 30 );
        my $prefs_frame = LacunaWaX::Dialog::Prefs->new(
            title       => "Preferences",
            position    => $self_origin,
        );
        $prefs_frame->Show(1);
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
