use v5.14;

package LacunaWaX::MainSplitterWindow::RightPane::SSHealth {
    use Data::Dumper;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHECKBOX EVT_CLOSE EVT_TEXT);
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

    has 'police' => (
        is          => 'rw',
        isa         => 'Maybe[Games::Lacuna::Client::Buildings::PoliceStation]',
        lazy_build  => 1,
    );

    has 'number_formatter'  => (
        is      => 'rw',
        isa     => 'Number::Format', 
        lazy    => 1,
        default => sub{ Number::Format->new }
    );

    has 'alert_record' => (
        is          => 'rw',
        isa         => 'LacunaWaX::Model::Schema::SSAlerts',
        lazy_build  => 1,
    );

    has 'planet_name'       => (is => 'rw', isa => 'Str',       required => 1);
    has 'planet_id'         => (is => 'rw', isa => 'Int',       lazy_build => 1);
    has 'szr_header'        => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1, documentation => 'vertical' );

    has 'lbl_header'        => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'lbl_instructions'  => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);

    has 'szr_grid_opts'         => (is => 'rw', isa => 'Wx::FlexGridSizer', lazy_build => 1 );
    has 'chk_enable_alert'      => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'lbl_enable_alert'      => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'chk_hostile_ships'     => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'lbl_hostile_ships'     => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'chk_hostile_spies'     => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'lbl_hostile_spies'     => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'chk_own_star_seized'   => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'lbl_own_star_seized'   => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);
    has 'chk_mem_only_stations'   => (is => 'rw', isa => 'Wx::CheckBox',      lazy_build => 1);
    has 'lbl_mem_only_stations'   => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1);

    has 'lbl_min_res_pre'   => (is => 'rw', isa => 'Wx::StaticText', lazy_build => 1);
    has 'lbl_min_res_suf'   => (is => 'rw', isa => 'Wx::StaticText', lazy_build => 1);
    has 'txt_min_res'       => (is => 'rw', isa => 'Wx::TextCtrl',   lazy_build => 1);

    has 'szr_save' => (is => 'rw', isa => 'Wx::Sizer',  lazy_build => 1, documentation => 'vertical' );
    has 'btn_save' => (is => 'rw', isa => 'Wx::Button', lazy_build => 1);

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->szr_header->Add($self->lbl_header, 0, 0, 0);
        $self->szr_header->Add(5, 3, 0);
        $self->szr_header->Add($self->lbl_instructions, 0, 0, 0);

        $self->szr_grid_opts->Add( $self->lbl_enable_alert, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->chk_enable_alert, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->lbl_hostile_ships, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->chk_hostile_ships, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->lbl_hostile_spies, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->chk_hostile_spies, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->lbl_own_star_seized, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->chk_own_star_seized, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->lbl_mem_only_stations, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->chk_mem_only_stations, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->lbl_min_res_pre, 0, 0, 0 );
        $self->szr_grid_opts->Add( $self->txt_min_res, 0, 0, 0 );

        $self->szr_save->Add($self->btn_save, 0, 0, 0);

        $self->content_sizer->Add($self->szr_header, 0, 0, 0);
        $self->content_sizer->AddSpacer(20);
        $self->content_sizer->Add($self->szr_grid_opts, 0, 0, 0);
        $self->content_sizer->AddSpacer(20);
        $self->content_sizer->Add($self->szr_save, 0, 0, 0);

        $self->_set_events();
        return $self;
    }
    sub _build_alert_record {#{{{
        my $self = shift;
 
        my $schema = wxTheApp->main_schema;
        my $rec = $schema->resultset("SSAlerts")->find_or_create(
            {
                server_id   => wxTheApp->server->id,
                station_id  => $self->planet_id,
            },
            {
                key => 'one_alert_per_station',
            }
        );
        return $rec;
    }#}}}
    sub _build_btn_save {#{{{
        my $self = shift;
        my $v = Wx::Button->new($self->parent, -1, "Save Alert Preferences");
        $v->SetFont( wxTheApp->get_font('para_text_1') );
        return $v;
    }#}}}
    sub _build_chk_enable_alert {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Yes',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( $self->alert_record->enabled );

        return $v;
    }#}}}
    sub _build_lbl_enable_alert {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "Turn on alerts?",
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        my $tt = Wx::ToolTip->new( "If off, NO alerts will be produced for this station." );
        $v->SetToolTip($tt);
        return $v;
    }#}}}
    sub _build_chk_hostile_ships {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Yes',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( $self->alert_record->hostile_ships );

        return $v;
    }#}}}
    sub _build_lbl_hostile_ships {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "Enable hostile ship alerts?",
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        my $tt = Wx::ToolTip->new( "Alerts for incoming foreign ships." );
        $v->SetToolTip($tt);
        return $v;
    }#}}}
    sub _build_chk_hostile_spies {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Yes',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( $self->alert_record->hostile_spies );

        return $v;
    }#}}}
    sub _build_lbl_hostile_spies {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "Enable hostile spy alerts?",
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        my $tt = Wx::ToolTip->new( "Alerts for spies onsite who are not set to Counter Espionage." );
        $v->SetToolTip($tt);
        return $v;
    }#}}}
    sub _build_chk_own_star_seized {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Yes',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( $self->alert_record->own_star_seized );

        return $v;
    }#}}}
    sub _build_lbl_own_star_seized {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "Enable own star seizure alerts?",
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        my $tt = Wx::ToolTip->new( "Alerts if the station's own star is not seized by this station." );
        $v->SetToolTip($tt);
        return $v;
    }#}}}
    sub _build_chk_mem_only_stations {#{{{
        my $self = shift;
        my $v = Wx::CheckBox->new(
            $self->parent, -1, 
            'Yes',
            wxDefaultPosition, 
            Wx::Size->new(-1,-1), 
        );

        $v->SetFont( wxTheApp->get_font('para_text_2') );
        $v->SetValue( $self->alert_record->members_only_stations );

        return $v;
    }#}}}
    sub _build_lbl_mem_only_stations {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "Enable members only station alerts?",
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        my $tt = Wx::ToolTip->new( "Alerts if the station does not have 'Members Only Stations' turned on." );
        $v->SetToolTip($tt);
        return $v;
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "Monitor Health of " . $self->planet_name,
            wxDefaultPosition, 
            Wx::Size->new(-1, 68)
        );
        $v->SetFont( wxTheApp->get_font('header_1') );
        $v->Wrap( $self->parent->GetSize->GetWidth - 130 ); # accounts for the vertical scrollbar
        return $v;
    }#}}}
    sub _build_lbl_instructions {#{{{
        my $self = shift;

        my $text = "Sends mail to alert you to possible problems with a Space Station.  See Help for details.";

        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            $text,
            wxDefaultPosition, 
            Wx::Size->new(-1, 20)
        );
        $v->Wrap( $self->parent->GetSize->GetWidth - 130 ); # accounts for the vertical scrollbar
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_lbl_min_res_pre {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "Alert if any res drops below: ",
            wxDefaultPosition, 
            Wx::Size->new(-1, -1)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
        return $v;
    }#}}}
    sub _build_lbl_min_res_suf {#{{{
        my $self = shift;
        my $v = Wx::StaticText->new(
            $self->parent, -1, 
            "/ hr",
            wxDefaultPosition, 
            Wx::Size->new(-1, -1)
        );
        $v->SetFont( wxTheApp->get_font('para_text_2') );
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
    sub _build_szr_grid_opts {#{{{
        my $self = shift;
        return Wx::FlexGridSizer->new(5, 2, 5, 15);
    }#}}}
    sub _build_szr_header {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Header');
        return $v;
    }#}}}
    sub _build_szr_save {#{{{
        my $self = shift;
        return wxTheApp->build_sizer($self->parent, wxVERTICAL, 'Save');
    }#}}}
    sub _build_txt_min_res {#{{{
        my $self = shift;

        my $v = Wx::TextCtrl->new(
            $self->parent, -1, 
            '', 
            wxDefaultPosition, 
            Wx::Size->new(100,20)
        );

        $v->SetValue(
            $self->number_formatter->format_number( $self->alert_record->min_res || 0 )
        );

        my $tt = Wx::ToolTip->new( "If any resource per hour drops below this number, send an alert." );
        $v->SetToolTip($tt);

        return $v;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_TEXT(       $self->parent, $self->txt_min_res->GetId,           sub{$self->OnUpdateMinRes(@_)}  );
        EVT_BUTTON(     $self->parent, $self->btn_save->GetId,              sub{$self->OnSave(@_)}          );
        EVT_CHECKBOX(   $self->parent, $self->chk_enable_alert->GetId,      sub{$self->OnCheckEnable(@_)}   );
        EVT_CHECKBOX(   $self->parent, $self->chk_hostile_ships->GetId,     sub{$self->OnCheckShips(@_)}    );
        EVT_CHECKBOX(   $self->parent, $self->chk_hostile_spies->GetId,     sub{$self->OnCheckSpies(@_)}    );
        EVT_CHECKBOX(   $self->parent, $self->chk_own_star_seized->GetId,   sub{$self->OnCheckStar(@_)}     );
        EVT_CHECKBOX(   $self->parent, $self->chk_mem_only_stations->GetId, sub{$self->OnCheckMemOnlyStation(@_)}     );
        return;
    }#}}}

    sub enable_alerts_check_from_child {#{{{
        my $self    = shift;
        my $input   = shift;

        ### If the user turns on any of the Enable alerts, forcefully turn on 
        ### the main "Turn on alerts" checkbox as well.
        if( $input->GetValue() ) {
            $self->chk_enable_alert->SetValue(1);
        }
    }#}}}

    sub OnClose {#{{{
        my $self = shift;
        return 1;
    }#}}}
    sub OnCheckEnable {#{{{
        my $self = shift;

        unless( $self->chk_enable_alert->GetValue() ) {
            $self->chk_hostile_ships->SetValue(0);
            $self->chk_hostile_spies->SetValue(0);
            $self->chk_own_star_seized->SetValue(0);
            $self->chk_mem_only_stations->SetValue(0);
            $self->txt_min_res->SetValue(0);
        }

        return 1;
    }#}}}
    sub OnCheckShips {#{{{
        my $self    = shift;
        my $window  = shift;
        my $event   = shift;

        $self->enable_alerts_check_from_child( $self->chk_hostile_ships );

        return 1;
    }#}}}
    sub OnCheckSpies {#{{{
        my $self    = shift;
        my $window  = shift;
        my $event   = shift;

        $self->enable_alerts_check_from_child( $self->chk_hostile_spies );

        return 1;
    }#}}}
    sub OnCheckStar {#{{{
        my $self    = shift;
        my $window  = shift;
        my $event   = shift;

        $self->enable_alerts_check_from_child( $self->chk_own_star_seized );
        return 1;
    }#}}}
    sub OnCheckMemOnlyStation {#{{{
        my $self    = shift;
        my $window  = shift;
        my $event   = shift;

        $self->enable_alerts_check_from_child( $self->chk_mem_only_stations );
        return 1;
    }#}}}
    sub OnSave {#{{{
        my $self    = shift;
        my $parent  = shift;    # Wx::ScrolledWindow
        my $event   = shift;    # Wx::CommandEvent

        my $enabled = ( $self->chk_enable_alert->IsChecked ) ? 1 : 0;
        my $min_res = $self->txt_min_res->GetValue || 0;
           $min_res =~ s/\D//g;
           $min_res ||= 0;

        if( $min_res and $min_res < 1_000_000 ) {
            if( wxNO == wxTheApp->popconf("You're alerting on less than a million res/hour; that seems awfully low.  Are you sure that shouldn't be set higher?") ) {
                wxTheApp->popmsg("No save performed; fix your alert number and re-save.");
                return 0;
            }

            wxTheApp->popmsg("OK, it's your funeral.  But think hard about increasing that number or your station could get into trouble.");
        }

        $self->alert_record->enabled(               $enabled                                         );
        $self->alert_record->hostile_ships(         $self->chk_hostile_ships->GetValue()        || 0 );
        $self->alert_record->hostile_spies(         $self->chk_hostile_spies->GetValue()        || 0 );
        $self->alert_record->own_star_seized(       $self->chk_own_star_seized->GetValue()      || 0 );
        $self->alert_record->members_only_stations( $self->chk_mem_only_stations->GetValue()    || 0 );
        $self->alert_record->min_res(               $min_res                                         );
        $self->alert_record->update;

        my $msg = ($enabled)
            ? "Station alerts for " . $self->planet_name . " have been TURNED ON."
            : "Station alerts for " . $self->planet_name . " have been DISABLED.";

        wxTheApp->popmsg($msg);
        return 1;
    }#}}}
    sub OnUpdateMinRes {#{{{
        my $self    = shift;
        my $parent  = shift;    # Wx::ScrolledWindow
        my $event   = shift;    # Wx::CommandEvent

        my $num = $self->txt_min_res->GetValue;

        ### Remove the formatting, which is likely wrong now
        $num =~ s/\D//g;
        $num ||= 0;

        ### Apply correct formatting to the now digit-only $num
        my $formatted_num = $self->number_formatter->format_number($num);

        ### If our correctly-formatted number is not what's currently in the 
        ### text box, put it there.  The conditional exists because the update 
        ### itself will recurse back here again.
        unless( $formatted_num eq $self->txt_min_res->GetValue() ) {
            $self->txt_min_res->SetValue($formatted_num);
            $self->txt_min_res->SetInsertionPointEnd();
        }

        ### Turn the global alerts checkbox on if the user is attempting to 
        ### alert on a non-zero res number.
        $self->enable_alerts_check_from_child( $self->txt_min_res ) if $num;

        return 1;
    }#}}}

   no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
