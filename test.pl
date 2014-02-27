
use v5.14;
use LacunaWaX::Preload::Perlapp;


say "blarg";


package TestClass {#{{{
    use Moose;

    has 'an_attribute' => (
        is          => 'rw',
        isa         => 'ArrayRef',
        #traits      => ['Array'],
    );

}#}}}


