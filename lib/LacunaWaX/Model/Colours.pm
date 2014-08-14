use v5.14;
use warnings;

package LacunaWaX::Model::Colours {
    use Moose;

    has 'background_gray' => (
        is          => 'ro',
        isa         => 'Wx::Colour',
        lazy        => 1,
        default     => sub{ return Wx::Colour->new(0xF2, 0xF1, 0xF0) }
    );

    has 'black' => (
        is          => 'ro',
        isa         => 'Wx::Colour',
        lazy        => 1,
        default     => sub{ return Wx::Colour->new(0x00, 0x00, 0x00) }
    );

    has 'white' => (
        is          => 'ro',
        isa         => 'Wx::Colour',
        lazy        => 1,
        default     => sub{ return Wx::Colour->new(0xFF, 0xFF, 0xFF) }
    );

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

=head1 NAME

LacunaWaX::Model::Colours - Default colors

=head1 SYNOPSIS

 use LacunaWaX::Model::Colours;

 my $gray = wxTheApp->colours->background_gray;
 say ref $gray;     # Wx::Colour

=head1 DESCRIPTION

There isn't much in here, but each time you create a color, do so in here
rather than manually creating the thing, so our palette stays consistent.

=head1 SEE ALSO

=head1 AUTHOR

Jonathan D. Barton (jdbarton@gmail.com)

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
