use v5.14;
use warnings;

package LacunaWaX::Preload::Perlapp {

    use Class::Load::XS;                            # 1
    use Package::Stash::XS;                         # 7
    use Moose;                                      # 8
    use Class::MOP::Mixin;                          # 2
    use Class::MOP::Method::Generated;              # 3
    use Class::MOP::Method::Inlined;                # 4
    use Class::MOP::Module;                         # 5
    use Class::MOP::Package;                        # 6
    use Moose::Meta::Method;                        # 9
    use Class::MOP::Class::Immutable::Trait;        # 10
    use Moose::Meta::Mixin::AttributeCore;          # 11

}

1;
