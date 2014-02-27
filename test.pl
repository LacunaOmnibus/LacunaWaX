
=pod

This actually works; perlapp is able to compile it to a runnable executable.



The goal here was to use perlapp to compile the following:
    use Moose;
    print "blarg\n";



Each attempt to create an .exe with perlapp was successful, in that an .exe 
was created with no warnings or errors from perlapp.  However, upon running 
that .exe, I'd get our old friend
    "Can't locate MODULENAME in @INC..."



One at a time, I added the modules that the .exe was complaining about here as 
use statements.  In some (many) cases, the new use statement had to preceed 
the one that was already there, which is why the numbered steps below are out 
of order.

I added each use statement below the rest at first, and then re-ran the .exe.  
If that same module (that I had just added) was still being complained about, 
I'd move it up one step and try again, until its complaint stopped.

=cut

#BEGIN {#{{{
    
    ### Step 1
    use Class::Load::XS;

    ### Step 7
    use Package::Stash::XS;

    ### Step 8
    use Moose;

    ### Step 2
    use Class::MOP::Mixin;

    ### Step 3
    use Class::MOP::Method::Generated;

    ### Step 4
    use Class::MOP::Method::Inlined;

    ### Step 5
    use Class::MOP::Module;

    ### Step 6
    use Class::MOP::Package;

    ### Step 9
    use Moose::Meta::Method;

    ### Step 10
    use Class::MOP::Class::Immutable::Trait;

    ### Step 11
    use Moose::Meta::Mixin::AttributeCore;

    ### 
    ### If we stop here, a simple print after the BEGIN block works as an 
    ### .exe.
    ###

#}#}}}
BEGIN {#{{{

    ### As soon as I uncomment the traits line, I get complaints about the 
    ### following two not being in @INC.
    
    #use Moose::Meta::Attribute::Native::Trait;
    #use Moose::Meta::Attribute::Native::Trait::Array;

    ### After adding those, this exception is thrown and I'm done.
    #Moose::Exception::IncompatibleMetaclassOfSuperclass;

}#}}}

use v5.14;
say "blarg";


package TestClass {#{{{
    use Moose;

    has 'an_attribute' => (
        is          => 'rw',
        isa         => 'ArrayRef',
        #traits      => ['Array'],
    );

}#}}}


