
package LacunaWaX::MainFrame::MenuBar {
    use v5.14;
    use Moose;
    use Wx qw(:everything);

    use LacunaWaX::MainFrame::MenuBar::Edit;
    use LacunaWaX::MainFrame::MenuBar::File;
    use LacunaWaX::MainFrame::MenuBar::Help;
    use LacunaWaX::MainFrame::MenuBar::Tools;

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::Window',
        required    => 1,
    );

    ##############################################

    has 'menu_bar' => (
        is          => 'rw',
        isa         => 'Wx::MenuBar',
        lazy_build  => 1,
        handles     => {
            Append              => "Append",
            AppendSubMenu       => "AppendSubMenu",
            Centre              => "Centre",
            Close               => "Close",
            Connect             => "Connect",
            Destroy             => "Destroy",
            Enable              => "Enable",
            Fit                 => "Fit",
            GetClientSize       => "GetClientSize",
            GetSize             => "GetSize",
            GetWindowStyleFlag  => "GetWindowStyleFlag",
            Layout              => "Layout",
            SetSize             => "SetSize",
            SetSizer            => "SetSizer",
            SetTitle            => "SetTitle",
            SetWindowStyle      => "SetWindowStyle",
            Show                => "Show",
        }
    );

    has 'show_test'   => (is => 'rw', isa => 'Int',  lazy => 1, default => 0,
        documentation => q{
            If true, the Tools menu will include a "Test Dialog" entry, which 
            will display Dialog/Test.pm, which I'm using to play with controls 
            etc.
            Should generally be off.
        }
    );

    has 'menu_file'     => (is => 'rw', isa => 'LacunaWaX::MainFrame::MenuBar::File',   lazy_build => 1);
    has 'menu_edit'     => (is => 'rw', isa => 'LacunaWaX::MainFrame::MenuBar::Edit',   lazy_build => 1);
    has 'menu_tools'    => (is => 'rw', isa => 'LacunaWaX::MainFrame::MenuBar::Tools',  lazy_build => 1);
    has 'menu_help'     => (is => 'rw', isa => 'LacunaWaX::MainFrame::MenuBar::Help',   lazy_build => 1);

    has 'menu_list'     => (is => 'rw', isa => 'ArrayRef', lazy => 1,
        default => sub {
            [qw(
                menu_file
                menu_edit
                menu_tools
                menu_help
            )]
        },
        documentation => q{
            If you add a new menu to the bar, be sure to add its name to this list please.
        }
    );

    sub BUILD {
        my $self = shift;

        $self->Append( $self->menu_file->menu,   "&File");
        $self->Append( $self->menu_edit->menu,   "&Edit");
        $self->Append( $self->menu_tools->menu,  "&Tools");
        $self->Append( $self->menu_help->menu,   "&Help");

        return $self;
    }
    sub _build_menu_bar {#{{{
        my $self = shift;
        return Wx::MenuBar->new();
    }#}}}
    sub _build_menu_file {#{{{
        my $self = shift;
        return LacunaWaX::MainFrame::MenuBar::File->new(
            parent => $self->parent,   # MainFrame, not this Menu, is the parent.
        );
    }#}}}
    sub _build_menu_file_connect {#{{{
        my $self = shift;
        return LacunaWaX::MainFrame::MenuBar::File::Connect->new(
            parent => $self->parent,   # MainFrame, not this Menu, is the parent.
        );
    }#}}}
    sub _build_menu_edit {#{{{
        my $self = shift;
        return LacunaWaX::MainFrame::MenuBar::Edit->new(
            parent => $self->parent,   # MainFrame, not this Menu, is the parent.
        );
    }#}}}
    sub _build_menu_help {#{{{
        my $self = shift;
        return LacunaWaX::MainFrame::MenuBar::Help->new(
            parent => $self->parent,   # MainFrame, not this Menu, is the parent.
        );
    }#}}}
    sub _build_menu_tools {#{{{
        my $self = shift;
        return LacunaWaX::MainFrame::MenuBar::Tools->new(
            parent      => $self->parent,   # MainFrame, not this Menu, is the parent.
            show_test   => $self->show_test,
        );
    }#}}}
    sub _set_events { }

    ### Display or gray out any menu items that need it based on whether we're 
    ### currently connected or not.
    ### Individual menu classes should respond to this as needed.
    sub show_connected {#{{{
        my $self = shift;
        foreach my $submenu( @{$self->menu_list} ) {
            $self->$submenu->show_connected if $self->$submenu->can('show_connected');
        }
        return 1;
    }#}}}
    sub show_not_connected {#{{{
        my $self = shift;
        foreach my $submenu( @{$self->menu_list} ) {
            $self->$submenu->show_connected if $self->$submenu->can('show_connected');
        }
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
