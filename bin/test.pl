#!/home/jon/perl5/perlbrew/perls/perl-5.18.1/bin/perl

use v5.14;
#use DateTime::Format::ISO8601;
use DateTime::Format::RFC3339;


my $f = DateTime::Format::RFC3339->new();
#my $dt = $f->parse_datetime('2002-07-01T13:50:05Z');
my $dt = DateTime::Format::RFC3339->parse_datetime('2002-07-01T13:50:05Z');
say $dt;

