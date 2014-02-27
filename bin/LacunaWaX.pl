#!/home/jon/perl5/perlbrew/perls/perl-5.14.2/bin/perl

use v5.14;
use strict;

use File::Copy;
use IO::All;
use Wx qw(:allclasses);

use FindBin;
use lib "$FindBin::Bin/../lib";
use LacunaWaX;
use LacunaWaX::Util;
use LacunaWaX::Model::DefaultData;

my $root_dir = LacunaWaX::Util::find_root();
my $app_db   = "$root_dir/user/lacuna_app.sqlite";
my $log_db   = "$root_dir/user/lacuna_log.sqlite";

unless(-e $app_db and -e $log_db ) {#{{{
    autoflush STDOUT 1;
    say "
Running for the first time, so databases must be deployed first.

This takes a few seconds; please be patient...  ";

    my $g = LacunaWaX::Model::Globals->new( root_dir => "$FindBin::Bin/.." );

    unless(-e $app_db ) {
        my $app_schema = $g->main_schema;
        $app_schema->deploy;
        my $d = LacunaWaX::Model::DefaultData->new();
        $d->add_servers($app_schema);
        $d->add_stations($app_schema);
    }
    unless(-e $log_db ) {
        my $log_schema = $g->logs_schema;
        $log_schema->deploy;
    }

    say "...Database deployment complete.";
}#}}}

my $app = LacunaWaX->new( root_dir => $root_dir );
$app->MainLoop();

