
### CHECK
### Needs to keep track of the size of its own sizers, so using its own 
### version of build_sizer().
###
### Works, but hacky.

package LacunaWaX::Dialog::Status {
    use v5.14;
    use Data::Dumper;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_CLOSE EVT_SIZE);

    has 'parent' => (
        is          => 'rw',
        isa         => 'Object',
        weak_ref    => 1,
        ### not required.
    );

    has 'dialog'    => (is => 'rw', isa => 'Wx::Dialog', lazy_build => 1 );

    has 'title'             => (is => 'rw', isa => 'Str', lazy_build => 1, documentation => "goes on the dialog, not the sizer" );
    has 'recsep'            => (is => 'rw', isa => 'Str', lazy_build => 1 );
    has 'user_closeable'    => (is => 'rw', isa => 'Int', default    => 1 );

    has 'position'  => (is => 'rw', isa => 'Wx::Point', lazy_build => 1);
    has 'size'      => (is => 'rw', isa => 'Wx::Size',  lazy_build => 1);
    has 'sizers'    => (is => 'rw', isa => 'HashRef', lazy => 1, default => sub{ {} });

    has 'margin_top'    => (is => 'rw', isa => 'Int', lazy => 1, default => 10, documentation => 'in pixels');
    has 'margin_right'  => (is => 'rw', isa => 'Int', lazy => 1, default => 10, documentation => 'in pixels');
    has 'margin_bottom' => (is => 'rw', isa => 'Int', lazy => 1, default => 10, documentation => 'in pixels');
    has 'margin_left'   => (is => 'rw', isa => 'Int', lazy => 1, default => 10, documentation => 'in pixels');

    has 'page_sizer' => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1,
        documentation => q{
            Horizontal
            Controls left and right margins.
        }
    );
    has 'content_sizer' => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1,
        documentation => q{
            Vertical
            Controls top and bottom margins.
        }
    );
    has 'header_sizer' => (is => 'rw', isa => 'Wx::Sizer', lazy_build => 1, documentation => q{vertical});

    has 'lbl_header'    => (is => 'rw', isa => 'Wx::StaticText',    lazy_build => 1     );
    has 'txt_status'    => (is => 'rw', isa => 'Wx::TextCtrl',      lazy_build => 1     );

    sub BUILD {
        my $self = shift;

        wxTheApp->borders_off();    # Change to borders_on to see borders around sizers

        $self->header_sizer->Add($self->lbl_header, 0, 0, 0);

        $self->content_sizer->AddSpacer( $self->margin_top );
        $self->content_sizer->Add($self->header_sizer, 0, 0, 0);
        $self->content_sizer->AddSpacer(5); # fix get_text_size if you change this.
        $self->content_sizer->Add($self->txt_status, 0, 0, 0);

        $self->txt_status->SetFocus;

        $self->page_sizer->AddSpacer( $self->margin_left );
        $self->page_sizer->Add($self->content_sizer, 0, 0, 0);
        $self->page_sizer->AddSpacer( $self->margin_right );

        $self->dialog->SetSizer($self->page_sizer);
        $self->_set_events();
        return $self;
    }

    sub _build_content_sizer {#{{{
        my $self = shift;
        my $name = 'Content';
        my $v = $self->build_sizer($self->dialog, wxVERTICAL, $name, undef, undef, $self->get_content_size);
        $self->sizers->{$name}->{'sizer'}->SetMinSize( $self->get_content_size );
        $self->sizers->{$name}->{'box'}->SetSize( $self->get_content_size ) if defined $self->sizers->{$name}->{'box'};
        return $v;
    }#}}}
    sub _build_dialog {#{{{
        my $self = shift;

        my $style = wxRESIZE_BORDER|wxCAPTION;
        $style |= wxDEFAULT_DIALOG_STYLE if $self->user_closeable;
        return Wx::Dialog->new(
            undef, -1, 
            $self->title, 
            $self->position, 
            $self->size,
            $style,
            "LacunaWaX Status"
        );
    }#}}}
    sub _build_header_sizer {#{{{
        my $self = shift;
        my $v = $self->build_sizer($self->dialog, wxVERTICAL, 'Header');
        return $v;
    }#}}}
    sub _build_lbl_header {#{{{
        my $self = shift;
        my $s = Wx::Size->new(-1, 35);
        my $v = Wx::StaticText->new(
            $self->dialog, -1, 
            $self->title,
            wxDefaultPosition, 
            $s,
        );
        $v->SetFont( wxTheApp->get_font('header_1') );

        ### This needs to be here, or the header will report itself as being 
        ### 34 pixels high immediately after creation, regardless of what we 
        ### set $s to (even though we are using $s as the size parameter).
        $v->SetSize($s);

        return $v;
    }#}}}
    sub _build_page_sizer {#{{{
        my $self = shift;
        my $name = 'Page';
        my $v = $self->build_sizer($self->dialog, wxHORIZONTAL, $name, undef, undef, $self->get_page_size);
        $self->sizers->{$name}->{'sizer'}->SetMinSize( $self->get_page_size );
        if( defined $self->sizers->{$name}->{'box'} ) {
            $self->sizers->{$name}->{'box'}->SetSize( $self->get_page_size );
        }
        return $v;
    }#}}}
    sub _build_position {#{{{
        my $self = shift;
        return wxDefaultPosition;
    }#}}}
    sub _build_recsep {#{{{
        my $self = shift;
        return '----------';
    }#}}}
    sub _build_size {#{{{
        my $self = shift;

        ### See comments in LacunaWaX::MainFrame's _build_size.
        my $s = wxDefaultSize;
        $s->SetWidth(400);
        $s->SetHeight(300);

        return $s;
    }#}}}
    sub _build_title {#{{{
        my $self = shift;
        return 'Status';
    }#}}}
    sub _build_txt_status {#{{{
        my $self = shift;

        my $size = $self->get_txt_size;

        ### wxTE_PROCESS_ENTER gives the control the ability to respond to an 
        ### EVT_TEXT_ENTER (the user clicking their 'enter' key).  
        my $v = Wx::TextCtrl->new(
            $self->dialog, -1, 
            qq{},
            wxDefaultPosition, 
            $size,
            wxTE_MULTILINE
            | wxTE_READONLY
            | wxTE_PROCESS_ENTER
        );
        return $v;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE(  $self->dialog, sub{$self->OnClose(@_)}  );
        EVT_SIZE(   $self->dialog, sub{$self->OnResize(@_)} );
        return 1;
    }#}}}

    sub build_sizer {#{{{
        my $self        = shift;
        my $parent      = shift;
        my $direction   = shift;
        my $name        = shift or die "iSizer name is required.";
        my $force_box   = shift || 0;
        my $pos         = shift || wxDefaultPosition;
        my $size        = shift || wxDefaultSize;

        my $hr = { };
        if( not wxTheApp->borders_are_off or $force_box ) {
            $hr->{'box'} = Wx::StaticBox->new($parent, -1, $name, $pos, $size),
            $hr->{'box'}->SetFont( wxTheApp->get_font('para_text_1') );
            $hr->{'sizer'} = Wx::StaticBoxSizer->new($hr->{'box'}, $direction);
        }
        else {
            $hr->{'sizer'} = Wx::BoxSizer->new($direction);
        }
        $self->sizers->{$name} = $hr;

        return $hr->{'sizer'};
    }#}}}
    sub close {## no critic qw(ProhibitBuiltinHomonyms NamingConventions) {{{
        my $self = shift;
        if($self->has_dialog) { 
            my $crv = $self->dialog->DestroyChildren;
            my $rv = $self->dialog->Destroy;
        }
        return 1;
    }#}}}
    sub erase {#{{{
        my $self = shift;
        $self->txt_status->SetValue(q{}) if $self->has_txt_status;
        return 1;
    }#}}}
    sub hide {#{{{
        my $self = shift;
        $self->dialog->Show(0);
        return 1;
    }#}}}
    sub get_content_size {#{{{
        my $self = shift;

        ### Returns the size used by the content sizer, which sits inside the 
        ### page_sizer.  
        my $size = $self->get_page_size;

        my $width  = $size->GetWidth  - $self->margin_left - $self->margin_right;
        my $height = $size->GetHeight - $self->margin_top  - $self->margin_bottom;

        unless( wxTheApp->borders_are_off ) {
            ### The debug boxes themselves generate a good bit of extra vertical 
            ### requirement.
            $size->SetWidth( $width - 10 );
            $size->SetHeight( $height - 10 );
        }
        else {
            $size->SetWidth( $width );
            $size->SetHeight( $height );
        }
        return $size;
    }#}}}
    sub get_dialog_size{#{{{
        my $self = shift;

        ### Returns the size of the dialog
        my $dialog_size = $self->dialog->GetClientSize;
        return $dialog_size;
    }#}}}
    sub get_page_size {#{{{
        my $self = shift;

        ### Same as get_dialog_size; any margins need to be inside this sizer 
        ### (that's why it's here).
        my $dialog_size = $self->get_dialog_size;
        return $dialog_size;
    }#}}}
    sub get_txt_size {#{{{
        my $self = shift;

        my $content_size = $self->get_content_size;
        my $header_size  = $self->lbl_header->GetSize;

        ### Shave off a little to deal with the scrollbar
        my $width = $content_size->GetWidth;

        ### We're under the header sizer and a 5-pixel spacer.
        my $header_height = $header_size->GetHeight;
        my $height = $content_size->GetHeight - $header_height - 5;

        unless( wxTheApp->borders_are_off ) {
            $width  -= 10;
            $height -= 30;
        }
        my $size = Wx::Size->new($width, $height);
        return $size;
    }#}}}
    sub print {## no critic qw(ProhibitBuiltinHomonyms) {{{
        my $self = shift;
        my $text = shift // q{};
        $self->txt_status->AppendText("$text");
        $self->txt_status->Layout();
        ### The short MilliSleep following the Yield gives the main thread 
        ### enough time to actually respond to the Yield and flush the output 
        ### buffer, which is the point.
        wxTheApp->Yield(1);
        Wx::MilliSleep(100);
        return 1;
    }#}}}
    sub say {## no critic qw(ProhibitBuiltinHomonyms) {{{
        my $self = shift;
        my $text = shift // q{};
        $self->txt_status->AppendText("$text\n");
        $self->txt_status->Layout();
        ### The short MilliSleep following the Yield gives the main thread 
        ### enough time to actually respond to the Yield and flush the output 
        ### buffer, which is the point.
        wxTheApp->Yield(1);
        Wx::MilliSleep(100);
        return 1;
    }#}}}
    sub say_recsep {#{{{
        my $self = shift;
        $self->say( $self->recsep );
        return 1;
    }#}}}
    sub show {#{{{
        my $self = shift;
        $self->dialog->Show(1);
        $self->dialog->Layout();
        return 1;
    }#}}}
    sub show_modal {#{{{
        my $self = shift;
        $self->dialog->ShowModal();
        $self->dialog->Layout();
        return 1;
    }#}}}

    sub OnClose {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;
        if( $self->parent and $self->parent->can('OnDialogStatusClose') ) {
            ### The window that opened this status dialog might want to do 
            ### something when we close.  If so, call its pseudo-event method.
            $self->parent->OnDialogStatusClose;
        }
        $self->close;
        $event->Skip();
        return 1;
    }#}}}
    sub OnResize {#{{{
        my $self    = shift;
        my $dialog  = shift;    # Wx::Dialog
        my $event   = shift;    # Wx::SizeEvent

        $self->sizers->{'Page'}->{'sizer'}->SetMinSize( $self->get_page_size );
        $self->sizers->{'Page'}->{'box'}->SetSize( $self->get_page_size ) if defined $self->sizers->{'Page'}->{'box'};

        $self->sizers->{'Content'}->{'sizer'}->SetMinSize( $self->get_content_size );
        $self->sizers->{'Content'}->{'box'}->SetSize( $self->get_content_size ) if defined $self->sizers->{'Content'}->{'box'};

        $self->txt_status->SetSize( $self->get_txt_size );
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 TBD

The other modules in ./ are standalone tools using WxDialog windows, 
accessible via the app's MenuBar.  But this module is essentially a scrolled 
STDOUT tool meant to be used in multiple places, and is not accessible on its 
own via the MenuBar.

Since this class has a different purpose from the others in ./, I'm beginning 
to think that this is the wrong location for it.

=head1 SYNOPSIS

Provides an output dialog window, meant to be used to display messages for 
debugging (the way I often use the terminal window with Perl's "say") or a 
running commentary for the user during longer-running processes (as during 
sitter voting).

 my $status = LacunaWaX::Dialog::Status->new(
  parent => $self,
  title  => 'My Output Window',
 );
 
 $status->show; # Don't forget this!

 use Data::Dumper;
 $status->say( Dumper $myvar );

 for(1..5) {
  $status->say("We are on number $_");
  $status->say_recsep;
 }

The dialog begins its life hidden, so be sure to call show() if you expect to be 
able to see it.

=head2 The title attribute

This is optional to the constructor, and defaults to "Status".  Whatever string 
is in this attribute will be both the title and the header of the produced 
status window.

'header' should probably be a different attribute, defaulting to the same 
value that's in 'title'.  Right now, they will both always display the same 
string.

=head2 The recsep attribute and say_recsep() methods

The recsep attribute is optional to the constructor, and will default to simply 
ten hyphens ('----------').  This gets sent to output by say_recsep().  It's 
just meant as an attempt to keep output looking uniform.

=head2 Dialog Size

By default, the status dialog will be created at 400x300 pixels, but you can 
adjust this as needed:

 my $status = LacunaWaX::Dialog::Status->new(
  app   => $self->app,
  title => 'My Output Window',
  size  => Wx::Size->new(500, 600),
 );

=head2 Closing the dialog

Don't forget this in your calling window's OnClose event.  If that calling 
window creates a Dialog::Status, but is itself closed before the Dialog::Status is 
shown, the Dialog::Status will remain in existence, but invisible, leading to a 
frustrating program hang that you'll need to track down.

 $status->close;

=head2 Erasing the dialog's text box

Any status messages currently being displayed can be removed with;

 $status->erase;

=head2 Hiding and showing the dialog

If you need to construct a Dialog::Status before you want to actually display it, 
you can hide it upon construction, then just show it when you're ready to use 
it:

 my $status = LacunaWaX::Dialog::Status->new( ... );
 $status->hide();

 ...time passes...

 $status->show();
 $status->say("You can see this now").

=head2 Responding to user input

The TextCtrl containing the output is able to respond to the user clicking their 
Enter button.  This will produce an EVT_TEXT_ENTER event.

You can safely ignore this if you don't need it, but if you want to, eg, produce 
a message, then block until the user hits Enter to acknowledge they've read the 
message, this event is necessary.

For an example of this, see '->waiting_for_enter' and OnDialogEnter() in 
./TestBlockingStatus.pm.  Note carefully how the _set_dialog_events() method is 
setting up that enter event every time a new Dialog::Status window is opened.

=head2 Responding to the Status Dialog being closed

If you need to do something in response to the user closing the status window, 
implement a pseudo-event handler called OnDialogStatusClose().  If it exists, it 
will be called by the Dialog::Status's OnClose event.

 sub OnDialogStatusClose {
  my $self    = shift;
  my $status  = shift;    # LacunaWaX::Dialog::Status
  say "You just closed the status dialog.";
 }

=head2 Dealing with premature status window closure

By default, a Status window will have regular window controls on it, including 
the red X.  If your program attempts to write to the status window after the 
user has closed it that way, LacunaWaX will produce a crash upon app close 
(this crash is a little tricksy because it does not occur immediately upon the 
attempt to write to the closed status window; ONLY upon app close).

There are two ways of dealing with this.

The easiest way is simply to pass the user_closeable option with a false value 
upon construction of your status window:

 my $status = LacunaWaX::Dialog::Status->new(
  app               => $self->app,
  title             => 'My Output Window',
  user_closeable    => 0,
 );

The default for that option is true (meaning that the status window will 
include the red X).  By turning it off, you're making it impossible for the 
user to close the status window.

The caveats here are that you must close the status window once you're 
finished with it by calling $status->close, and any output that the user might 
have wanted to look at will disappear as soon as you do that.  FWIW - it would 
be reasonable to include a possibly-optional "close this status window" button 
that only becomes enabled after you're finished writing output to that window.  
That button would need to be added to this module, and does not exist yet.

The second option is to include some extra methods in the class that wants to 
write to that status window.  These methods need to check if the status window 
still exists, and respond to its close event when the user does close it.

 sub status_say {
  my $self = shift;
  my $msg  = shift;
  if( $self->has_status ) {
   try{ $self->status->say($msg) };
  }
  return 1;
 }
 sub status_say_recsep {
  my $self = shift;
  if( $self->has_status ) {
   try{ $self->status->say_recsep };
  }
  return 1;
 }
 sub OnDialogStatusClose {
  my $self    = shift;
  my $status  = shift;    # LacunaWaX::Dialog::Status
  if( $self->has_status ) {
   $self->clear_status;
  }
  return 1;
 }

At the top of the event that triggers writing to the status window, be sure to 
include $self->status->show.  That call will have no effect if the status 
window is already shown, but will call the lazy_builder for the status window 
if it doesn't already exist (including if the user closed it).

 sub SomeEvent {
  my $self = shift;
  $self->status->show;
  $self->status_say("This is safe.");
 }

=cut
