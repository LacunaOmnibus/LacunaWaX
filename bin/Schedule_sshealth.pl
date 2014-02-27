use v5.14;
use warnings;
use DateTime::TimeZone;
use FindBin;
use Try::Tiny;

use lib $FindBin::Bin . '/../lib';

### This must exist here for perlApp to understand it needs Moose in time.
use Moose;

use LacunaWaX::Model::Globals;
use LacunaWaX::Schedule;
use LacunaWaX::Util;

my $root_dir    = LacunaWaX::Util::find_root();
my $db_file     = join '/', ($root_dir, 'user', 'lacuna_app.sqlite');
my $db_log_file = join '/', ($root_dir, 'user', 'lacuna_log.sqlite');

my $dt = try {
    DateTime::TimeZone->new( name => 'local' )->name();
};
$dt ||= 'UTC';

my $globals = LacunaWaX::Model::Globals->new( root_dir => $root_dir );

my $scheduler = LacunaWaX::Schedule->new( 
    globals     => $globals,
    schedule => 'ss_health',
);

$scheduler->ss_health();

exit 0;

