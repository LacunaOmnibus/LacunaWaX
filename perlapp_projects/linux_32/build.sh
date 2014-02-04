#!/bin/bash

source /home/jon/bin/as_perl.sh

clear;
echo "";
echo "There will be a lot of 'missing module' errors showing up below.  They're expected and should be nothing to worry about.";
echo "";
echo "Are you ready to begin?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo "Here we go..."; echo ""; echo ""; break;;
        No ) exit;;
    esac
done

ARCHIVE_FILENAME_BASE="LacunaWaX_linux64";
ARCHIVE_FILENAME_FULL="${ARCHIVE_FILENAME_BASE}.tar.gz";

if [ -e build ] 
    then
        echo "Removing existing build directory";
        rm -rf build;
fi

if [ -e LacunaWaX ] 
    then
        echo "Removing existing LacunaWaX directory";
        rm -rf LacunaWaX;
fi

if [ -e $ARCHIVE_FILENAME_FULL ] 
    then
        echo "Removing existing $ARCHIVE_FILENAME_FULL archive";
        rm -rf $ARCHIVE_FILENAME_FULL;
fi

mkdir build
mkdir build/bin
mkdir build/user

cp -p ../../user/assets.zip ./build/user/
cp -Rip ../../user/doc/     ./build/user/
cp -Rip ../../user/ico/     ./build/user/

### LacunaWaX (main GUI)
perlapp --trim "Games::Lacuna::Client" --add "Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;LacunaWaX::;Games::Lacuna::Client::;Games::Lacuna::Cache;Games::Lacuna::Client::;Games::Lacuna::Client::;Games::Lacuna::Client;Games::Lacuna::Client::Buildings::**" --icon "../../unpackaged assets/frai.ico" --icon "../../unpackaged assets/frai.ico" --scan ../extra_scan.pl --lib ../../lib --shared private --norunlib --force --exe build/bin/LacunaWaX --perl /home/jon/opt/as_perl_5.16/bin/perl-static ../../bin/LacunaWaX.pl

### Archmin
perlapp --add "Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;Moose" --icon "../../unpackaged assets/leela.ico" --scan ../extra_scan.pl --lib ../../lib --shared private --norunlib --force --exe build/bin/Schedule_archmin --perl /home/jon/opt/as_perl_5.16/bin/perl-static ../../bin/Schedule_archmin.pl

### Autovote
perlapp --add "Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;Moose" --icon "../../unpackaged assets/leela.ico" --scan ../extra_scan.pl --lib ../../lib --shared private --norunlib --force --exe build/bin/Schedule_autovote --perl /home/jon/opt/as_perl_5.16/bin/perl-static ../../bin/Schedule_autovote.pl

### SS Health
perlapp --add "Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;Moose" --icon "../../unpackaged assets/leela.ico" --scan ../extra_scan.pl --lib ../../lib --shared private --norunlib --force --exe build/bin/Schedule_sshealth --perl /home/jon/opt/as_perl_5.16/bin/perl-static ../../bin/Schedule_sshealth.pl

mv build LacunaWaX
tar -cvf "${ARCHIVE_FILENAME_BASE}.tar" LacunaWaX
gzip "${ARCHIVE_FILENAME_BASE}.tar"

echo "Done!  $ARCHIVE_FILENAME_FULL has been created.  LacunaWaX/ has been left for testing.";
echo "";
echo "";
