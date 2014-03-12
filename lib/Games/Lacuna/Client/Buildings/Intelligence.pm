package Games::Lacuna::Client::Buildings::Intelligence;
{
  $Games::Lacuna::Client::Buildings::Intelligence::VERSION = '0.003';
}
use 5.0080000;
use strict;
use warnings;
use Carp 'croak';

use Games::Lacuna::Client;
use Games::Lacuna::Client::Buildings;

our @ISA = qw(Games::Lacuna::Client::Buildings);

sub api_methods {
  return {
    view                  => { default_args => [qw(session_id building_id)] },
    ### JDB new spy training update
    view_all_spies        => { default_args => [qw(session_id building_id)] },
    train_spy             => { default_args => [qw(session_id building_id)] },
    view_spies            => { default_args => [qw(session_id building_id)] },
    subsidize_training    => { default_args => [qw(session_id building_id)] },
    burn_spy              => { default_args => [qw(session_id building_id)] },
    name_spy              => { default_args => [qw(session_id building_id)] },
    assign_spy            => { default_args => [qw(session_id building_id)] },

    ### JDB 11/23/2012
    ### Server just updated with these new calls; I assume these will be added 
    ### to the official dist soon.
    view_all_spies      => { default_args => [qw(session_id building_id)] },

    ### This is documented at 
    ### https://us1.lacunaexpanse.com/api/Intelligence.html
    ###
    ### However, as of 04/02/2013, it's commented out in the server code
    ### https://github.com/plainblack/Lacuna-Server-Open/blob/master/lib/Lacuna/RPC/Building/Intelligence.pm
    ### "This call is too intensive for server at this time. Disabled"
    ### ...so don't try running it.
    view_empire_spies   => { default_args => [qw(session_id building_id)] },
  };
}

__PACKAGE__->init();

1;
__END__

=head1 NAME

Games::Lacuna::Client::Buildings::Intelligence - The Intelligence Ministry building

=head1 SYNOPSIS

  use Games::Lacuna::Client;

=head1 DESCRIPTION

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
