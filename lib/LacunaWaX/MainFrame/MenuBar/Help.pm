
package LacunaWaX::MainFrame::MenuBar::Help {
    use v5.14;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);
    with 'LacunaWaX::Roles::GuiElement';

    ### Wx::Menu is a non-hash object.  Extending such requires 
    ### MooseX::NonMoose::InsideOut instead of plain MooseX::NonMoose.
    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';

    has 'itm_about' => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);

    sub FOREIGNBUILDARGS {#{{{
        return; # Wx::Menu->new() takes no arguments
    }#}}}
    sub BUILD {
        my $self = shift;
        $self->Append( $self->itm_about );
        return $self;
    }

    sub _build_itm_about {#{{{
        my $self = shift;
        my $v = Wx::MenuItem->new(
            $self, -1,
            '&About',
            'Show about dialog',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
        return $v;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU($self->parent,  $self->itm_about->GetId, sub{$self->OnAbout(@_)});
    }#}}}

    sub OnAbout {#{{{
        my $self  = shift;
        my $frame = shift;  # Wx::Frame
        my $event = shift;  # Wx::CommandEvent
        my $ad = LacunaWaX::Dialog::About->new(
            app         => $self->app,
            ancestor    => $self,
            parent      => undef,
        );
        $ad->show();
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
