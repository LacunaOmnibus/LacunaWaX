#!/home/jon/perl5/perlbrew/perls/perl-5.14.2/bin/perl

use v5.14;
use strict;

BEGIN {#{{{

    use FindBin;
    use lib "$FindBin::Bin/../lib";

    ### Step 2
    use Class::Load::XS;

    ### Step 3
    use Package::Stash::XS;

    ### Step 5
    use Variable::Magic;

    ### Step 4
    use B::Hooks::EndOfScope::XS;

    ### Step 1
    use Moose;

    ### Step 6
    use JSON::RPC::Common::Marshal::Text;

### I stopped here and went to play with WaxWorks' test.pl.

    ### Step 3
#    use Class::MOP::Mixin;

    ### Step 4
#    use Class::MOP::Method::Generated;

    ### Step 5
#    use Class::MOP::Method::Inlined;

    ### Step 6
#    use Class::MOP::Module;

    ### Step 7
#    use Class::MOP::Package;

    ### Step 9
#    use Moose::Meta::Method;

    ### Step 10
#    use Class::MOP::Class::Immutable::Trait;

    ### Step 11
#    use Moose::Meta::Mixin::AttributeCore;

    ### Step 15
#    use Params::Validate::XS;

    ### Step 18
#    use MooseX::Clone::Meta::Attribute::Trait::Clone::Base;

    ### Step 19
#    use MooseX::Clone::Meta::Attribute::Trait::Clone::Std;

    ### Step 17
#    use MooseX::Clone;

    ### Step 19
#    use SQL::Translator::Role::Error;

    ### Step 20
#    use SQL::Translator::Role::BuildArgs;

    ### Step 21
#    use SQL::Translator::Schema::Role::Extra;

    ### Step 22
#    use SQL::Translator::Schema::Role::Compare;

    ### Step 23
#    use SQL::Translator::Role::Debug;

    ### Step 18
#    use SQL::Translator::Schema::Object;

#use Moose::Exception::Role::Class;
#use Moose::Exception::MethodNameNotFoundInInheritanceHierarchy;
#use Moose::Exception::IncompatibleMetaclassOfSuperclass;

}#}}}

use File::Copy;
use IO::All;
use Wx qw(:allclasses);

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

