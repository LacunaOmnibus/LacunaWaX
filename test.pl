
use v5.14;
use lib 'lib';
use LacunaWaX::Preload::Perlapp;
use LacunaWaX::Dialog::About;
#use LacunaWaX::Dialog::LogViewer;   # still producing incompatible metaclass problems, because of NonScrolled.  Come back to this.
use LacunaWaX::MainSplitterWindow::RightPane::GlyphsPane;
use LacunaWaX::MainSplitterWindow::RightPane::RepairPane;
use LacunaWaX::MainSplitterWindow::RightPane::SSIncoming;

say "blarg";


__END__

package TestClass {#{{{
    use Moose;

    has 'num' => (
        is          => 'rw',
        isa         => 'Int',
        default     => 1,
    );

}#}}}

my $tc = TestClass->new();
say $tc->num;
$tc->num( $tc->num + 1 );
say $tc->num;




