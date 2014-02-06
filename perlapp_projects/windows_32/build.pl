#!/usr/bin/env perl

use v5.16;
use Archive::Zip qw(:ERROR_CODES);
use File::Mirror;
use Path::Tiny;
use Term::Prompt;

system('cls');
say "";
say "There will be a lot of 'missing module' errors showing up below.  They're expected and should be nothing to worry about.";
say "";
my $r = prompt('y', 'Are you ready to begin?', 'Y/N', 'N');
exit unless $r;
say "Here we go...";
say "";

my $ARCHIVE_FILENAME_BASE   = path("LacunaWaX_win32");
my $ARCHIVE_FILENAME_FULL   = path("${ARCHIVE_FILENAME_BASE}.zip");
my $build_dir               = path('build');
my $lw_dir                  = path('LacunaWaX');

if( $build_dir->exists ) {
    say "Removing existing build directory";
    $build_dir->remove_tree;
} 
if( $lw_dir->exists ) {
    say "Removing existing LacunaWaX directory";
    $lw_dir->remove_tree;
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

### LacunaWaX (main GUI)
system('perlapp --trim Games::Lacuna::Client --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;LacunaWaX::;Games::Lacuna::Client::;Games::Lacuna::Cache;Games::Lacuna::Client::;Games::Lacuna::Client::;Games::Lacuna::Client;Games::Lacuna::Client::Buildings::** --icon "../../unpackaged assets/frai.ico" --icon "../../unpackaged assets/frai.ico" --scan ../extra_scan.pl --lib ..\..\lib --shared private --norunlib --force --exe build/bin/LacunaWaX --perl C:\Perl\bin\perl.exe ../../bin/LacunaWaX.pl');

### Archmin

### Autovote

### SS Health

$build_dir->move('LacunaWaX');
my $zip = Archive::Zip->new();
$zip->addDirectory( $build_dir );
unless( $zip->writeToFileNamed($ARCHIVE_FILENAME_FULL->stringify) == AZ_OK ) {
    die "Unable to write to archive $ARCHIVE_FILENAME_FULL.";
}

say "Done!  $ARCHIVE_FILENAME_FULL has been created.  LacunaWaX/ has been left for testing.";
say "";

