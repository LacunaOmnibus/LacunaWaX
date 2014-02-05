
md build
md build/bin
md build/user

REM These should work since I've got cygwin, but that's hardly portable.
REM They need to be windows-ified.
cp -p ../../user/assets.zip ./build/user/
cp -Rip ../../user/doc/     ./build/user/
cp -Rip ../../user/ico/     ./build/user/

REM LacunaWaX (main GUI)
perlapp --trim Games::Lacuna::Client --add Wx::;JSON::RPC::Common::;Params::Validate::*;DateTime::Locale::*;Bread::Board::;Moose::;MooseX::;SQL::Translator::;SQL::Abstract;Log::Dispatch::*;DateTime::Format::*;CHI::Driver::;LacunaWaX::;Games::Lacuna::Client::;Games::Lacuna::Cache;Games::Lacuna::Client::;Games::Lacuna::Client::;Games::Lacuna::Client;Games::Lacuna::Client::Buildings::** --icon "../../unpackaged assets/frai.ico" --icon "../../unpackaged assets/frai.ico" --scan ../extra_scan.pl --lib ..\..\lib --shared private --norunlib --force --exe build/bin/LacunaWaX --perl C:\Perl\bin\perl.exe ../../bin/LacunaWaX.pl

REM Archmin

REM Autovote

REM SS Health

REM Window-ify!
mv build LacunaWaX
tar -cvf "${ARCHIVE_FILENAME_BASE}.tar" LacunaWaX
gzip "${ARCHIVE_FILENAME_BASE}.tar"

REM Window-ify!
echo "Done!  $ARCHIVE_FILENAME_FULL has been created.  LacunaWaX/ has been left for testing.";
echo "";
echo "";
