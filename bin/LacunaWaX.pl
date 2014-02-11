#!/home/jon/perl5/perlbrew/perls/perl-5.14.2/bin/perl

use v5.14;
use strict;
use File::Copy;
use FindBin;
use IO::All;
use Wx qw(:allclasses);
use lib $FindBin::Bin . '/../lib';
use LacunaWaX;
use LacunaWaX::Model::DefaultData;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

my $root_dir = "$FindBin::Bin/..";
{
    ### $env is going to get modified by the build process to "msi", so the 
    ### installed version can know it is the installed version, not the source 
    ### version.
    ###
    ### That modification is a simple regex in the build script - do not mess 
    ### with the $env assignment line below, or you're likely to break that 
    ### part of the build script.
    my $env = 'source';    
    if( $^O eq 'MSWin32' ) {
        $root_dir = $ENV{'APPDATA'} . '/LacunaWaX' if $env eq 'msi';
    }
}
my $app_db   = "$root_dir/user/lacuna_app.sqlite";
my $log_db   = "$root_dir/user/lacuna_log.sqlite";

unless(-e $app_db and -e $log_db ) {#{{{
    autoflush STDOUT 1;
    say "
Running for the first time, so databases must be deployed first.

This takes a few seconds; please be patient...  ";

    my $c = LacunaWaX::Model::Container->new(
        name        => 'my container',
        root_dir    => $FindBin::Bin . "/..",
        db_file     => $app_db,
        db_log_file => $log_db,
    );

    unless(-e $app_db ) {
        my $app_schema = $c->resolve( service => '/Database/schema' );
        $app_schema->deploy;
        my $d = LacunaWaX::Model::DefaultData->new();
        $d->add_servers($app_schema);
        $d->add_stations($app_schema);
    }
    unless(-e $log_db ) {
        my $log_schema = $c->resolve( service => '/DatabaseLog/schema' );
        $log_schema->deploy;
    }

    say "...Database deployment complete.";
}#}}}

my $app = LacunaWaX->new( root_dir => $root_dir );
$app->MainLoop();

