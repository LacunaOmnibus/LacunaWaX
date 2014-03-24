
### Need to add another grid sizer with SendShipRow objects.  I'll probably 
### want to create a SendShipRow class first.

package LacunaWax::Dialog::MissionEditor::TabObjective {
    use v5.14;
    use Data::UUID;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_COMBOBOX);
    use Wx::Perl::TextValidator;

    use LacunaWaX::Dialog::MissionEditor::ResourceRow;

    has 'parent' => (
        is          => 'rw',
        isa         => 'LacunaWaX::Dialog::MissionEditor',
        required    => 1,
    );

    #################################

    has [qw( btn_add_row )] => (
        is          => 'rw',
        isa         => 'Wx::Button',
        lazy_build  => 1
    );

    has [qw( lbl_instructions )] => (
        is          => 'rw',
        isa         => 'Wx::StaticText',
        lazy_build  => 1
    );

    has 'pnl_main' => (
        is          => 'rw',
        isa         => 'Wx::Panel',
        lazy_build  => 1,
    );

    has 'szr_grid_data' => (
        is          => 'rw',
        isa         => 'Wx::FlexGridSizer',
        lazy_build  => 1
    );

    has 'szr_main' => (
        is          => 'rw',
        isa         => 'Wx::Sizer',
        lazy_build  => 1
    );

    has 'rows' => (
        is          => 'rw',
        isa         => 'HashRef[LacunaWaX::Dialog::MissionEditor::ResourceRow]',
        default     => sub{ {} },
    );

    has 'uuid' => (
        is          => 'ro',
        isa         => 'Data::UUID',
        default     => sub{ Data::UUID->new() },
    );

    sub BUILD {
        my $self = shift;

        ### Start with one objective row showing.  The user can add more if 
        ### needed.
        $self->add_row();

        $self->szr_main->AddSpacer(20);
        $self->szr_main->Add( $self->lbl_instructions );
        $self->szr_main->Add( $self->szr_grid_data );
        $self->szr_main->Add( 0, 20, 0 );
        $self->szr_main->Add( $self->btn_add_row );

        $self->pnl_main->SetSizer( $self->szr_main );

        $self->_set_events;
        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON(     $self->pnl_main,  $self->btn_add_row->GetId,     sub{$self->OnAddObjective(@_)}    );
        return 1;
    }#}}}

    sub _build_btn_add_row {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->pnl_main, -1, "Add Another Material Objective");
        $v->Enable(1);
        return $v;
    }#}}}
    sub _build_lbl_instructions {#{{{
        my $self = shift;

        my $inst = "OBJECTIVE INSTRUCTIONS GO HERE.";

        my $v = Wx::StaticText->new(
            $self->pnl_main, -1, 
            $inst, 
            wxDefaultPosition, 
            Wx::Size->new(365,25)
        );

        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_pnl_main {#{{{
        my $self = shift;
        my $v = Wx::Panel->new($self->parent->notebook, -1, wxDefaultPosition, wxDefaultSize);
        return $v;
    }#}}}
    sub _build_szr_grid_data {#{{{
        my $self = shift;
        my $v = Wx::FlexGridSizer->new( 0, 2, 10, 5 );   # r, c, vgap, hgap
        return $v;
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;
        my $v = Wx::BoxSizer->new(wxVERTICAL);
        return $v;
    }#}}}

    sub add_row {#{{{
        my $self    = shift;
        my $delbtn  = shift // 1;

        ### Create a UUID that'll be used to associate the button with its 
        ### ResourceRow object.
        my $bin_uuid = $self->uuid->create();
        my $txt_uuid = $self->uuid->to_string($bin_uuid);

        ### Add a blank row to our sizer
        my $numrows = $self->szr_grid_data->GetRows();
        $self->szr_grid_data->SetRows( $numrows + 1 );

        ### Make a new row, put it in our hashref keyed off that UUID, and add 
        ### it to our grid
        my $row = LacunaWax::Dialog::MissionEditor::ResourceRow->new(
            parent  => $self,
            type    => 'objective',
        );
        $self->rows->{$txt_uuid} = $row;
        $self->szr_grid_data->Add( $row->pnl_main );
        
        ### No delete button for the first row
        unless( $delbtn ) {
            $self->szr_grid_data->Add( 0, 0, 0 );
            return 1;
        }

        ### Create button, name it our UUID, set up its event, add it to our 
        ### grid
        my $butt = Wx::Button->new(
            $self->pnl_main, -1, 
            'X',
            wxDefaultPosition, Wx::Size->new(30,25),
            0,  # style
            Wx::Perl::TextValidator->new( '.+' ),
            $txt_uuid,
        );
        $butt->SetForegroundColour( Wx::Colour->new(255, 0, 0) );
        $self->szr_grid_data->Add( $butt );
        EVT_BUTTON( $self->pnl_main, $butt->GetId, sub{$self->OnDelRow(@_, $butt)} );

        $self->szr_grid_data->Layout();
        return 1;
    }#}}}

    sub OnAddObjective {#{{{
        my $self    = shift;
        $self->add_row();
        $self->pnl_main->Layout();
        return 1;
    }#}}}
    sub OnDelRow {#{{{
        my $self    = shift;
        my $panel   = shift;    # Wx::Panel
        my $event   = shift;    # Wx::CommandEvent
        my $button  = shift;    # Wx::Button

        my $uuid = $button->GetName;
        my $numrows = $self->szr_grid_data->GetRows();

=pod

While the GridSizer knows how many rows and columns it was created with, 
either via its constructor or SetRows(), it doesn't have a true idea of what a 
row is.  Think of it as an array, with each individual element being a single 
field in the grid.  This means we can't just tell it to "delete row 3".

    +--------------------+---------------+
    | ResourceRow object | delete button |
    | ResourceRow object | delete button |
    | ResourceRow object | delete button |
    +--------------------+---------------+

To delete a "row":
    - We're dealing with two columns, and the delete button is in the second 
      column.
        - So on the third "row", the delete button is occupying offset 5 in 
          the grid.
    - Also, when we built the ResourceRow and button objects, we created a 
      UUID.  The ResourceRows are in a hash keyed off that UUID, and the 
      associated button's name is that UUID.

    - This event method is being handed a copy of the delete button clicked 
      (in $button).

    - Iterate all children of the Grid.  If the child is a Wx::Window, check 
      its ID and see if it's the same ID as the $button we were handed.
        - If so, we have the correct grid offset of the clicked button.

    - Remove both the clicked delete button (current offset) and its 
      associated row (current offset - 1) from the grid.

    - Now, using the button's name (the UUID), find the associated ResourceRow 
      from the $self->rows hashref (keyed off that UUID).  Call that 
      ResourceRow's clearme() method and delete the entry from $self->rows.

=cut

        ### $child is a SizerItem, but GetItem requires a integer offset, so 
        ### we do need $cnt.
        my $cnt = 0;
        for my $child ( $self->szr_grid_data->GetChildren() ) {
            my $itm = $self->szr_grid_data->GetItem( $cnt );
            if( my $win = $itm->GetWindow ) {
                if( $win->GetId == $button->GetId ) {
                    $self->szr_grid_data->Remove( $cnt );
                    $self->szr_grid_data->Remove( $cnt - 1 );
                    $button->Destroy;
                    $self->rows->{ $uuid }->clearme;
                    delete $self->rows->{ $uuid };
                    $self->szr_grid_data->Layout();
                    $self->pnl_main->Layout();
                    return 1;
                }
            }
            $cnt++;
        }

        say "whoopsie could not find row to delete";
        return 1;
    }#}}}


    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
