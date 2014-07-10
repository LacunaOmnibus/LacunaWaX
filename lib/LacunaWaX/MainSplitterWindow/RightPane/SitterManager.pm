
package LacunaWaX::MainSplitterWindow::RightPane::SitterManager {
    use v5.14;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE);
    with 'LacunaWaX::Roles::MainSplitterWindow::RightPane';

    use LacunaWaX::MainSplitterWindow::RightPane::SitterManager::SitterRow;

    has 'parent' => (
        is          => 'rw',
        isa         => 'Wx::ScrolledWindow',
        required    => 1,
    );

    #########################################

    has 'row_spacer_size'           => (is => 'rw', isa => 'Int',               lazy_build => 1                                 );
    has 'instructions_sizer'        => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1                                 );
    has 'add_sitter_button_sizer'   => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => 'horizontal'  );
    has 'header_sizer'              => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => 'vertical'    );
    has 'sitters_sizer'             => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => 'vertical'    );
    has 'lbl_header'                => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1                                 );
    has 'lbl_instructions'          => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1                                 );
    has 'btn_add_sitter'            => (is => 'rw', isa => 'Wx::Button',        lazy_build => 1                                 );

    sub BUILD {
        my $self = shift;
    
        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->header_sizer->Add($self->lbl_header, 0, 0, 0);
        $self->header_sizer->AddSpacer(10);
        $self->header_sizer->Add($self->instructions_sizer, 0, 0, 0);
        $self->header_sizer->AddSpacer(10);

        $self->fill_sitters_sizer();

        $self->content_sizer->AddSpacer(4);    # a little top margin
        $self->content_sizer->Add($self->header_sizer, 0, 0, 0);
        $self->content_sizer->AddSpacer(15);
        $self->content_sizer->Add($self->sitters_sizer, 0, 0, 0);

        $self->_set_events();
        return $self;
    };
    sub _build_add_sitter_button_sizer {#{{{
        my $self = shift;

        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Sitter Sizer');
        $v->AddSpacer(30);
        $v->Add($self->btn_add_sitter, 0, 0, 0);

        return $v;
    }#}}}
    sub _build_btn_add_sitter {#{{{
        my $self = shift;
        my $y = Wx::Button->new(
            $self->parent, -1, 
            "Add New Sitter",
            wxDefaultPosition, 
            Wx::Size->new(400, 35)
        );
        return $y;
    }#}}}
    sub _build_header_sizer {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Header Sizer');
        return $v;
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;
        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            "Sitter Password Manager",
            wxDefaultPosition, 
            Wx::Size->new(600, 35)
        );
        $y->SetFont( wxTheApp->get_font('header_1') );
        return $y;
    }#}}}
    sub _build_lbl_instructions {#{{{
        my $self = shift;

        my $text = "Your alliance leader should have your sitter.  Other than your alliance leader, only give your sitter out to players you trust.";
        my $size = Wx::Size->new(-1, -1);

        my $y = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition, $size
        );
        #$y->Wrap( $self->size->GetWidth - 100 ); # - 255 accounts for the vertical scrollbar
        $y->Wrap( $self->parent->GetSize->GetWidth - 100 ); # Subtract to account for the vertical scrollbar
        $y->SetFont( wxTheApp->get_font('para_text_1') );

        return $y;
    }#}}}
    sub _build_instructions_sizer {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxHORIZONTAL, 'Instructions');
        $v->Add($self->lbl_instructions, 0, 0, 0);
        return $v;
    }#}}}
    sub _build_row_spacer_size {#{{{
        ### Pixel size of the space between rows
        return 1;
    }#}}}
    sub _build_sitters_sizer {#{{{
        my $self = shift;
        my $y = Wx::BoxSizer->new(wxVERTICAL);
        return $y;
    }#}}}
    sub _build_size {#{{{
        my $self = shift;
        ### 700 px high allows for 18 saved sitters.  Past 18, the screen will 
        ### need to be scrolled down to get to the button.
        my $s = wxDefaultSize;
        $s->SetWidth(600);
        $s->SetHeight(700);
        return $s;
    }#}}}
    sub _build_title {#{{{
        my $self = shift;
        return 'Sitter Manager';
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_BUTTON( $self->parent, $self->btn_add_sitter->GetId,   sub{$self->OnAddSitter(@_)} );
        return 1;
    }#}}}

    sub fill_sitters_sizer {#{{{
        my $self = shift;

        my $schema = wxTheApp->main_schema;

        my $header = LacunaWaX::MainSplitterWindow::RightPane::SitterManager::SitterRow->new(
            parent      => $self,
            is_header   => 1,
        );
        $self->sitters_sizer->Add($header->main_sizer, 0, 0, 0);
        $header->show;

        my $rs = $schema->resultset('SitterPasswords')->search(
            { server_id => wxTheApp->server->id },
            ### LOWER(arg) works with SQLite.  May not work with another RDBMS.
            { order_by => { -asc => 'LOWER(player_name)' }, }
        );

        my $prev_row = undef;
        while(my $rec = $rs->next) {
            my $row = LacunaWaX::MainSplitterWindow::RightPane::SitterManager::SitterRow->new(
                parent      => $self,
                player_rec  => $rec,
            );
            $self->sitters_sizer->Add($row->main_sizer, 0, 0, 0);
            $self->sitters_sizer->AddSpacer( $self->row_spacer_size );
            wxTheApp->Yield;
            $row->show;

            if( $prev_row ) {
                $row->txt_name->MoveAfterInTabOrder($prev_row->btn_test);
            }

            $prev_row = $row;
        }

        ### Blank row to add new player info
        my $row = LacunaWaX::MainSplitterWindow::RightPane::SitterManager::SitterRow->new(
            parent      => $self,
        );
        $self->sitters_sizer->Add($row->main_sizer, 0, 0, 0);
        $self->sitters_sizer->AddSpacer( $self->row_spacer_size );
        $row->show;

        $self->sitters_sizer->AddSpacer(5);
        $self->sitters_sizer->Add($self->add_sitter_button_sizer, 0, 0, 0);
        return 1;
    }#}}}

    sub OnAddSitter {#{{{
        my $self    = shift;
        my $dialog  = shift;    # Wx::ScrolledWindow
        my $event   = shift;    # Wx::CommandEvent

        my $row = LacunaWaX::MainSplitterWindow::RightPane::SitterManager::SitterRow->new(
            parent      => $self,
        );
        
        ### We're going to insert a new, blank row into our sitter_sizer, but 
        ### need to know where to insert that row.
        ### 
        ### We don't know how many sitter rows already exist in our sizer in 
        ### total, but we do know how many items exist in the sizer after the 
        ### final row.
        ###
        ### Following the final SitterRow is:
        ###     - Horizontal spacer (appears after each row)
        ###     - Larger horizontal spacer (separates Sitter inputs from "Add New Row" sizer)
        ###     - "Add New Row" button sizer
        ###
        ### ...so we subtract 3 from $count.
        my @children = $self->sitters_sizer->GetChildren;
        my $count = scalar @children;
        $self->sitters_sizer->Insert( ($count - 3), $row->main_sizer );
        $self->sitters_sizer->InsertSpacer( ($count - 3), $self->row_spacer_size );
        $row->txt_name->SetFocus;

        $row->show;
        $self->parent->FitInside();
        $self->parent->Layout;

        ### On Windows XP (at least), adding a new row is leaving a very slight 
        ### artifact on the bottom border of the Player Name text control.  Just 
        ### mousing over that control removes the artifact.  It's not 
        ### interfering with anything, it's just ugly.
        ###
        ### Calling SetFocus on that txt_name control isn't just convenient (and 
        ### it is), it also removes that artifact.

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
