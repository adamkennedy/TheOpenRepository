package Astro::Hipparcos;

use 5.008;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Astro::Hipparcos', $VERSION);

sub new {
  my $class = shift;
  my $file = shift;
  croak("Need catalog file") if not defined $file;
  croak("Specified catalog file '$file' does not exist") if not -e $file;
  open my $ifh, '<', $file or die "Could not open file '$file' for reading: $!";
  my $self = bless {
    fh => $ifh,
    filename => $file,
  } => $class;
  return $self;
}

sub get_record {
  my $self = shift;
  my $fh = $self->{fh};
  my $line = <$fh>;
  return if not defined $line;
  my $record = Astro::Hipparcos::Record->new();
  $record->ParseRecord($line);
  return $record;
}

1;
__END__

=head1 NAME

Astro::Hipparcos - Perl extension for reading the Hipparcos star catalog

=head1 SYNOPSIS

  use Astro::Hipparcos;
  my $catalog = Astro::Hipparcos->new("thefile.dat");
  while (defined(my $record = $catalog->get_record())) {
    print $record->get_HIP(), "\n"; # print record id
  }

=head1 DESCRIPTION

This is an extension for reading the Hipparcos star catalog.

=head1 METHODS

=head2 new

Given a file name, returns a new Astro::Hipparcos catalog
object.

=head2 get_record

Returns the next record (line) from the catalog as an L<Astro::Hipparcos::Record>
object.

=head1 SEE ALSO

L<Astro::Hipparcos::Record>

L<http://en.wikipedia.org/wiki/Hipparcos_Catalogue>

At the time of this writing, you could obtain a copy of the Hipparcos catalogue
from L<ftp://adc.gsfc.nasa.gov/pub/adc/archives/catalogs/1/1239/> (hip_main.dat.gz).

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
