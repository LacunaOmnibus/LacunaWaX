

package LacunaWaX::Util {
    use v5.14;
    use strict;
    use warnings;
    use FindBin;

    sub find_root {#{{{

        my $root_dir = "$FindBin::Bin/..";

        ### $env is going to get modified by the build process to "msi", so 
        ### the installed version can know it is the installed version, not 
        ### the source version.
        ###
        ### That modification is a simple regex in the build script - do not mess 
        ### with the $env assignment line below, or you're likely to break that 
        ### part of the build script.
        my $env = 'source';    

        if( $^O eq 'MSWin32' ) {
            $root_dir = $ENV{'APPDATA'} . '/LacunaWaX' if $env eq 'msi';
        }

        return $root_dir;
    }#}}}

}

1;

__END__

 vim: syntax=perl
