
package LacunaWaX::MainSplitterWindow::RightPane::BodiesSummaryPane {
    use v5.14;
    use utf8;
    use open qw(:std :utf8);
    use Data::Dumper;
    use DateTime;
    use LacunaWaX::Model::Dates;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_SIZE);
    with 'LacunaWaX::Roles::MainSplitterWindow::RightPane';

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
        weak_ref    => 1,
    );

    has 'type' => (
        is          => 'rw',
        isa         => 'Str',
        required    => 1,
        documentation => q{
            This panel displays a list of body names and their IDs.  These
            bodies can be either planets or space stations, depending on the
            value of this type.

            'planet' == display planets
            <anything other than 'planet'> == display stations
        }
    );

    #########################################

    has 'ctrl_height' => (
        is          => 'rw',
        isa         => 'Int',
        lazy        => 1,
        clearer     => 'clear_ctrl_height',
        default     => sub {
            my $self = shift;
            my $size = $self->parent->GetClientSize;
            return ($size->height - 75);
        },
        documentation => q{
            The height, in pixels, of the text control displaying our bodies.
            The - 75 accounts for the bottom status bar.
        }
    );

    has 'ctrl_width' => (
        is          => 'rw',
        isa         => 'Int',
        lazy        => 1,
        clearer     => 'clear_ctrl_width',
        default     => sub {
            my $self = shift;
            my $size = $self->parent->GetClientSize;
            return ($size->width - 100);
        },
        documentation => q{
            The width, in pixels, of the text control displaying our bodies.
            The - 100  is arbitrary; we just don't need the thing to go all
            the way to the edge.
        }
    );

    has 'header_length' => (
        is          => 'rw',
        isa         => 'Int',
        default     => 0,
        lazy        => 1,
        documentation => q{
            The length of the header line in the text blob.  Calculated in _build_text.
        }
    );

    has 'text' => (
        is          => 'rw',
        isa         => 'Str',
        lazy_build  => 1,
        documentation => q{
            The text string displayed on-screen.
        }
    );

    has 'szr_header'    => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1   );
    has 'lbl_header'    => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1   );
    has 'txtctrl_text'  => (is => 'rw', isa => 'Wx::TextCtrl',      lazy_build => 1   );

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->szr_header->Add($self->lbl_header, 0, 0, 0);
        $self->content_sizer->Add($self->szr_header, 0, 0, 0);
        $self->content_sizer->AddSpacer(20);
        $self->content_sizer->Add($self->txtctrl_text, 0, 0, 0);

        return $self;
    }
    sub _build_lbl_header {#{{{
        my $self = shift;

        my $v = Wx::StaticText->new(
            $self->parent, -1,
            (lc $self->type eq 'planet') ? "Planets" : "Space Stations",
            wxDefaultPosition,
            Wx::Size->new(-1, 30)
        );
        $v->SetFont( wxTheApp->get_font('header_1') );
        return $v;
    }#}}}
    sub _build_txtctrl_text {#{{{
        my $self = shift;

        ### We're using a TextCtrl instead of a static text here because:
        ###     - We can change the style of part of a TextCtrl, but not of a
        ###       StaticText
        ###     - The TextCtrl is scrollable, and some of the SS lists are
        ###       going to be too long to fit.

        my $v = Wx::TextCtrl->new(
            $self->parent, -1,
            $self->text,
            wxDefaultPosition,
            Wx::Size->new($self->ctrl_width, $self->ctrl_height),
              wxTE_MULTILINE | wxTE_READONLY | wxTE_DONTWRAP | wxTE_NOHIDESEL | wxBORDER_NONE
        );

        ### The control already has no border.  Now set the background color
        ### and font so it just looks like a StaticText rather than an input.
        $v->SetBackgroundColour( wxTheApp->colours->background_gray );
        $v->SetFont( wxTheApp->get_font('modern_text_2') ); # fixed width

        ### Documentation for GetStyle says that it may return false if
        ### "styles are not supported on this platform".  Linux allows me to
        ### set styles, but not Get them (GetStyle gives me back undef).
        ### So I can't just modify the existing style; I have to create a new
        ### one and manually maintain the "defaults", like text and background
        ### colors.
        my $header_style = Wx::TextAttr->new(
            wxTheApp->colours->black,                       # text
            wxTheApp->colours->background_gray,             # background
            wxTheApp->get_font('bold_modern_text_2'),       # bold fixed width - different from the rest
        );

        ### Calling _build_text, which we've already done by referencing
        ### $self->text above, sets $self->header_length.
        my $rv = $v->SetStyle( 1, $self->header_length, $header_style );

        return $v;
    }#}}}
    sub _build_szr_header {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Header');
    }#}}}
    sub _build_text {#{{{
        my $self  = shift;

        my $status  = wxTheApp->game_client->empire_status;
        my $key     = (lc $self->type eq 'planet') ? "planets" : "space_stations";
        my $hr      = { reverse %{$status->{'empire'}{$key}} };  # name => id

        ### Get strlen of longest body name so we can calculate how many dots 
        ### to add.
        my $longest = 0;
        foreach my $name( keys %{$hr} ) {
            $longest = (length $name > $longest) ? length $name : $longest;
        }
        my $dotlen = $longest + 10;  # arbitrary; some dots in even the longest name to look nice

        my $indent = q{ }x3;

        my $dots = q{.} x($dotlen - (length 'Name'));
        my $text = sprintf("\n%s %-s %s %s\n\n", $indent, 'Name', $dots, "ID");
        $self->header_length( length $text );

        foreach my $name( sort keys %{$hr} ) {
            my $id      = $hr->{$name};
            my $dots    = q{.} x($dotlen - (length $name));
            $text      .= sprintf("%s %-s %s %s\n", $indent, $name, $dots, $id);
        }

        return $text;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_SIZE( $self->parent, sub{$self->OnResize(@_)} );
    }#}}}

    sub OnResize {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;    # Wx::SizeEvent

        $self->clear_ctrl_width;
        $self->clear_ctrl_height;

        $self->txtctrl_text->SetMinSize(
            Wx::Size->new(
                $self->ctrl_width,
                $self->ctrl_height,
            )
        );
        $self->txtctrl_text->SetMaxSize(
            Wx::Size->new(
                $self->ctrl_width,
                $self->ctrl_height,
            )
        );

    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

