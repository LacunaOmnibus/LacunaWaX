
package LacunaWaX::Model::SStation::Command {
    use v5.14;
    use utf8;
    use open qw(:std :utf8);
    use Data::Dumper;
    use List::Util qw(first);
    use Moose;
    use POSIX qw(ceil);
    use Try::Tiny;
    use URI;
    use URI::Query;

    has 'scc' => (
        is          => 'rw',
        isa         => 'Games::Lacuna::Client::Buildings::StationCommand', 
        required    => 1,
    );

    has 'game_client' => (
        is          => 'rw', 
        isa         => 'LacunaWaX::Model::Client', 
        required    => 1,
    );

    has 'alliance_members' => (
        is          => 'rw',
        isa         => 'ArrayRef',
        lazy_build  => 1,
    );

    sub _build_alliance_members {#{{{
        my $self = shift;
        my $ar = [];
        $ar = try {
            $self->game_client->get_alliance_members('as array ref');
        }
        catch {
            my $msg = (ref $_) ? $_->text : $_;
            "Unable to get current player's alliance members: $msg";
        };

        return $ar;
    }#}}}


    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

LacunaWaX::Model::Lottery::Link - Link to a voting site

=head1 SYNOPSIS

 use LacunaWaX::Model::Lottery::Link;

 $l = LacunaWaX::Model::Lottery::Link->new(
  name => $name,
  url  => $url
 );

=head1 DESCRIPTION

You won't normally need to use this module or construct objects from it 
explicitly.  Instead, you'll use L<LacunaWaX::Model::Lottery::Links|the Links 
module> to construct a list of links.

=cut
