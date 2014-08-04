#!/home/jon/perl5/perlbrew/perls/perl-5.14.2/bin/perl

use v5.14;
use strict;

use File::Copy;
use IO::All;
use Wx qw(:allclasses);

my $i;
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    opendir my $splash_dir, "$FindBin::Bin/../splash";
    my @imgs = grep{ $_ =~ /\.(png|jpe?g)$/; }readdir $splash_dir;
    $i = "$FindBin::Bin/../splash/" . $imgs[int rand @imgs];
}
BEGIN {
    use LacunaWaX::Preload::Perlapp;
    use Wx::Perl::SplashFast( $i, 2000 );
}
use LacunaWaX;
use LacunaWaX::Util;

my $root_dir = LacunaWaX::Util::find_root();
my $app_db   = "$root_dir/user/lacuna_app.sqlite";
my $log_db   = "$root_dir/user/lacuna_log.sqlite";
my $globals  = LacunaWaX::Model::Globals->new( root_dir => $root_dir );

unless(-e $app_db and -e $log_db ) {#{{{
    autoflush STDOUT 1;
    say "
Running for the first time, so databases must be deployed first.

This takes a few seconds; please be patient...  ";

    ### ->deploy does not function properly for the installed version, and it 
    ### would take too long anyway.  So the installer needs to include empty 
    ### versions of both databases.
    ###
    ### This deploy bit is here for the benefit of people running from source.
    unless(-e $app_db ) {
        my $app_schema = $globals->main_schema;
        say "deploying app";
        $app_schema->deploy;
        my $d = LacunaWaX::Model::DefaultData->new();
        $d->add_servers($app_schema);
    }
    unless(-e $log_db ) {
        my $log_schema = $globals->logs_schema;
        say "deploying log";
        $log_schema->deploy;
    }

    say "...Database deployment complete.";
}#}}}

my $app = LacunaWaX->new( root_dir => $root_dir );
$app->MainLoop();

