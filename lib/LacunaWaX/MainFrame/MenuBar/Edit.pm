
package LacunaWaX::MainFrame::MenuBar::Edit {
    use v5.14;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use LacunaWaX::Dialog::Prefs;
    with 'LacunaWaX::Roles::MainFrame::MenuBar::Menu';

    has 'itm_copy'      => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_prefs'     => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);

    sub BUILD {
        my $self = shift;
        ### See the right pane's DefaultPane and figure out how to change its 
        ### StaticText to a TextCtrl.  At which point, the itm_copy below 
        ### should (maybe) work.
        #$self->Append( $self->itm_copy );
        $self->Append( $self->itm_prefs );
        $self->_set_events();
        return $self;
    }

    sub _build_itm_copy {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self->menu, -1,
            '&Copy',
            'Copy selected text',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_prefs {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self->menu, -1,
            '&Preferences',
            'Preferences',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU($self->parent,  $self->itm_prefs->GetId,   sub{$self->OnPrefs(@_)});
        EVT_MENU($self->parent,  $self->itm_copy->GetId,    sub{$self->OnCopy(@_)});
        return 1;
    }#}}}

    sub OnCopy {#{{{
        my $self = shift;
        my $window = shift;

        #my $widget = $window->FindFocus();
        my $widget = Wx::Window::FindFocus();
        if( $widget->can('GetStringSelection') ) {
my $text = $widget->GetStringSelection();
say "--$text--";
        }
        else {
            say "No GetStringSelection for " . (ref $widget);
        }

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
