package Astro::Nova;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Astro::Nova', $VERSION);

1;
__END__

=head1 NAME

Astro::Nova - Perl interface to libnova

=head1 SYNOPSIS

  use Astro::Nova qw(functions ...);
  my $hms = Astro::Nova::HMS->new();
  $hms->set_hours(12);
  ...

=head1 DESCRIPTION

A libnova wrapper. The goal of this documentation is to document the Perl wrapper,
not to reproduce the entire libnova documentation. Please find the documentation
at L<http://libnova.sourceforge.net/>.

In general, the available functions have the same name as the libnova functions, but with
the C<ln_> prefix removed. That means C<ln_get_mean_sidereal_time(JD)> becomes in Perl either
C<Astro::Nova::get_mean_sidereal_time($jd)> or if exported C<get_mean_sidereal_time($jd)>.

The functions' interfaces will be mostly the same as in C,
except that the libnova structs are available as Perl classes. See L</STRUCTS>.
If there are other changes to the interface, the changes will be documented in the
list of exported functions below.

=head2 EXPORT

None by default.

Many functions can be exported on demand. They will be added to the list
as they become available. The function list will look remotely like a C-level
signature but refer to classes instead of C structs. Some of the interfaces
have been changed to I<return> a value instead of passing pointers as arguments.
The C<ln_> prefix has been stripped.

  sidereal_time.h
    double get_mean_sidereal_time(double JD)
    double get_apparent_sidereal_time(double JD)

  abberation.h
    Astro::Nova::EquPosn get_equ_aber(Astro::Nova::EquPosn mean_position, double JD)
    Astro::Nova::LnLatPosn get_ecl_aber(Astro::Nova::LnLatPosn mean_position, double JD)

=head2 STRUCTS

libnova defines several structs for passing data to or receiving results from the
functions. These have been wrapped as Perl classes. Below is a list of the struct names,
their Perl class names, and their data members (including the C types). The class
constructors currently, do B<not> take arguments. Instead, you need to use the accessors
for the individual data members. If a member is called C<L>, then there will be
two methods C<get_L> and C<set_L> for getting/setting the data. All numeric data
is intialized to zero.

  Astro::Nova::Date, ln_date
    int years
    int months
    int days
    int hours
    int minutes
    double seconds
  
  Astro::Nova::DMS, ln_dms
    unsigned short  neg
    unsigned short  degrees
    unsigned short  minutes
    double  seconds
  
  Astro::Nova::EllOrbit, ln_ell_orbit
    double  a
    double  e
    double  i
    double  w
    double  omega
    double  n
    double  JD
  
  Astro::Nova::EquPosn, ln_equ_posn
    double  ra
    double  dec
  
  Astro::Nova::GalPosn, ln_gal_posn
    double  l
    double  b
  
  Astro::Nova::HelioPosn, ln_helio_posn
    double  L
    double  B
    double  R
  
  Astro::Nova::HMS, ln_hms
    unsigned short  hours
    unsigned short  minutes
    double  seconds
  
  Astro::Nova::HrzPosn, ln_hrz_posn
    double  az
    double  alt
  
  Astro::Nova::HypOrbit, ln_hyp_orbit
    double  q
    double  e
    double  i
    double  w
    double  omega
    double  JD
  
  Astro::Nova::LnLatPosn, ln_lnlat_posn
    double  lng
    double  lat
  
  Astro::Nova::Nutation, ln_nutation
    double  longitude
    double  obliquity
    double  ecliptic
  
  Astro::Nova::ParOrbit, ln_par_orbit
    double  q
    double  i
    double  w
    double  omega
    double  JD
  
  Astro::Nova::RectPosn, ln_rect_posn
    double  X
    double  Y
    double  Z
  
  Astro::Nova::RstTime, ln_rst_time
    double  rise
    double  set
    double  transit
  
  Astro::Nova::Zonedate, ln_zonedate
    int  years
    int  months
    int  days
    int  hours
    int  minutes
    double  seconds
    long  gmtoff

These are "human readable" composite structs that contain
others. Accessing their memebers with a getter method will
return a B<new copy> of the contained structure.

  Astro::Nova::HEquPosn, lnh_equ_posn
    struct ln_hms ra
    struct ln_dms dec
  
  Astro::Nova::HHrzPosn, lnh_hrz_posn
    struct ln_dms az
    struct ln_dms alt
  
  Astro::Nova::HLnLatPosn, lnh_lnlat_posn
    struct ln_dms lng
    struct ln_dms lat

=head1 SEE ALSO

libnova website: L<http://libnova.sourceforge.net/>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
