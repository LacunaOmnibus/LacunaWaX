
package LacunaWaX::Model::SStation {
    use v5.14;
    use utf8;
    use open qw(:std :utf8);
    use Data::Dumper;
    use Moose;
    use Try::Tiny;

    has 'id'        => (is => 'rw', isa => 'Int',                           required => 1       );
    has 'name'      => (is => 'rw', isa => 'Str',                           lazy_build => 1     );
    has 'status'    => (is => 'rw', isa => 'HashRef',                       lazy_build => 1     );
    has 'body'      => (is => 'rw', isa => 'Games::Lacuna::Client::Body',   lazy_build => 1     );

    has 'game_client' => (
        is          => 'rw', 
        isa         => 'LacunaWaX::Model::Client', 
        required    => 1,
    );

    has 'command' => (
        is          => 'rw',
        isa         => 'Maybe[LacunaWaX::Model::SStation::Command]', 
        lazy_build  => 1,
    );
    has 'police' => (
        is          => 'rw',
        isa         => 'Maybe[LacunaWaX::Model::SStation::Police]', 
        lazy_build  => 1,
        handles => {
            incoming_hostiles => 'incoming_hostiles',
            has_hostile_spies => 'has_hostile_spies',
        }
    );

    has 'laws' => (
        is          => 'rw',
        isa         => 'ArrayRef[HashRef]', 
        lazy_build  => 1,
        documentation => q{
            id, name, description, date_enacted
        }
    );

    sub BUILD {
        my $self = shift;

        ### Gotta force this lazy builder.
        $self->police;

        unless( $self->command ) {
            ### All stations have a command center.  So here, we have prefs 
            ### for an old station that has gone away, or the user is running 
            ### under somebody else's account (somebody in a different 
            ### alliance).
            ###
            ### In that case, $self->command is undef, but $self->has_command 
            ### still returns true, since the attribute is a Maybe[], and it 
            ### has been set.  Clearing it will cause calls to has_command() 
            ### to return false.
            $self->clear_command;
        }

        return $self;
    }
    sub _build_name {#{{{
        my $self = shift;
        return $self->game_client->planet_name ($self->id ) || q{};
    }#}}}
    sub _build_body {#{{{
        my $self = shift;
        return $self->game_client->get_body( $self->id );
    }#}}}
    sub _build_command {#{{{
        my $self = shift;
        my $bldg = try {
            $self->game_client->get_building($self->id, 'command');
        };

        my $comm = undef;
        if( $bldg ) {
            $comm = LacunaWaX::Model::SStation::Command->new( 
                scc         => $bldg,
                game_client => $self->game_client,
            )
        }

        return $comm;
    }#}}}
    sub _build_laws {#{{{
        my $self = shift;
        my $v = $self->body->view_laws();
        return $v->{'laws'};
    }#}}}
    sub _build_police {#{{{
        my $self = shift;
        my $bldg = try {
            $self->game_client->get_building($self->id, 'Police');
        };

        my $popo = undef;
        if( $bldg ) {
            $popo = LacunaWaX::Model::SStation::Police->new( 
                precinct    => $bldg,
                game_client => $self->game_client,
            )
        }
        return $popo;
    }#}}}
    sub _build_status {#{{{
        my $self = shift;
        my $s = try {
            $self->game_client->get_body_status( $self->id );
        }
        catch {
            $self->poperr("$_->{'text'} ($_)");
            return;
        };
        return $s;
    }#}}}

    sub has_law {#{{{
        my $self = shift;
        my $cand = shift;

        my $gotit = 0;
        CHECKLAW:
        foreach my $l( @{$self->laws} ) {
            if( $l->{'name'} eq $cand ) {
                $gotit = 1;
                last CHECKLAW;
            }
        }
        return $gotit;
    }#}}}
    sub subpar_res {#{{{
        my $self = shift;
        my $min  = shift;

        my $view = $self->game_client->get_building_view(
            $self->id, 
            $self->command->scc,
        );

        foreach my $res( qw(food ore water energy) ) {
            my $rate = $res . '_hour';
            if( $view->{'status'}{'body'}{$rate} < $min ) {
                ### No need to report on all res types that are too low; as 
                ### soon as we find one, the user will have to go check on 
                ### that, and will see the others if they're too low as well.
                return $res;
            }
        }

        return 0;   # res/hr is fine
    }#}}}
    sub star_unseized {#{{{
        my $self = shift;

=pod

Returns true if the star orbited by the station has not been seized by anybody.

=cut

        return ( defined $self->status->{'station'} ) ? 0 : 1;
    }#}}}
    sub star_seized_by_other {#{{{
        my $self = shift;

=pod

Returns true if the star orbited by the station has been seized by a station 
other than the current station.

=cut

        return 0 if $self->star_unseized;
        if( $self->status->{'station'}{'name'} ne $self->name ) {
            return 1;
        }
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
