package Games::Lacuna::Client::Buildings::Embassy;
{
  $Games::Lacuna::Client::Buildings::Embassy::VERSION = '0.003';
}
use 5.0080000;
use strict;
use Carp 'croak';
use warnings;

use Games::Lacuna::Client;
use Games::Lacuna::Client::Buildings;

our @ISA = qw(Games::Lacuna::Client::Buildings);

sub api_methods {
  return {
    view                   => { default_args => [qw(session_id building_id)] },
    get_alliance_status    => { default_args => [qw(session_id building_id)] },
    create_alliance        => { default_args => [qw(session_id building_id)] },
    dissolve_alliance      => { default_args => [qw(session_id building_id)] },
    send_invite            => { default_args => [qw(session_id building_id)] },
    withdraw_invite        => { default_args => [qw(session_id building_id)] },
    accept_invite          => { default_args => [qw(session_id building_id)] },
    reject_invite          => { default_args => [qw(session_id building_id)] },
    get_pending_invites    => { default_args => [qw(session_id building_id)] },
    get_my_invites         => { default_args => [qw(session_id building_id)] },
    assign_alliance_leader => { default_args => [qw(session_id building_id)] },
    update_alliance        => { default_args => [qw(session_id building_id)] },
    leave_alliance         => { default_args => [qw(session_id building_id)] },
    expel_member           => { default_args => [qw(session_id building_id)] },
    view_stash             => { default_args => [qw(session_id building_id)] },
    donate_to_stash        => { default_args => [qw(session_id building_id)] },
    exchange_with_stash    => { default_args => [qw(session_id building_id)] },

    ### JDB new SS changes
    view_laws                                       => { default_args => [qw(session_id building_id)] },
    view_propositions                               => { default_args => [qw(session_id building_id)] },
    cast_vote                                       => { default_args => [qw(session_id)] },
    propose_writ                                    => { default_args => [qw(session_id building_id)] },
    propose_repeal_law                              => { default_args => [qw(session_id building_id)] },
    get_stars_in_jurisdiction                       => { default_args => [qw(session_id building_id)] },
    get_bodies_for_stars_in_jurisdiction            => { default_args => [qw(session_id building_id)] },
    get_mining_platforms_for_stars_in_jurisdiction  => { default_args => [qw(session_id building_id)] },
    get_excavators_for_stars_in_jurisdiction        => { default_args => [qw(session_id building_id)] },
    propose_focus_influence_on_star                 => { default_args => [qw(session_id building_id)] },
    propose_rename_star                             => { default_args => [qw(session_id building_id)] },
    propose_broadcast_on_network19                  => { default_args => [qw(session_id building_id)] },
    propose_induct_member                           => { default_args => [qw(session_id building_id)] },
    propose_expel_member                            => { default_args => [qw(session_id building_id)] },
    propose_elect_new_leader                        => { default_args => [qw(session_id building_id)] },
    propose_rename_asteroid                         => { default_args => [qw(session_id building_id)] },
    propose_rename_uninhabited                      => { default_args => [qw(session_id building_id)] },
    propose_members_only_mining_rights              => { default_args => [qw(session_id building_id)] },
    propose_evict_mining_platform                   => { default_args => [qw(session_id building_id)] },
    propose_members_only_colonization               => { default_args => [qw(session_id building_id)] },
    propose_neutralize_bhg                          => { default_args => [qw(session_id building_id)] },
    propose_transfer_station_ownership              => { default_args => [qw(session_id building_id)] },
    propose_fire_bfg                                => { default_args => [qw(session_id building_id)] },

  };
}

__PACKAGE__->init();

1;
__END__

=head1 NAME

Games::Lacuna::Client::Buildings::Embassy - The Embassy building

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
