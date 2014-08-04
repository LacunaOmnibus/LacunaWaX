
use v5.14;

package LacunaWaX::Model::Dates {

    use DateTime;

    sub parse_lacuna {
        my $self = shift;
        my $date = shift;

        my $dt;
        if( $date =~ m/^(\d{2}) (\d{2}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) \+0000/ ) {
            $dt = DateTime->new(
                day         => $1,
                month       => $2,
                year        => $3,
                hour        => $4,
                minute      => $5,
                second      => $6,
                time_zone   => 'UTC',
            );
        }
        else {
            die "Bad date string provided: $date";
        }

        return $dt;
    }

}

1;

__END__

=head1 NAME

LacunaWaX::Dates - Common date/time utilities

=head1 SYNOPSIS

 use LacunaWaX::Dates;

 my $d = '21 08 2011 04:25:09 +0000';
 my $dt = LacunaWaX::Dates::parse_lacuna( $d );
 say $dt->year;    # 2011   

=head1 DESCRIPTION

Ultimately meant to provide any date-munging we need

=head2 parse_lacuna( $TLE_formatted_datetime_string )

Accepts a TLE datetime string, returns a DateTime object.

=head1 AUTHOR

Jonathan D. Barton (jdbarton@gmail.com)

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
