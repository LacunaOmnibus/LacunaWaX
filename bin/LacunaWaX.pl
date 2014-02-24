#!/home/jon/perl5/perlbrew/perls/perl-5.14.2/bin/perl

use v5.14;
use strict;


### Regular BreadBoard container has been excised.
###
### Next step is to remove the wxbb (I'll need an additional Globals module, 
### WxGlobals maybe, to replace it.) 



BEGIN {#{{{

    ### Step 2
    use Class::Load::XS;

    ### Step 8
    use Package::Stash::XS;

    ### Step 1
    use Moose;

    ### Step 3
    use Class::MOP::Mixin;

    ### Step 4
    use Class::MOP::Method::Generated;

    ### Step 5
    use Class::MOP::Method::Inlined;

    ### Step 6
    use Class::MOP::Module;

    ### Step 7
    use Class::MOP::Package;

    ### Step 9
    use Moose::Meta::Method;

    ### Step 10
    use Class::MOP::Class::Immutable::Trait;

    ### Step 11
    use Moose::Meta::Mixin::AttributeCore;

    ### Step 13
    use Variable::Magic;

    ### Step 12
    use B::Hooks::EndOfScope::XS;

    ### Step 14
    use JSON::RPC::Common::Marshal::Text;

    ### Step 15
    use Params::Validate::XS;

    ### Step 18
    use MooseX::Clone::Meta::Attribute::Trait::Clone::Base;

    ### Step 19
    use MooseX::Clone::Meta::Attribute::Trait::Clone::Std;

    ### Step 17
    use MooseX::Clone;

    ### Step 16
    use Bread::Board::Traversable;

    ### Step 20
    use Bread::Board::Service::WithClass;

    ### Step 21
    use Bread::Board::Service::WithParameters;

    ### Step 24
    use Moose::Meta::Attribute::Native::Trait;

    ### Step 23
    use Moose::Meta::Attribute::Native::Trait::Code;

    ##########################################################################
    ###
    ### This is where I get irretrievably stuck.  Step 26 requires step 27 
    ### comes first, but step 27 requires step 26 come first.
    ###
    ### Step 26
    use Moose::Exception::Role::Class;

    ### Step 27
    use Moose::Exception::MethodNameNotFoundInInheritanceHierarchy;
    ##########################################################################

    ### Step 25
    use Moose::Exception::IncompatibleMetaclassOfSuperclass;

    ### Step 22
    use Bread::Board::Service::WithDependencies;



}#}}}

use File::Copy;
use FindBin;
use IO::All;
use Wx qw(:allclasses);

use lib "$FindBin::Bin/../lib";
use LacunaWaX;
use LacunaWaX::Util;
use LacunaWaX::Model::DefaultData;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

my $root_dir = LacunaWaX::Util::find_root();
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

