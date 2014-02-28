
package LacunaWaX::Roles::MainFrame::MenuBar::Menu {
    use v5.14;
    use Moose::Role;
    #use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    ### This should be a role I think

    has 'menu' => (
        is          => 'rw',
        isa         => 'Wx::Menu',
        lazy_build  => 1,
        handles => {
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
        },
    );

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainFrame',
        required    => 1,
    );

    sub _build_menu {#{{{
        my $self = shift;
        my $m = Wx::Menu->new();
        return $m;
    }#}}}

    no Moose::Role;
}

1;
