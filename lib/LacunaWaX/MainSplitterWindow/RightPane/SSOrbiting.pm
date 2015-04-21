use v5.14;

package LacunaWaX::MainSplitterWindow::RightPane::SSOrbiting {
    use Data::Dumper;
    use LacunaWaX::Model::Client;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE);
    with 'LacunaWaX::Roles::MainSplitterWindow::RightPane';

    has 'ancestor' => (
        is          => 'rw',
        isa         => 'LacunaWaX::MainSplitterWindow::RightPane',
        required    => 1,
    );

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
    );

    #########################################

    has 'count' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
        documentation => q{
            The total number of ships (not just the number on the current page).
            Set by get_orbiting().
        }
    );
    has 'page' => (
        is      => 'rw',
        isa     => 'Int',
        default => 1,
        documentation => q{
            The page we're currently on.  Will only change if more than 25 ships 
            are inbound and the user is playing with the pagination buttons.
        }
    );

    has 'orbiting' => (
        is      => 'rw',
        isa     => 'ArrayRef',
        default => sub{ [] },
        documentation => q{
            AoH of orbiting ships, set by get_orbiting().
        }
    );

    has 'police' => (
        is          => 'rw',
        isa         => 'Maybe[Games::Lacuna::Client::Buildings::PoliceStation]',
        lazy_build  => 1,
    );

    has 'planet_name'       => (is => 'rw', isa => 'Str',       required => 1);
    has 'planet_id'         => (is => 'rw', isa => 'Int',       lazy_build => 1);
    has 'szr_buttons'       => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1, documentation => 'horizontal' );
    has 'szr_header'        => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1, documentation => 'vertical' );
    has 'szr_list'          => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1, documentation => 'vertical' );

    has 'btn_next'          => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1);
    has 'btn_prev'          => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1);
    has 'lbl_header'        => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_instructions'  => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_incoming'      => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_page'          => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lst_orbiting'      => (is => 'rw', isa => 'Wx::ListCtrl',      lazy_build => 1);

### POD {#{{{

=pod

 ----------------------------------------------------------------
| HEADER                                                        |
|                                                               |
| Instructions blah lorem ipsum blarg                           |
| There are currently $CNT ships incoming.                      |
|                                                               |
|  ----------------------------------------------------------   |
|  | Type | Arrival Date | Origin Planet | Origin Empire    |   |
|  |--------------------------------------------------------|   |
|  |      |              |               |                  |   |
|  |      |              |               |                  |   |
|  |      |              |               |                  |   |
|  |      |              |               |                  |   |
|  |      |              |               |                  |   |
|  |      |              |               |                  |   |
|  |      |              |               |                  |   |
|  ----------------------------------------------------------   |
|                                                               |
|   < (button)                                    > (button)    |
|                                                               | 
 ----------------------------------------------------------------

=cut

### }#}}}

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->get_orbiting();
        $self->add_pagination();

        $self->szr_header->Add($self->lbl_header, 0, 0, 0);
        $self->szr_header->AddSpacer(5);
        $self->szr_header->Add($self->lbl_instructions, 0, 0, 0);
        $self->szr_header->AddSpacer(5);
        $self->szr_header->Add($self->lbl_incoming, 0, 0, 0);

        $self->show_list_page(1);
        $self->szr_list->Add($self->lst_orbiting, 0, 0, 0);

        $self->content_sizer->Add($self->szr_header, 0, 0, 0);
        $self->content_sizer->AddSpacer(20);
        $self->content_sizer->Add($self->szr_list, 0, 0, 0);
        $self->content_sizer->AddSpacer(5);
        $self->content_sizer->Add($self->szr_buttons, 0, 0, 0);

        $self->_set_events();
        return $self;
    }
    sub _build_btn_next {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->parent, -1, 
            "Next",
            wxDefaultPosition, 
            Wx::Size->new(50, 30)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        ### Disable next button unless we have more than 25 incoming.
        my $enabled = ($self->count > 25) ? 1 : 0;
        $v->Enable($enabled);
        return $v;
    }#}}}
    sub _build_btn_prev {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->parent, -1, 
            "Prev",
            wxDefaultPosition, 
            Wx::Size->new(50, 30)
        );
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        ### Always start the Prev button disabled.
        $v->Enable(0);
        return $v;
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "Ships Orbiting " . $self->planet_name,
            wxDefaultPosition, 
            Wx::Size->new(-1, 40)
        );
        $v->SetFont( wxTheApp->get_font('header_1') );
        return $v;
    }#}}}
    sub _build_lbl_instructions {#{{{
        my $self = shift;

        my $text = "Showing ships currently in orbit.";

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_lbl_incoming {#{{{
        my $self = shift;
        my $cnt  = shift || 0;;

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            q{},
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_lbl_page {#{{{
        my $self = shift;
        my $cnt  = shift || 0;;

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            q{Page 1},
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_lst_orbiting {#{{{
        my $self = shift;

        ### 700 gives us plenty of extra width to handle long empire and 
        ### planet names.
        ### 380 is as much height as we need to display 25 records, which is 
        ### the most we can have at one time.
        my $width  = 700;
        my $height = 580;

        my $v = Wx::ListCtrl->new(
            $self->parent, -1, 
            wxDefaultPosition, 
            Wx::Size->new($width, $height),
            wxLC_REPORT
            |wxSUNKEN_BORDER
            |wxLC_SINGLE_SEL
        );
        $v->InsertColumn(0, 'Type');
        $v->InsertColumn(1, 'Arrival Date');
        $v->InsertColumn(2, 'Planet                        ');   # Yeah, I know the spaces are hacky.
        $v->InsertColumn(3, 'Planet ID');
        $v->InsertColumn(4, 'Empire                        ');   # Yeah, I know the spaces are hacky.
        $v->InsertColumn(5, 'Empire ID');
        $v->SetColumnWidth(0,wxLIST_AUTOSIZE_USEHEADER);
        $v->SetColumnWidth(1,wxLIST_AUTOSIZE_USEHEADER);
        $v->SetColumnWidth(2,wxLIST_AUTOSIZE_USEHEADER);
        $v->SetColumnWidth(3,wxLIST_AUTOSIZE_USEHEADER);
        $v->SetColumnWidth(4,wxLIST_AUTOSIZE_USEHEADER);
        $v->SetColumnWidth(5,wxLIST_AUTOSIZE_USEHEADER);
        $v->Arrange(wxLIST_ALIGN_TOP);
        wxTheApp->Yield;
        return $v;

        return $v;
    }#}}}
    sub _build_planet_id {#{{{
        my $self = shift;
        return wxTheApp->game_client->planet_id( $self->planet_name );
    }#}}}
    sub _build_police {#{{{
        my $self = shift;

        my $police = try {
            wxTheApp->game_client->get_building($self->planet_id, 'Police Station');
        }
        catch {
            my $msg = (ref $_) ? $_->text : $_;
            wxTheApp->poperr($msg);
            return;
        };

        return( $police and ref $police eq 'Games::Lacuna::Client::Buildings::PoliceStation' ) ? $police : undef;
    }#}}}
    sub _build_szr_buttons {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Buttons');
    }#}}}
    sub _build_szr_header {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Header');
    }#}}}
    sub _build_szr_list {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'List');
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON( $self->parent, $self->btn_prev->GetId,        sub{$self->OnPrev(@_)}         );
        EVT_BUTTON( $self->parent, $self->btn_next->GetId,        sub{$self->OnNext(@_)}         );
        return;
    }#}}}

    sub add_pagination {#{{{
        my $self = shift;
        my $width = $self->lst_orbiting->GetSize->width;
        $width -= $self->btn_prev->GetSize->width;
        $width -= $self->btn_next->GetSize->width;
        $width -= $self->lbl_page->GetSize->width;
        $width /= 2;
        $self->szr_buttons->Add($self->btn_prev, 0, 0, 0);
        $self->szr_buttons->AddSpacer($width);
        $self->szr_buttons->Add($self->lbl_page, 0, 0, 0);
        $self->szr_buttons->AddSpacer($width);
        $self->szr_buttons->Add($self->btn_next, 0, 0, 0);
    }#}}}
    sub get_orbiting {#{{{
        my $self = shift;

=head2 get_orbiting

Gets the orbiting ships on our current page, which defaults to 1.

Sets the attributes:

 $self->count       # total number of ships incoming
 $self->orbiting    # AoH of ships orbiting

Returns true on success, false (with a poperr) on failure.

The list of ships is an AoH, each H representing a ship:

 {
  "id" : "id-goes-here",
  "name" : "CS3",
  "type_human" : "Cargo Ship",
  "type" : "cargo_ship",
  "date_arrived" : "02 01 2010 10:08:33 +0600",
  "from" : {
   "id" : "id-goes-here",
   "name" : "Earth",
   "empire" : {
    "id" : "id-goes-here",
    "name" : "Earthlings"
   }
  }
 }

=cut

        my $rv = try {
            $self->police->view_ships_orbiting($self->page);
        }
        catch {
            my $msg = (ref $_) ? $_->text : $_;
            wxTheApp->poperr($msg);
            return;
        };
        $rv and ref $rv eq 'HASH' or return undef;

        $self->count( $rv->{'number_of_ships'} );
        $self->orbiting( [] );
        foreach my $ship( sort{$a->{'date_arrived'} cmp $b->{'date_arrived'} }@{$rv->{'ships'}} ) {
            push( @{$self->orbiting}, $ship );
        }

        return 1;
    }#}}}
    sub show_list_page {#{{{
        my $self = shift;

        $self->update_lbl_incoming();
        $self->update_lbl_page();
        $self->lst_orbiting->DeleteAllItems;

        my $row = 0;
        foreach my $ship( @{$self->orbiting} ) {
            $self->lst_orbiting->InsertStringItem($row, $ship->{'type_human'});
            my $show_date = $ship->{'date_arrived'};
            $show_date =~ s/\s*\+\d{4}$//;     # Get rid of the "+0000" at the end of the date.
            $self->lst_orbiting->SetItem($row, 1, $show_date);

            my $from_planet = ($ship->{'from'}{'name'})
                ?  $ship->{'from'}{'name'} 
                : 'Unknown';
            $self->lst_orbiting->SetItem($row, 2, $from_planet);

            $self->lst_orbiting->SetItem($row, 3, $ship->{'from'}{'id'}) if $ship->{'from'}{'id'};

            my $from_empire = ($ship->{'from'}{'empire'}{'name'})
                ? $ship->{'from'}{'empire'}{'name'} : 'Unknown';
            $self->lst_orbiting->SetItem($row, 4, $from_empire);

            $self->lst_orbiting->SetItem($row, 5, $ship->{'from'}{'empire'}{'id'}) if $ship->{'from'}{'empire'}{'id'};

            $row++;
            wxTheApp->Yield;
        }
        if($row) {
            ### Only resize the ListCtrl if we added data to it (don't bother 
            ### if there are no ships incoming.)
            $self->lst_orbiting->SetColumnWidth(0, wxLIST_AUTOSIZE);            # type
            $self->lst_orbiting->SetColumnWidth(1, wxLIST_AUTOSIZE);            # inc date
            $self->lst_orbiting->SetColumnWidth(2, wxLIST_AUTOSIZE_USEHEADER);  # planet name
            $self->lst_orbiting->SetColumnWidth(3, wxLIST_AUTOSIZE_USEHEADER);  # pid
            $self->lst_orbiting->SetColumnWidth(4, wxLIST_AUTOSIZE_USEHEADER);  # empire name
            $self->lst_orbiting->SetColumnWidth(5, wxLIST_AUTOSIZE_USEHEADER);  # eid
        }

        $self->update_pagination;
        return 1;
    }#}}}
    sub update_lbl_incoming {#{{{
        my $self = shift;
        my $cnt  = shift || 0;

        my $text = "There are currently " . $self->count . " ships orbiting.";
        $self->lbl_incoming->SetLabel($text);
    }#}}}
    sub update_lbl_page {#{{{
        my $self = shift;
        my $cnt  = shift || 0;

        my $text = "Page " . $self->page;
        $self->lbl_page->SetLabel($text);
    }#}}}
    sub update_pagination {#{{{
        my $self = shift;
        my $cnt  = shift || 0;

        my $next_enabled = ($self->page * 25 <  $self->count) ? 1 : 0;
        $self->btn_next->Enable($next_enabled);

        my $prev_enabled = ($self->page > 1) ? 1 : 0;
        $self->btn_prev->Enable($prev_enabled);
    }#}}}

    sub OnClose {#{{{
        my $self = shift;
        return 1;
    }#}}}
    sub OnNext {#{{{
        my $self    = shift;
        my $panel   = shift;
        my $event   = shift;

        $self->page( $self->page + 1 );
        $self->get_orbiting;
        $self->show_list_page;

        return 1;
    }#}}}
    sub OnPrev {#{{{
        my $self    = shift;
        my $panel   = shift;
        my $event   = shift;

        $self->page( $self->page - 1);
        $self->get_orbiting;
        $self->show_list_page;

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
