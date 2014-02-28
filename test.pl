
use v5.14;
use lib 'lib';

use LacunaWaX::Preload::Perlapp;
use LacunaWaX::Dialog::About;
use LacunaWaX::Dialog::Calculator;
use LacunaWaX::Dialog::Captcha;
use LacunaWaX::Dialog::Help;
use LacunaWaX::Dialog::LogViewer;
use LacunaWaX::Dialog::Mail;
use LacunaWaX::Dialog::Prefs;
use LacunaWaX::Dialog::SitterManager;
use LacunaWaX::MainSplitterWindow::RightPane::GlyphsPane;
use LacunaWaX::MainSplitterWindow::RightPane::RepairPane;
use LacunaWaX::MainSplitterWindow::RightPane::SSIncoming;
use LacunaWaX::Model::Globals::Wx;
use LacunaWaX::Model::SStation;
use LacunaWaX::Model::SStation::Police;
use LacunaWaX::Schedule::Spies;
use LacunaWaX::Schedule::SS_Health;
use LacunaWaX::Servers;

### Need to get to here.
use LacunaWaX;

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




