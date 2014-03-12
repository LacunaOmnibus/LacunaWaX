#!/usr/bin/env perl

use v5.16;
use Archive::Zip qw(:ERROR_CODES);
use Capture::Tiny qw(:all);
use File::Mirror;
use IO::All;
use Path::Tiny;
use Term::Prompt;

use FindBin;
use lib $FindBin::Bin . '/../../lib';
use LacunaWaX::Model::DefaultData;
use LacunaWaX::Model::Globals;
use LacunaWaX::Model::LogsSchema;
use LacunaWaX::Model::Schema;

BEGIN {#{{{
    sub filter_source {#{{{
        my $file    = shift;
        my $str     = shift;

        my @lines = io->file($file)->slurp;
        for my $l(@lines) {
            if( $l =~ s/^(\s+my\s+\$env\s*=\s*['"])(\w+)(["'].*)/$1${str}$3/ ) {
                #say "old was $2.  Current is $str;"
            }
        }
        io->file($file)->binmode("raw")->print(@lines);
    }#}}}

    ### Change the $env variable from 'source' to 'msi' so the executables 
    ### know they're the installed version.
    filter_source("../../lib/LacunaWaX/Util.pm", "msi");
}#}}}
END {#{{{
    ### Change the $env setting back to 'source'.  In END block in case some 
    ### part of the build process dies after changing $env.
    filter_source("../../lib/LacunaWaX/Util.pm", "source");
}#}}}

STDOUT->autoflush(1);

my $binary_type = q{};  # 'deb'ug or 'pro'duction
### Interactively gather data from user {#{{{
    system('cls');
    say "";

    while( my $r !~ /^(p|d)$/ ) {
        $r = prompt(
            'a', 
            'Should I produce Production or Debug binaries?', 
            'Production hides the console, Debug shows it', 
            'Production'
        );
        if( $r =~ /^p/i ) {
            $binary_type = 'pro';
            last;
        }
        elsif( $r =~ /^d/i ) {
            $binary_type = 'deb';
            last;
        }
        say '';
        say "Respond with 'production' or 'debug', please.";
        say '';
    }
    say "Producing " . ( ($binary_type eq 'deb') ? 'Debug' : 'Production' ) . " binaries.";
    say '';

### }#}}}

my $ARCHIVE_FILENAME_BASE   = path("LacunaWaX_win32");
my $ARCHIVE_FILENAME_FULL   = path("${ARCHIVE_FILENAME_BASE}.zip");
my $build_dir               = path('build');

if( $build_dir->exists ) {
    say "Removing existing build directory";
    $build_dir->remove_tree;
} 
if( $ARCHIVE_FILENAME_FULL->exists ) {
    say "Removing existing $ARCHIVE_FILENAME_FULL archive";
    $ARCHIVE_FILENAME_FULL->remove_tree;
    
} 
say "";

$build_dir->mkpath;
$build_dir->child('bin')->mkpath;
$build_dir->child('user')->mkpath;

path("../../user/assets.zip")->copy("./build/user/");
mirror "../../user/doc", "./build/user/doc/";
mirror "../../user/ico", "./build/user/ico/";

### Used by multiple Capture::Tiny::capture() calls below
my($out,$err,$exit);

### Deploy empty datbases {#{{{
say "Deploying default (empty) databases...";
($out,$err,$exit) = capture {
    my $g           = LacunaWaX::Model::Globals->new( root_dir => "$FindBin::Bin/build/" );
    my $app_schema  = $g->main_schema;
    my $log_schema  = $g->logs_schema;

    $log_schema->deploy;
    $app_schema->deploy;

    my $d = LacunaWaX::Model::DefaultData->new();
    $d->add_servers($app_schema) or return 3;   # 3 just so our error message will point us here.

    ### add_servers returns a true value on success, but we're expecting $exit 
    ### to be false on success.  So if we're here, everything's good - return 
    ### false.
    0;
};
die "Database deploy failed! ($exit)" if $exit;
### }#}}}
### LacunaWaX (main GUI) {#{{{
say "Building LacunaWaX executable...";
($out,$err,$exit) = capture {

    if( $binary_type eq 'deb' ) {
        system('perlapp --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;LacunaWaX::;Games::Lacuna::Client::;Games::Lacuna::Cache;Games::Lacuna::Client::;Games::Lacuna::Client::;Games::Lacuna::Client;Games::Lacuna::Client::Buildings::**;Class::MOP::;HTML::TreeBuilder::XPath;Variable::Magic --icon "..\..\unpackaged assets\frai.ico" --scan ..\extra_scan.pl --lib ..\..\lib --shared private --norunlib --force --exe build\bin\LacunaWaX.exe --perl C:\Perl\bin\perl.exe ..\..\bin\LacunaWaX.pl') and return 1;
    }
    else {
        system('perlapp --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;LacunaWaX::;Games::Lacuna::Client::;Games::Lacuna::Cache;Games::Lacuna::Client::;Games::Lacuna::Client::;Games::Lacuna::Client;Games::Lacuna::Client::Buildings::**;Class::MOP::;HTML::TreeBuilder::XPath;Variable::Magic --icon "..\..\unpackaged assets\frai.ico" --scan ..\extra_scan.pl --lib ..\..\lib --shared private --norunlib --gui --force --exe build\bin\LacunaWaX.exe --perl C:\Perl\bin\perl.exe ..\..\bin\LacunaWaX.pl') and return 1;
    }

};
die "Building LacunaWaX.exe failed!" if $exit;
=pod
=cut
### }#}}}
### Archmin {#{{{
say "Building Archmin executable...";
($out,$err,$exit) = capture {

    if( $binary_type eq 'deb' ) {
        system('perlapp --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;Moose;Class::MOP:: --icon "../../unpackaged assets/leela.ico" --scan ../extra_scan.pl --lib ..\..\lib --shared private --norunlib --force --exe build\bin\Schedule_archmin.exe --perl C:\Perl\bin\perl.exe ..\..\bin\Schedule_archmin.pl');
    }
    else {
        system('perlapp --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;Moose;Class::MOP:: --icon "../../unpackaged assets/leela.ico" --scan ../extra_scan.pl --lib ..\..\lib --shared private --norunlib --gui --force --exe build\bin\Schedule_archmin.exe --perl C:\Perl\bin\perl.exe ..\..\bin\Schedule_archmin.pl');
    }

};
die "Building Schedule_archmin.exe failed!" if $exit;
=pod
=cut
### }#}}}
### Autovote {#{{{
say "Building Autovote executable...";
($out,$err,$exit) = capture {

    if( $binary_type eq 'deb' ) {
        system('perlapp --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;Moose;Class::MOP:: --icon "../../unpackaged assets/leela.ico" --scan ../extra_scan.pl --lib ../../lib --shared private --norunlib --force --exe build\bin\Schedule_autovote.exe --perl C:\Perl\bin\perl.exe ..\..\bin\Schedule_autovote.pl');
    }
    else {
        system('perlapp --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;Moose;Class::MOP:: --icon "../../unpackaged assets/leela.ico" --scan ../extra_scan.pl --lib ../../lib --shared private --norunlib --gui --force --exe build\bin\Schedule_autovote.exe --perl C:\Perl\bin\perl.exe ..\..\bin\Schedule_autovote.pl');
    }

};
die "Building Schedule_autovote failed!" if $exit;
=pod
=cut
### }#}}}
### SS Health {#{{{
say "Building SS Health executable...";
($out,$err,$exit) = capture {

    if( $binary_type eq 'deb' ) {
        system('perlapp --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;Moose;Class::MOP:: --icon "../../unpackaged assets/leela.ico" --scan ../extra_scan.pl --lib ../../lib --shared private --norunlib --force --exe build\bin\Schedule_sshealth.exe --perl C:\Perl\bin\perl.exe ..\..\bin\Schedule_sshealth.pl');
    }
    else {
        system('perlapp --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;Moose;Class::MOP:: --icon "../../unpackaged assets/leela.ico" --scan ../extra_scan.pl --lib ../../lib --shared private --norunlib --gui --force --exe build\bin\Schedule_sshealth.exe --perl C:\Perl\bin\perl.exe ..\..\bin\Schedule_sshealth.pl');
    }

};
die "Building Schedule_sshealth failed!" if $exit;
=pod
=cut
### }#}}}
    
my $zip = Archive::Zip->new();
$zip->addDirectory( $build_dir );
unless( $zip->writeToFileNamed($ARCHIVE_FILENAME_FULL->stringify) == AZ_OK ) {
die "Unable to write to archive $ARCHIVE_FILENAME_FULL.";
}

say "";
say "Done!  $ARCHIVE_FILENAME_FULL has been created.  build/ has been left for testing.";
say "";
say "If you attempt to test build/, remember that it's going to try to use databases in APPDIR,";
say "not the ones in ./build/user/.  Those get placed by the installer, so may not be there now,";
say "and ->deploy will not work from the executable.  So if the version in build\ doesn't function,";
say "go make sure that empty copies of the database are in users/USER/AppData/Roaming/.";
say "";

