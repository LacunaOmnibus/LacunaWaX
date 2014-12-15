package Games::Lacuna::Client::Inbox;
{
  $Games::Lacuna::Client::Inbox::VERSION = '0.003';
}
use 5.0080000;
use strict;
use warnings;
use Carp 'croak';

use Games::Lacuna::Client;
use Games::Lacuna::Client::Module;
our @ISA = qw(Games::Lacuna::Client::Module);

### JDB
### This is the original.  It was assumed that all methods would always have 
### positional parameters, but TT is adding trash_messages_where to have named 
### parameters, so this entire method is now broken.
#sub api_methods {
#  return {
#    (
#      map {
#        ($_ => { default_args => [qw(session_id)] })
#      }
#        ### JDB added trash_messages_where
#      qw(
#        view_inbox
#        view_archived
#        view_trashed
#        view_sent
#        read_message
#        archive_messages
#        trash_messages
#        trash_messages_where
#        send_message
#      )
#    ),
#  };
#}


### JDB I copied this more standard structure from Map.pm and filled it out 
### with Inbox methods.
sub api_methods {
  return {
    view_inbox              => { default_args => [qw(session_id)] },
    view_archived           => { default_args => [qw(session_id)] },
    view_trashed            => { default_args => [qw(session_id)] },
    view_sent               => { default_args => [qw(session_id)] },
    read_message            => { default_args => [qw(session_id)] },
    archive_messages        => { default_args => [qw(session_id)] },
    trash_messages          => { default_args => [qw(session_id)] },
    trash_messages_where    => { default_args => [qw(session_id)] },
    send_message            => { default_args => [qw(session_id)] },
  };
}


### JDB I don't know why this exists; it was commented out when I got here.
#sub new {
#  my $class = shift;
#  my %opt = @_;
#  my $self = $class->SUPER::new(@_);
#  bless $self => $class;
#  $self->{body_id} = $opt{id};
#  return $self;
#}


__PACKAGE__->init();

1;
__END__

=head1 NAME

Games::Lacuna::Client::Inbox - The inbox module

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
