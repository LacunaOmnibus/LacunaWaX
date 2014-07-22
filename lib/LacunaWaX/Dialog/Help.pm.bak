
package LacunaWaX::Dialog::Help {
    use v5.14;
    use Browser::Open;
    use Data::Dumper;
    use File::Basename;
    use File::Slurp;
    use File::Spec;
    use File::Util;
    use HTML::Scrubber;
    use HTML::TreeBuilder::XPath;
    use Lucy::Analysis::PolyAnalyzer;
    use Lucy::Index::Indexer;
    use Lucy::Plan::Schema;
    use Lucy::Plan::FullTextType;
    use Lucy::Search::IndexSearcher;
    use Moose;
    use Template;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CLOSE EVT_HTML_LINK_CLICKED EVT_SIZE EVT_TEXT_ENTER);

    extends 'LacunaWaX::Dialog::NonScrolled';

    has 'index_file'    => (is => 'rw', isa => 'Str',       lazy_build => 1);
    has 'history'       => (is => 'rw', isa => 'ArrayRef',  lazy_build => 1);
    has 'history_idx'   => (is => 'rw', isa => 'Int',       lazy_build => 1);

    has 'prev_click_href' => (is => 'rw', isa => 'Str', lazy => 1, default => q{},
        documentation => q{ See OnLinkClicked for details.  }
    );
    has 'summary_length'    => (is => 'rw', isa => 'Int',       lazy => 1,      default => 120  );
    has 'tt'                => (is => 'rw', isa => 'Template',  lazy_build => 1                 );

    has 'title' => (is => 'rw', isa => 'Str',       lazy_build => 1);
    has 'size'  => (is => 'rw', isa => 'Wx::Size',  lazy_build => 1);

    has 'nav_img_h'     => (is => 'rw', isa => 'Int',  lazy => 1, default => 32     );
    has 'nav_img_w'     => (is => 'rw', isa => 'Int',  lazy => 1, default => 32     );
    has 'search_box_h'  => (is => 'rw', isa => 'Int',  lazy => 1, default => 32     );
    has 'search_box_w'  => (is => 'rw', isa => 'Int',  lazy => 1, default => 150    );
    has 'home_spacer_w' => (is => 'rw', isa => 'Int',  lazy => 1, default => 10     );

    has 'bmp_home'          => (is => 'rw', isa => 'Wx::BitmapButton',  lazy_build => 1);
    has 'bmp_left'          => (is => 'rw', isa => 'Wx::BitmapButton',  lazy_build => 1);
    has 'bmp_right'         => (is => 'rw', isa => 'Wx::BitmapButton',  lazy_build => 1);
    has 'bmp_search'        => (is => 'rw', isa => 'Wx::BitmapButton',  lazy_build => 1);
    has 'htm_window'        => (is => 'rw', isa => 'Wx::HtmlWindow',    lazy_build => 1);
    has 'szr_html'          => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => q{vertical});
    has 'szr_navbar'        => (is => 'rw', isa => 'Wx::Sizer',         lazy_build => 1, documentation => q{horizontal});
    has 'txt_search'        => (is => 'rw', isa => 'Wx::TextCtrl',      lazy_build => 1, documentation => q{horizontal});

    ### Doesn't follow the Hungarian notation convention used for the other 
    ### WxWindows on purpose, to set it apart from the other controls.    
    ### main_sizer is required by our NonScrolled parent.
    has 'main_sizer' => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1, documentation => q{vertical});

    sub BUILD {
        my($self, @params) = @_;
        $self->Show(0);

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->make_search_index;

        $self->SetTitle( $self->title );
        $self->make_navbar();

        $self->szr_html->Add($self->htm_window, 0, 0, 0);

        $self->main_sizer->AddSpacer(5);
        $self->main_sizer->Add($self->szr_navbar, 0, 0, 0);
        $self->main_sizer->AddSpacer(5);
        $self->main_sizer->Add($self->szr_html, 0, 0, 0);

        unless( $self->load_html_file($self->index_file) ) {
            wxTheApp->poperr("GONG!  Unable to load help files!", "GONG!");
            $self->Destroy;
            return;
        }

        $self->_set_events;
        $self->init_screen();
        $self->Show(1);
        return $self;
    };
    sub _build_bmp_home {#{{{
        my $self = shift;
        my $img = wxTheApp->get_image('app/home.png');
        $img->Rescale($self->nav_img_w - 10, $self->nav_img_h - 10);    # see build_bmp_left
        my $bmp = Wx::Bitmap->new($img);
        my $v = Wx::BitmapButton->new(
            $self->dialog, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($self->nav_img_w, $self->nav_img_h),
            wxBU_AUTODRAW 
        );
        return $v;
    }#}}}
    sub _build_bmp_left {#{{{
        my $self = shift;
        my $img = wxTheApp->get_image('app/arrow-left.png');
        ### On Ubuntu, there's a margin inside the button.  If the image is 
        ### the same size as the button, that margin obscures part of the 
        ### image.  So the image must be a bit smaller than the button.
        $img->Rescale($self->nav_img_w - 10, $self->nav_img_h - 10);
        my $bmp = Wx::Bitmap->new($img);
        my $v = Wx::BitmapButton->new(
            $self->dialog, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($self->nav_img_w, $self->nav_img_h),
            wxBU_AUTODRAW 
        );
        return $v;
    }#}}}
    sub _build_bmp_right {#{{{
        my $self = shift;
        my $img = wxTheApp->get_image('app/arrow-right.png');
        $img->Rescale($self->nav_img_w - 10, $self->nav_img_h - 10);    # see build_bmp_left
        my $bmp = Wx::Bitmap->new($img);
        return Wx::BitmapButton->new(
            $self->dialog, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($self->nav_img_w, $self->nav_img_h),
            wxBU_AUTODRAW 
        );
    }#}}}
    sub _build_bmp_search {#{{{
        my $self = shift;
        my $img = wxTheApp->get_image('app/search.png');
        $img->Rescale($self->nav_img_w - 10, $self->nav_img_h - 10);    # see build_bmp_left
        my $bmp = Wx::Bitmap->new($img);
        my $v = Wx::BitmapButton->new(
            $self->dialog, -1, 
            $bmp,
            wxDefaultPosition,
            Wx::Size->new($self->nav_img_w, $self->nav_img_h),
            wxBU_AUTODRAW 
        );
        return $v;
    }#}}}
    sub _build_history {#{{{
        my $self = shift;
        return [$self->index_file];
    }#}}}
    sub _build_history_idx {#{{{
        return 0;
    }#}}}
    sub _build_htm_window {#{{{
        my $self = shift;

        my $v = Wx::HtmlWindow->new(
            $self->dialog, -1, 
            wxDefaultPosition, 
            Wx::Size->new($self->get_html_width, $self->get_html_height),
            wxHW_SCROLLBAR_AUTO
            |wxSIMPLE_BORDER
        );
        return $v;
    }#}}}
    sub _build_index_file {#{{{
        return 'index.html';
    }#}}}
    sub _build_size {#{{{
        my $self = shift;
        return Wx::Size->new( 600, 700 );
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->dialog, wxVERTICAL, 'Main Sizer');
        return $v;
    }#}}}
    sub _build_szr_html {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->dialog, wxVERTICAL, 'LacunaWaX Help');
        return $v;
    }#}}}
    sub _build_szr_navbar {#{{{
        my $self = shift;
        my $v = wxTheApp->build_sizer($self->dialog, wxHORIZONTAL, 'Nav bar');
        return $v;
    }#}}}
    sub _build_title {#{{{
        return 'LacunaWaX Help';
    }#}}}
    sub _build_tt {#{{{
        my $self = shift;
        my $tt = Template->new(
            INCLUDE_PATH => wxTheApp->globals->dir_html,
            INTERPOLATE => 1,
            OUTPUT_PATH => wxTheApp->globals->dir_html,
            WRAPPER => 'wrapper',
        );
        return $tt;
    }#}}}
    sub _build_txt_search {#{{{
        my $self = shift;
        my $v = Wx::TextCtrl->new(
            $self->dialog, -1, 
            q{},
            wxDefaultPosition, 
            Wx::Size->new($self->search_box_w, $self->search_box_h),
            wxTE_PROCESS_ENTER
        );
        $v->SetToolTip("Type search terms and hit <enter> or click the search button");
        return $v;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE(              $self,                              sub{$self->OnClose(@_)}         );
        EVT_BUTTON(             $self,  $self->bmp_home->GetId,     sub{$self->OnHomeNav(@_)}       );
        EVT_BUTTON(             $self,  $self->bmp_left->GetId,     sub{$self->OnLeftNav(@_)}       );
        EVT_BUTTON(             $self,  $self->bmp_right->GetId,    sub{$self->OnRightNav(@_)}      );
        EVT_BUTTON(             $self,  $self->bmp_search->GetId,   sub{$self->OnSearchNav(@_)}     );
        EVT_HTML_LINK_CLICKED(  $self,  $self->htm_window->GetId,   sub{$self->OnLinkClicked(@_)}   );
        EVT_SIZE(               $self,                              sub{$self->OnResize(@_)}        );
        EVT_TEXT_ENTER(         $self,  $self->txt_search->GetId,   sub{$self->OnSearchNav(@_)}     );
        return 1;
    }#}}}

    sub clean_text {#{{{
        my $self = shift;
        my $text = shift;
        $text = " $text";
        $text =~ s/[\r\n]/ /g;
        $text =~ s/\s{2,}/ /g;
        $text =~ s/\s+$//;
        return $text;
    }#}}}
    sub get_docs {#{{{
        my $self    = shift;
        my $loofa   = HTML::Scrubber->new();
        my $docs    = {};
        my $dir     = wxTheApp->globals->dir_html;

        use HTML::TreeBuilder;
        foreach my $f(glob("\"$dir\"/*.html")) {
            my $html = read_file($f);

            my $content = $loofa->scrub( $html );

            my $x = HTML::TreeBuilder->new();
            $x->parse("<html><body>$html</body></html>");

            my $title_elem  = ($x->find_by_tag_name('h1'))[0];
            my $title_text  = (ref $title_elem eq 'HTML::Element') ? $title_elem->as_text : 'No Title';
            my $summary     = $self->get_doc_summary($x) || 'No Summary';

            $docs->{$f} = {
                content     => $content,
                summary     => $summary,
                title       => $title_text,
            }
        }
        return $docs;
    }#}}}
    sub get_doc_summary {#{{{
        my $self = shift;
        my $tree = shift;

        ### TBD
        ### This used to avoid the H1 tag contents before summarizing the body 
        ### tag contents.
        ###
        ### But HTML::TreeBuilder::XPath, which I was using before, does not 
        ### play well with being packaged by perlapp.
        ###
        ### I'm sure there's a way to remove the H1 tag contents using 
        ### TreeBuilder like I'm doing now, but having that H1 contents in the 
        ### summary is extremely minor and I doubt anybody but me will ever 
        ### even notice, and I want this thing out the door.
        ###
        ### So I'm gonna punt.

        my $body_elem = ($tree->find_by_tag_name('body'))[0];
        my $body_text = (ref $body_elem eq 'HTML::Element') ? $body_elem->as_text : 'No Body Text';
        $body_text = $self->clean_text( $body_text );
        $body_text = substr($body_text, 0, $self->summary_length);
        return $body_text;

    }#}}}
    sub get_html_width {#{{{
        my $self = shift;
        return ($self->GetClientSize->width - 10);
    }#}}}
    sub get_html_height {#{{{
        my $self = shift;
        return ($self->GetClientSize->height - 45);
    }#}}}
    sub load_html_file {#{{{
        my $self = shift;
        my $file = shift || return;

        my $fqfn = join q{/}, (wxTheApp->globals->dir_html, $file);
        unless(-e $fqfn) {
            wxTheApp->poperr("$fqfn: No such file or directory");
            return;
        }

        my $vars = {
            ### fix the .. in the paths, since it might confuse muggles.
            bin_dir     => wxTheApp->globals->dir_bin,
            dir_sep     => File::Util->SL,
            html_dir    => wxTheApp->globals->dir_html,
            user_dir    => wxTheApp->globals->dir_user,
            lucy_index  => wxTheApp->globals->dir_html_idx,
        };

        my $output  = q{};
        $self->tt->process($file, $vars, \$output);
        $self->htm_window->SetPage($output);
        return 1;
    }#}}}
    sub make_search_index {#{{{
        my $self = shift;

        return if -e wxTheApp->globals->dir_html_idx;
        my $docs = $self->get_docs;

        # Create a Schema which defines index fields.
        my $schema = Lucy::Plan::Schema->new;
        my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
            language => 'en',
        );
        my $type = Lucy::Plan::FullTextType->new(
            analyzer => $polyanalyzer,
        );
        $schema->spec_field( name => 'content',     type => $type );
        $schema->spec_field( name => 'filename',    type => $type );
        $schema->spec_field( name => 'summary',     type => $type );
        $schema->spec_field( name => 'title',       type => $type );
        
        # Create the index and add documents.
        my $indexer = Lucy::Index::Indexer->new(
            schema => $schema,  
            index  => wxTheApp->globals->dir_html_idx,
            create => 1,
            truncate => 1,  # if index already exists with content, trash them before adding more.
        );

        while ( my ( $filename, $hr ) = each %{$docs} ) {
            my $basename = basename($filename);
            $indexer->add_doc({
                filename    => $basename,
                content     => $hr->{'content'},
                summary     => $hr->{'summary'},
                title       => $hr->{'title'},
            });
        }
        $indexer->commit;
        return 1;
    }#}}}
    sub make_navbar {#{{{
        my $self = shift;

        my $spacer_width = $self->GetClientSize->width;
        $spacer_width -= $self->nav_img_w * 4;  # left, right, home, search buttons
        $spacer_width -= $self->home_spacer_w;
        $spacer_width -= $self->search_box_w;
        $spacer_width -= 10;                    # right margin

        $spacer_width < 10 and $spacer_width = 10;

        ### AddSpacer is adding unwanted vertical space when it adds the 
        ### wanted horizontal space.  So replace AddSpacer with manual Add 
        ### calls.

        $self->clear_szr_navbar;
        $self->szr_navbar->Add($self->bmp_left, 0, 0, 0);
        $self->szr_navbar->Add($self->bmp_right, 0, 0, 0);
        $self->szr_navbar->Add($self->home_spacer_w, 0, 0);
        $self->szr_navbar->Add($self->bmp_home, 0, 0, 0);
        $self->szr_navbar->Add($spacer_width, 0, 0);
        $self->szr_navbar->Add($self->txt_search, 0, 0, 0);
        $self->szr_navbar->Add($self->bmp_search, 0, 0, 0);

        $self->txt_search->SetFocus;
        return 1;
    }#}}}

    sub OnClose {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;
        $self->Destroy;
        $event->Skip();
        return 1;
    }#}}}
    sub OnHomeNav {#{{{
        my $self    = shift;    # LacunaWaX::Dialog::Help
        my $dialog  = shift;    # LacunaWaX::Dialog::Help
        my $event   = shift;    # Wx::CommandEvent

        $self->history_idx( $self->history_idx + 1 );
        $self->history->[ $self->history_idx ] = $self->index_file;
        $self->prev_click_href( $self->index_file );
        $self->load_html_file( $self->index_file );
        return 1;
    }#}}}
    sub OnLeftNav {#{{{
        my $self    = shift;    # LacunaWaX::Dialog::Help
        my $dialog  = shift;    # LacunaWaX::Dialog::Help
        my $event   = shift;    # Wx::CommandEvent

        return if $self->history_idx == 0;

        my $page = $self->history->[ $self->history_idx - 1 ];
        $self->history_idx( $self->history_idx - 1 );
        $self->prev_click_href( $page );
        $self->load_html_file( $page );
        return 1;
    }#}}}
    sub OnLinkClicked {#{{{
        my $self    = shift;    # LacunaWaX::Dialog::Help
        my $dialog  = shift;    # LacunaWaX::Dialog::Help
        my $event   = shift;    # Wx::HtmlLinkEvent

        my $info = $event->GetLinkInfo;
        if( $info->GetHref =~ /^http/ ) {# Deal with real URLs {{{
            ### retval of Browser::Open::open_browser
            ###     - retval == undef --> no open cmd found
            ###     - retval != 0     --> open cmd found but error encountered
            ### Browser::Open must be v0.04 to work on Windows.
            my $ok = Browser::Open::open_browser($info->GetHref);

            if( $ok ) {
                wxTheApp->poperr(
                    "LacunaWaX encountered an error while attempting to open the URL in your web browser.  The URL you were attempting to reach was '" . $info->GetHref . q{'.},
                    "Error opening web browser"
                );
            }
            elsif(not defined $ok) {
                wxTheApp->poperr(
                    "LacunaWaX was unable to open the URL in your web browser.  The URL you were attempting to reach was '" . $info->GetHref . q{'.},
                    "Unable to open web browser"
                );
            }

            return 1;
        }#}}}

        ### Each link click is triggering this event twice.
        if( $self->prev_click_href eq $info->GetHref ) {
            return 1;
        }
        $self->prev_click_href( $info->GetHref );

        ### If the user has backed up through their history and then clicked a 
        ### link, we need to diverge to an alternate timeline - truncate the 
        ### history so the current location is the furthest point.
        $#{$self->history} = $self->history_idx;

        push @{$self->history}, $info->GetHref;
        $self->history_idx( $self->history_idx + 1 );
        $self->load_html_file($info->GetHref);
        return 1;
    }#}}}
    sub OnResize {#{{{
        my $self = shift;

        my $old_szr_navbar = $self->szr_navbar;
        $self->make_navbar;
        $self->main_sizer->Replace($old_szr_navbar, $self->szr_navbar);

        ### Layout to force the navbar to update
        ### This must happen before the html window gets resized to avoid ugly 
        ### flashing.
        $self->Layout;

        $self->htm_window->SetSize( Wx::Size->new($self->get_html_width, $self->get_html_height) );
        return 1;
    }#}}}
    sub OnRightNav {#{{{
        my $self    = shift;    # LacunaWaX::Dialog::Help
        my $dialog  = shift;    # LacunaWaX::Dialog::Help
        my $event   = shift;    # Wx::CommandEvent

        return if $self->history_idx == $#{$self->history};

        my $page = $self->history->[ $self->history_idx + 1];
        $self->history_idx( $self->history_idx + 1 );
        $self->prev_click_href( $page );
        $self->load_html_file( $page );
        return 1;
    }#}}}
    sub OnSearchNav {#{{{
        my $self    = shift;    # LacunaWaX::Dialog::Help
        my $dialog  = shift;    # LacunaWaX::Dialog::Help
        my $event   = shift;    # Wx::CommandEvent

        my $term = $self->txt_search->GetValue;
        unless($term) {
            wxTheApp->popmsg("Searching for nothing isn't going to return many results.");
            return;
        }

        ### Search results do not get recorded in history.

        my $searcher = wxTheApp->globals->lucy_searcher;
        my $hits = $searcher->hits( query => $term );
        my $vars = {
            term => $term,
        };
        while ( my $hit = $hits->next ) {
            my $hr = {
                content     => $hit->{'content'},
                filename    => $hit->{'filename'},
                summary     => $hit->{'summary'},
                title       => $hit->{'title'},
            };
            push @{$vars->{'hits'}}, $hr;
        }

        my $output = q{};
        $self->tt->process('hitlist.tmpl', $vars, \$output);
        $self->htm_window->SetPage($output);
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
