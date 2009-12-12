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

  abberation.h
    Astro::Nova::EquPosn get_equ_aber(Astro::Nova::EquPosn mean_position, double JD)
    Astro::Nova::LnLatPosn get_ecl_aber(Astro::Nova::LnLatPosn mean_position, double JD)
  
  airmass.h
    double get_airmass(double alt, double airmass_scale)
  
  angular_separation.h
    double get_angular_separation(Astro::Nova::EquPosn posn1, Astro::Nova::EquPosn posn2)
    double get_rel_posn_angle(Astro::Nova::EquPosn posn1, Astro::Nova::EquPosn posn2)
  
  apparent_position.h
    Astro::Nova::EquPosn get_apparent_posn(Astro::Nova::EquPosn mean_position,
                                           Astro::Nova::EquPosn proper_motion,
                                           double JD)
  
  asteroid.h
    double get_asteroid_mag(double JD, Astro::Nova::EllOrbit orbit, double H, double G)
    double get_asteroid_sdiam_km(double H, double A)
    double get_asteroid_sdiam_arc(double JD, Astro::Nova::EllOrbit orbit, double H, double A)
  
  comet.h
    double get_ell_comet_mag(double JD, Astro::Nova::EllOrbit orbit, double g, double k)
    double get_par_comet_mag(double JD, Astro::Nova::ParOrbit orbit, double g, double k)
  
  dynamical_time.h
    double get_dynamical_time_diff(double JD)
    double get_jde(double JD)
  
  sidereal_time.h
    double get_mean_sidereal_time(double JD)
    double get_apparent_sidereal_time(double JD)
  
  earth.h
    Astro::Nova::HelioPosn get_earth_helio_coords(double JD)
    double get_earth_solar_dist(double JD)
    Astro::Nova::RectPosn get_earth_rect_helio(double JD)
    (double $p_sin_o, double $p_cos_o) = get_earth_centre_dist(float height, double latitude)
  
  elliptic_motion.h
    double solve_kepler(double e, double M)
    double get_ell_mean_anomaly(double n, double delta_JD)
    double get_ell_true_anomaly(double e, double E)
    double get_ell_radius_vector(double a, double e, double E)
    double get_ell_smajor_diam(double e, double q)
    double get_ell_sminor_diam(double e, double a)
    double get_ell_mean_motion(double a)
    Astro::Nova::RectPosn get_ell_geo_rect_posn(Astro::Nova::EllOrbit orbit, double JD)
    Astro::Nova::RectPosn get_ell_helio_rect_posn(Astro::Nova::EllOrbit orbit, double JD)
    double get_ell_orbit_len(Astro::Nova::EllOrbit orbit)
    double get_ell_orbit_vel(double JD, Astro::Nova::EllOrbit orbit)
    double get_ell_orbit_pvel(Astro::Nova::EllOrbit orbit)
    double get_ell_orbit_avel(Astro::Nova::EllOrbit orbit)
    double get_ell_body_phase_angle(double JD, Astro::Nova::EllOrbit orbit)
    double get_ell_body_elong(double JD, Astro::Nova::EllOrbit orbit)
    double get_ell_body_solar_dist(double JD, Astro::Nova::EllOrbit orbit)
    double get_ell_body_earth_dist(double JD, Astro::Nova::EllOrbit orbit)
    Astro::Nova::EquPosn get_ell_body_equ_coords(double JD, Astro::Nova::EllOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::EllOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                               Astro::Nova::EllOrbit orbit, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_next_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::EllOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_next_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                                    Astro::Nova::EllOrbit orbit, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_ell_body_next_rst_horizon_futur(double JD, Astro::Nova::LnLatPosn observer,
                                          Astro::Nova::EllOrbit orbit, double horizon,
                                          int day_limit)
    double get_ell_last_perihelion(double epoch_JD, double M, double n)
  
  heliocentric_time.h
    double get_heliocentric_time_diff(double JD, Astro::Nova::EquPosn object)
  
  hyperbolic_motion.h
    double solve_hyp_barker(double Q1, double G, double t)
    double get_hyp_true_anomaly(double q, double e, double t)
    double get_hyp_radius_vector(double q, double e, double t)
    Astro::Nova::RectPosn get_hyp_geo_rect_posn(Astro::Nova::HypOrbit orbit, double JD)
    Astro::Nova::RectPosn get_hyp_helio_rect_posn(Astro::Nova::HypOrbit orbit, double JD)
    Astro::Nova::EquPosn get_hyp_body_equ_coords(double JD, Astro::Nova::HypOrbit orbit)
    double get_hyp_body_earth_dist(double JD, Astro::Nova::HypOrbit orbit)
    double get_hyp_body_solar_dist(double JD, Astro::Nova::HypOrbit orbit)
    double get_hyp_body_phase_angle(double JD, Astro::Nova::HypOrbit orbit)
    double get_hyp_body_elong(double JD, Astro::Nova::HypOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::HypOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                               Astro::Nova::HypOrbit orbit, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_next_rst(double JD, Astro::Nova::LnLatPosn observer, Astro::Nova::HypOrbit orbit)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_next_rst_horizon(double JD, Astro::Nova::LnLatPosn observer,
                                    Astro::Nova::HypOrbit orbit, double horizon)
    (int $status, Astro::Nova::RstTime $rst) =
      get_hyp_body_next_rst_horizon_future(double JD, Astro::Nova::LnLatPosn observer,
                                           Astro::Nova::HypOrbit orbit, double horizon,
                                           int day_limit)
  
  julian_day.h
    double get_julian_day(Astro::Nova::Date date)
    Astro::Nova::Date get_date(double JD)
    Astro::Nova::Date get_date_from_timet(time_t t) (time_t is an integer)
    Astro::Nova::ZoneDate get_local_date(double JD)
    unsigned int get_day_of_week(Astro::Nova::Date date)
    double get_julian_from_sys()
    Astro::Nova::Date get_date_from_sys()
    double get_julian_from_timet(time_t t) (time_t is an integer)
    time_t get_timet_from_julian(double JD) (time_t is an integer)
    double get_julian_local_date(Astro::Nova::ZoneDate zonedate)
    Astro::Nova::ZoneDate date_to_zonedate(Astro::Nova::Date date, long gmtoff)
    Astro::Nova::Date zonedate_to_date(Astro::Nova::ZoneDate zonedate)
  
  jupiter.h
    double get_jupiter_equ_sdiam(double JD)
    double get_jupiter_pol_sdiam(double JD)
    Astro::Nova::RstTime get_jupiter_rst(double JD)
    Astro::Nova::HelioPosn get_jupiter_helio_coords(double JD)
    Astro::Nova::EquPosn get_jupiter_equ_coords(double JD)
    double get_jupiter_earth_dist(double JD)
    double get_jupiter_solar_dist(double JD)
    double get_jupiter_magnitude(double JD)
    double get_jupiter_disk(double JD)
    double get_jupiter_phase(double JD)
    Astro::Nova::RectPosn get_jupiter_rect_helio(double JD)
  
  lunar.h
    double get_lunar_sdiam(double JD)
    Astro::Nova::RstTime get_lunar_rst(double JD, Astro::Nova::LnLatPosn observer)
    Astro::Nova::RectPosn get_lunar_geo_posn(double JD, double precision)
    Astro::Nova::EquPosn get_lunar_equ_coords_prec(double JD, double precision)
    Astro::Nova::EquPosn get_lunar_equ_coords(double JD)
    Astro::Nova::LnLatPosn get_lunar_ecl_coords(double JD, double precision)
    double get_lunar_phase(double JD)
    double get_lunar_disk(double JD)
    double get_lunar_earth_dist(double JD)
    double get_lunar_bright_limb(double JD)
    double get_lunar_long_asc_node(double JD)
    double get_lunar_long_perigee(double JD)

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
