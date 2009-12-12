#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libnova/aberration.h>
#include <libnova/airmass.h>
#include <libnova/angular_separation.h>
#include <libnova/apparent_position.h>
#include <libnova/asteroid.h>
#include <libnova/comet.h>
#include <libnova/dynamical_time.h>
#include <libnova/earth.h>
#include <libnova/elliptic_motion.h>
#include <libnova/heliocentric_time.h>
#include <libnova/hyperbolic_motion.h>
#include <libnova/julian_day.h>
#include <libnova/jupiter.h>
#include <libnova/libnova.h>
#include <libnova/ln_types.h>
#include <libnova/lunar.h>
#include <libnova/mars.h>
#include <libnova/mercury.h>
#include <libnova/neptune.h>
#include <libnova/nutation.h>
#include <libnova/parabolic_motion.h>
#include <libnova/parallax.h>
#include <libnova/pluto.h>
#include <libnova/precession.h>
#include <libnova/proper_motion.h>
#include <libnova/refraction.h>
#include <libnova/rise_set.h>
#include <libnova/saturn.h>
#include <libnova/sidereal_time.h>
#include <libnova/solar.h>
#include <libnova/transform.h>
#include <libnova/uranus.h>
#include <libnova/utility.h>
#include <libnova/venus.h>
#include <libnova/vsop87.h>

/*
char *
asctime(__tp)
	__const struct tm *	__tp

char *
asctime_r(__tp, __buf)
	__const struct tm * __restrict	__tp
	char * __restrict	__buf

clock_t
clock()

int
clock_getcpuclockid(__pid, __clock_id)
	pid_t	__pid
	clockid_t *	__clock_id

int
clock_getres(__clock_id, __res)
	clockid_t	__clock_id
	struct timespec *	__res

int
clock_gettime(__clock_id, __tp)
	clockid_t	__clock_id
	struct timespec *	__tp

int
clock_nanosleep(__clock_id, __flags, __req, __rem)
	clockid_t	__clock_id
	int	__flags
	__const struct timespec *	__req
	struct timespec *	__rem

int
clock_settime(__clock_id, __tp)
	clockid_t	__clock_id
	__const struct timespec *	__tp

char *
ctime(__timer)
	__const time_t *	__timer

char *
ctime_r(__timer, __buf)
	__const time_t * __restrict	__timer
	char * __restrict	__buf

double
difftime(__time1, __time0)
	time_t	__time1
	time_t	__time0

int
dysize(__year)
	int	__year

struct tm *
getdate(__string)
	__const char *	__string

int
getdate_r(__string, __resbufp)
	__const char * __restrict	__string
	struct tm * __restrict	__resbufp

struct tm *
gmtime(__timer)
	__const time_t *	__timer

struct tm *
gmtime_r(__timer, __tp)
	__const time_t * __restrict	__timer
	struct tm * __restrict	__tp

void
ln_add_hms(source, dest)
	struct ln_hms *	source
	struct ln_hms *	dest

void
ln_add_secs_hms(hms, seconds)
	struct ln_hms *	hms
	double	seconds

double
ln_calc_series(data, terms, t)
	const struct ln_vsop *	data
	int	terms
	double	t

void
ln_date_to_zonedate(date, zonedate, gmtoff)
	struct ln_date *	date
	struct ln_zonedate *	zonedate
	long	gmtoff

void
ln_deg_to_dms(degrees, dms)
	double	degrees
	struct ln_dms *	dms

void
ln_deg_to_hms(degrees, hms)
	double	degrees
	struct ln_hms *	hms

double
ln_deg_to_rad(degrees)
	double	degrees

double
ln_dms_to_deg(dms)
	struct ln_dms *	dms

double
ln_dms_to_rad(dms)
	struct ln_dms *	dms

void
ln_equ_to_hequ(pos, hpos)
	struct ln_equ_posn *	pos
	struct lnh_equ_posn *	hpos

double
ln_get_airmass(alt, airmass_scale)
	double	alt
	double	airmass_scale

double
ln_get_angular_separation(posn1, posn2)
	struct ln_equ_posn *	posn1
	struct ln_equ_posn *	posn2

void
ln_get_apparent_posn(mean_position, proper_motion, JD, position)
	struct ln_equ_posn *	mean_position
	struct ln_equ_posn *	proper_motion
	double	JD
	struct ln_equ_posn *	position

double
ln_get_asteroid_mag(JD, orbit, H, G)
	double	JD
	struct ln_ell_orbit *	orbit
	double	H
	double	G

double
ln_get_asteroid_sdiam_arc(JD, orbit, H, A)
	double	JD
	struct ln_ell_orbit *	orbit
	double	H
	double	A

double
ln_get_asteroid_sdiam_km(H, A)
	double	H
	double	A

int
ln_get_body_next_rst_horizon(JD, observer, arg2, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	void ( * get_equ_body_coords ) ( double, struct ln_equ_posn * )	arg2
	double	horizon
	struct ln_rst_time *	rst

int
ln_get_body_next_rst_horizon_future(JD, observer, arg2, horizon, day_limit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	void ( * get_equ_body_coords ) ( double, struct ln_equ_posn * )	arg2
	double	horizon
	int	day_limit
	struct ln_rst_time *	rst

int
ln_get_body_rst_horizon(JD, observer, arg2, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	void ( * get_equ_body_coords ) ( double, struct ln_equ_posn * )	arg2
	double	horizon
	struct ln_rst_time *	rst

void
ln_get_date(JD, date)
	double	JD
	struct ln_date *	date

int
ln_get_date_from_mpc(date, mpc_date)
	struct ln_date *	date
	char *	mpc_date

void
ln_get_date_from_sys(date)
	struct ln_date *	date

void
ln_get_date_from_timet(t, date)
	time_t *	t
	struct ln_date *	date

void
ln_get_date_from_tm(t, date)
	struct tm *	t
	struct ln_date *	date

unsigned int
ln_get_day_of_week(date)
	struct ln_date *	date

double
ln_get_dec_location(s)
	char *	s

double
ln_get_dynamical_time_diff(JD)
	double	JD

void
ln_get_earth_centre_dist(height, latitude, p_sin_o, p_cos_o)
	float	height
	double	latitude
	double *	p_sin_o
	double *	p_cos_o

void
ln_get_earth_helio_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

void
ln_get_earth_rect_helio(JD, position)
	double	JD
	struct ln_rect_posn *	position

double
ln_get_earth_solar_dist(JD)
	double	JD

void
ln_get_ecl_from_equ(object, JD, position)
	struct ln_equ_posn *	object
	double	JD
	struct ln_lnlat_posn *	position

void
ln_get_ecl_from_rect(rect, posn)
	struct ln_rect_posn *	rect
	struct ln_lnlat_posn *	posn

void
ln_get_ecl_prec(mean_position, JD, position)
	struct ln_lnlat_posn *	mean_position
	double	JD
	struct ln_lnlat_posn *	position

double
ln_get_ell_body_earth_dist(JD, orbit)
	double	JD
	struct ln_ell_orbit *	orbit

double
ln_get_ell_body_elong(JD, orbit)
	double	JD
	struct ln_ell_orbit *	orbit

void
ln_get_ell_body_equ_coords(JD, orbit, posn)
	double	JD
	struct ln_ell_orbit *	orbit
	struct ln_equ_posn *	posn

int
ln_get_ell_body_next_rst(JD, observer, orbit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_ell_orbit *	orbit
	struct ln_rst_time *	rst

int
ln_get_ell_body_next_rst_horizon(JD, observer, orbit, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_ell_orbit *	orbit
	double	horizon
	struct ln_rst_time *	rst

int
ln_get_ell_body_next_rst_horizon_future(JD, observer, orbit, horizon, day_limit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_ell_orbit *	orbit
	double	horizon
	int	day_limit
	struct ln_rst_time *	rst

double
ln_get_ell_body_phase_angle(JD, orbit)
	double	JD
	struct ln_ell_orbit *	orbit

int
ln_get_ell_body_rst(JD, observer, orbit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_ell_orbit *	orbit
	struct ln_rst_time *	rst

int
ln_get_ell_body_rst_horizon(JD, observer, orbit, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_ell_orbit *	orbit
	double	horizon
	struct ln_rst_time *	rst

double
ln_get_ell_body_solar_dist(JD, orbit)
	double	JD
	struct ln_ell_orbit *	orbit

double
ln_get_ell_comet_mag(JD, orbit, g, k)
	double	JD
	struct ln_ell_orbit *	orbit
	double	g
	double	k

void
ln_get_ell_geo_rect_posn(orbit, JD, posn)
	struct ln_ell_orbit *	orbit
	double	JD
	struct ln_rect_posn *	posn

void
ln_get_ell_helio_rect_posn(orbit, JD, posn)
	struct ln_ell_orbit *	orbit
	double	JD
	struct ln_rect_posn *	posn

double
ln_get_ell_last_perihelion(epoch_JD, M, n)
	double	epoch_JD
	double	M
	double	n

double
ln_get_ell_mean_anomaly(n, delta_JD)
	double	n
	double	delta_JD

double
ln_get_ell_mean_motion(a)
	double	a

double
ln_get_ell_orbit_avel(orbit)
	struct ln_ell_orbit *	orbit

double
ln_get_ell_orbit_len(orbit)
	struct ln_ell_orbit *	orbit

double
ln_get_ell_orbit_pvel(orbit)
	struct ln_ell_orbit *	orbit

double
ln_get_ell_orbit_vel(JD, orbit)
	double	JD
	struct ln_ell_orbit *	orbit

double
ln_get_ell_radius_vector(a, e, E)
	double	a
	double	e
	double	E

double
ln_get_ell_smajor_diam(e, q)
	double	e
	double	q

double
ln_get_ell_sminor_diam(e, a)
	double	e
	double	a

double
ln_get_ell_true_anomaly(e, E)
	double	e
	double	E

void
ln_get_equ2000_from_gal(gal, equ)
	struct ln_gal_posn *	gal
	struct ln_equ_posn *	equ

void
ln_get_equ_from_ecl(object, JD, position)
	struct ln_lnlat_posn *	object
	double	JD
	struct ln_equ_posn *	position

void
ln_get_equ_from_gal(gal, equ)
	struct ln_gal_posn *	gal
	struct ln_equ_posn *	equ

void
ln_get_equ_from_hrz(object, observer, JD, position)
	struct ln_hrz_posn *	object
	struct ln_lnlat_posn *	observer
	double	JD
	struct ln_equ_posn *	position

void
ln_get_equ_pm(mean_position, proper_motion, JD, position)
	struct ln_equ_posn *	mean_position
	struct ln_equ_posn *	proper_motion
	double	JD
	struct ln_equ_posn *	position

void
ln_get_equ_pm_epoch(mean_position, proper_motion, JD, epoch_JD, position)
	struct ln_equ_posn *	mean_position
	struct ln_equ_posn *	proper_motion
	double	JD
	double	epoch_JD
	struct ln_equ_posn *	position

void
ln_get_equ_prec(mean_position, JD, position)
	struct ln_equ_posn *	mean_position
	double	JD
	struct ln_equ_posn *	position

void
ln_get_equ_prec2(mean_position, fromJD, toJD, position)
	struct ln_equ_posn *	mean_position
	double	fromJD
	double	toJD
	struct ln_equ_posn *	position

void
ln_get_gal_from_equ(equ, gal)
	struct ln_equ_posn *	equ
	struct ln_gal_posn *	gal

void
ln_get_gal_from_equ2000(equ, gal)
	struct ln_equ_posn *	equ
	struct ln_gal_posn *	gal

double
ln_get_heliocentric_time_diff(JD, object)
	double	JD
	struct ln_equ_posn *	object

void
ln_get_hrz_from_equ(object, observer, JD, position)
	struct ln_equ_posn *	object
	struct ln_lnlat_posn *	observer
	double	JD
	struct ln_hrz_posn *	position

void
ln_get_hrz_from_equ_sidereal_time(object, observer, sidereal, position)
	struct ln_equ_posn *	object
	struct ln_lnlat_posn *	observer
	double	sidereal
	struct ln_hrz_posn *	position

const char *
ln_get_humanr_location(location)
	double	location

double
ln_get_hyp_body_earth_dist(JD, orbit)
	double	JD
	struct ln_hyp_orbit *	orbit

double
ln_get_hyp_body_elong(JD, orbit)
	double	JD
	struct ln_hyp_orbit *	orbit

void
ln_get_hyp_body_equ_coords(JD, orbit, posn)
	double	JD
	struct ln_hyp_orbit *	orbit
	struct ln_equ_posn *	posn

int
ln_get_hyp_body_next_rst(JD, observer, orbit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_hyp_orbit *	orbit
	struct ln_rst_time *	rst

int
ln_get_hyp_body_next_rst_horizon(JD, observer, orbit, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_hyp_orbit *	orbit
	double	horizon
	struct ln_rst_time *	rst

int
ln_get_hyp_body_next_rst_horizon_future(JD, observer, orbit, horizon, day_limit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_hyp_orbit *	orbit
	double	horizon
	int	day_limit
	struct ln_rst_time *	rst

double
ln_get_hyp_body_phase_angle(JD, orbit)
	double	JD
	struct ln_hyp_orbit *	orbit

int
ln_get_hyp_body_rst(JD, observer, orbit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_hyp_orbit *	orbit
	struct ln_rst_time *	rst

int
ln_get_hyp_body_rst_horizon(JD, observer, orbit, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_hyp_orbit *	orbit
	double	horizon
	struct ln_rst_time *	rst

double
ln_get_hyp_body_solar_dist(JD, orbit)
	double	JD
	struct ln_hyp_orbit *	orbit

void
ln_get_hyp_geo_rect_posn(orbit, JD, posn)
	struct ln_hyp_orbit *	orbit
	double	JD
	struct ln_rect_posn *	posn

void
ln_get_hyp_helio_rect_posn(orbit, JD, posn)
	struct ln_hyp_orbit *	orbit
	double	JD
	struct ln_rect_posn *	posn

double
ln_get_hyp_radius_vector(q, e, t)
	double	q
	double	e
	double	t

double
ln_get_hyp_true_anomaly(q, e, t)
	double	q
	double	e
	double	t

double
ln_get_jde(JD)
	double	JD

double
ln_get_julian_day(date)
	struct ln_date *	date

double
ln_get_julian_from_mpc(mpc_date)
	char *	mpc_date

double
ln_get_julian_from_sys()

double
ln_get_julian_from_timet(in_time)
	time_t *	in_time

double
ln_get_julian_local_date(zonedate)
	struct ln_zonedate *	zonedate

double
ln_get_jupiter_disk(JD)
	double	JD

double
ln_get_jupiter_earth_dist(JD)
	double	JD

void
ln_get_jupiter_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

double
ln_get_jupiter_equ_sdiam(JD)
	double	JD

void
ln_get_jupiter_helio_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

double
ln_get_jupiter_magnitude(JD)
	double	JD

double
ln_get_jupiter_phase(JD)
	double	JD

double
ln_get_jupiter_pol_sdiam(JD)
	double	JD

void
ln_get_jupiter_rect_helio(JD, position)
	double	JD
	struct ln_rect_posn *	position

int
ln_get_jupiter_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

double
ln_get_jupiter_solar_dist(JD)
	double	JD

double
ln_get_light_time(dist)
	double	dist

void
ln_get_local_date(JD, zonedate)
	double	JD
	struct ln_zonedate *	zonedate

double
ln_get_lunar_bright_limb(JD)
	double	JD

double
ln_get_lunar_disk(JD)
	double	JD

double
ln_get_lunar_earth_dist(JD)
	double	JD

void
ln_get_lunar_ecl_coords(JD, position, precision)
	double	JD
	struct ln_lnlat_posn *	position
	double	precision

void
ln_get_lunar_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

void
ln_get_lunar_equ_coords_prec(JD, position, precision)
	double	JD
	struct ln_equ_posn *	position
	double	precision

void
ln_get_lunar_geo_posn(JD, moon, precision)
	double	JD
	struct ln_rect_posn *	moon
	double	precision

double
ln_get_lunar_long_asc_node(JD)
	double	JD

double
ln_get_lunar_long_perigee(JD)
	double	JD

double
ln_get_lunar_phase(JD)
	double	JD

int
ln_get_lunar_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

double
ln_get_lunar_sdiam(JD)
	double	JD

double
ln_get_mars_disk(JD)
	double	JD

double
ln_get_mars_earth_dist(JD)
	double	JD

void
ln_get_mars_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

void
ln_get_mars_helio_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

double
ln_get_mars_magnitude(JD)
	double	JD

double
ln_get_mars_phase(JD)
	double	JD

void
ln_get_mars_rect_helio(JD, position)
	double	JD
	struct ln_rect_posn *	position

int
ln_get_mars_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

double
ln_get_mars_sdiam(JD)
	double	JD

double
ln_get_mars_solar_dist(JD)
	double	JD

double
ln_get_mercury_disk(JD)
	double	JD

double
ln_get_mercury_earth_dist(JD)
	double	JD

void
ln_get_mercury_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

void
ln_get_mercury_helio_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

double
ln_get_mercury_magnitude(JD)
	double	JD

double
ln_get_mercury_phase(JD)
	double	JD

void
ln_get_mercury_rect_helio(JD, position)
	double	JD
	struct ln_rect_posn *	position

int
ln_get_mercury_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

double
ln_get_mercury_sdiam(JD)
	double	JD

double
ln_get_mercury_solar_dist(JD)
	double	JD

int
ln_get_motion_body_next_rst_horizon(JD, observer, get_motion_body_coords, orbit, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	get_motion_body_coords_t	get_motion_body_coords
	void *	orbit
	double	horizon
	struct ln_rst_time *	rst

int
ln_get_motion_body_next_rst_horizon_future(JD, observer, get_motion_body_coords, orbit, horizon, day_limit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	get_motion_body_coords_t	get_motion_body_coords
	void *	orbit
	double	horizon
	int	day_limit
	struct ln_rst_time *	rst

int
ln_get_motion_body_rst_horizon(JD, observer, get_motion_body_coords, orbit, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	get_motion_body_coords_t	get_motion_body_coords
	void *	orbit
	double	horizon
	struct ln_rst_time *	rst

double
ln_get_neptune_disk(JD)
	double	JD

double
ln_get_neptune_earth_dist(JD)
	double	JD

void
ln_get_neptune_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

void
ln_get_neptune_helio_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

double
ln_get_neptune_magnitude(JD)
	double	JD

double
ln_get_neptune_phase(JD)
	double	JD

void
ln_get_neptune_rect_helio(JD, position)
	double	JD
	struct ln_rect_posn *	position

int
ln_get_neptune_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

double
ln_get_neptune_sdiam(JD)
	double	JD

double
ln_get_neptune_solar_dist(JD)
	double	JD

void
ln_get_nutation(JD, nutation)
	double	JD
	struct ln_nutation *	nutation

int
ln_get_object_next_rst(JD, observer, object, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_equ_posn *	object
	struct ln_rst_time *	rst

int
ln_get_object_next_rst_horizon(JD, observer, object, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_equ_posn *	object
	double	horizon
	struct ln_rst_time *	rst

int
ln_get_object_rst(JD, observer, object, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_equ_posn *	object
	struct ln_rst_time *	rst

int
ln_get_object_rst_horizon(JD, observer, object, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_equ_posn *	object
	long double	horizon
	struct ln_rst_time *	rst

double
ln_get_par_body_earth_dist(JD, orbit)
	double	JD
	struct ln_par_orbit *	orbit

double
ln_get_par_body_elong(JD, orbit)
	double	JD
	struct ln_par_orbit *	orbit

void
ln_get_par_body_equ_coords(JD, orbit, posn)
	double	JD
	struct ln_par_orbit *	orbit
	struct ln_equ_posn *	posn

int
ln_get_par_body_next_rst(JD, observer, orbit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_par_orbit *	orbit
	struct ln_rst_time *	rst

int
ln_get_par_body_next_rst_horizon(JD, observer, orbit, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_par_orbit *	orbit
	double	horizon
	struct ln_rst_time *	rst

int
ln_get_par_body_next_rst_horizon_future(JD, observer, orbit, horizon, day_limit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_par_orbit *	orbit
	double	horizon
	int	day_limit
	struct ln_rst_time *	rst

double
ln_get_par_body_phase_angle(JD, orbit)
	double	JD
	struct ln_par_orbit *	orbit

int
ln_get_par_body_rst(JD, observer, orbit, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_par_orbit *	orbit
	struct ln_rst_time *	rst

int
ln_get_par_body_rst_horizon(JD, observer, orbit, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_par_orbit *	orbit
	double	horizon
	struct ln_rst_time *	rst

double
ln_get_par_body_solar_dist(JD, orbit)
	double	JD
	struct ln_par_orbit *	orbit

double
ln_get_par_comet_mag(JD, orbit, g, k)
	double	JD
	struct ln_par_orbit *	orbit
	double	g
	double	k

void
ln_get_par_geo_rect_posn(orbit, JD, posn)
	struct ln_par_orbit *	orbit
	double	JD
	struct ln_rect_posn *	posn

void
ln_get_par_helio_rect_posn(orbit, JD, posn)
	struct ln_par_orbit *	orbit
	double	JD
	struct ln_rect_posn *	posn

double
ln_get_par_radius_vector(q, t)
	double	q
	double	t

double
ln_get_par_true_anomaly(q, t)
	double	q
	double	t

void
ln_get_parallax(object, au_distance, observer, height, JD, parallax)
	struct ln_equ_posn *	object
	double	au_distance
	struct ln_lnlat_posn *	observer
	double	height
	double	JD
	struct ln_equ_posn *	parallax

void
ln_get_parallax_ha(object, au_distance, observer, height, H, parallax)
	struct ln_equ_posn *	object
	double	au_distance
	struct ln_lnlat_posn *	observer
	double	height
	double	H
	struct ln_equ_posn *	parallax

double
ln_get_pluto_disk(JD)
	double	JD

double
ln_get_pluto_earth_dist(JD)
	double	JD

void
ln_get_pluto_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

void
ln_get_pluto_helio_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

double
ln_get_pluto_magnitude(JD)
	double	JD

double
ln_get_pluto_phase(JD)
	double	JD

void
ln_get_pluto_rect_helio(JD, position)
	double	JD
	struct ln_rect_posn *	position

int
ln_get_pluto_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

double
ln_get_pluto_sdiam(JD)
	double	JD

double
ln_get_pluto_solar_dist(JD)
	double	JD

double
ln_get_rect_distance(a, b)
	struct ln_rect_posn *	a
	struct ln_rect_posn *	b

void
ln_get_rect_from_helio(object, position)
	struct ln_helio_posn *	object
	struct ln_rect_posn *	position

double
ln_get_refraction_adj(altitude, atm_pres, temp)
	double	altitude
	double	atm_pres
	double	temp

double
ln_get_rel_posn_angle(posn1, posn2)
	struct ln_equ_posn *	posn1
	struct ln_equ_posn *	posn2

double
ln_get_saturn_disk(JD)
	double	JD

double
ln_get_saturn_earth_dist(JD)
	double	JD

void
ln_get_saturn_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

double
ln_get_saturn_equ_sdiam(JD)
	double	JD

void
ln_get_saturn_helio_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

double
ln_get_saturn_magnitude(JD)
	double	JD

double
ln_get_saturn_phase(JD)
	double	JD

double
ln_get_saturn_pol_sdiam(JD)
	double	JD

void
ln_get_saturn_rect_helio(JD, position)
	double	JD
	struct ln_rect_posn *	position

int
ln_get_saturn_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

double
ln_get_saturn_solar_dist(JD)
	double	JD

void
ln_get_solar_ecl_coords(JD, position)
	double	JD
	struct ln_lnlat_posn *	position

void
ln_get_solar_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

void
ln_get_solar_geo_coords(JD, position)
	double	JD
	struct ln_rect_posn *	position

void
ln_get_solar_geom_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

int
ln_get_solar_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

int
ln_get_solar_rst_horizon(JD, observer, horizon, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	double	horizon
	struct ln_rst_time *	rst

double
ln_get_solar_sdiam(JD)
	double	JD

void
ln_get_timet_from_julian(JD, in_time)
	double	JD
	time_t *	in_time

double
ln_get_uranus_disk(JD)
	double	JD

double
ln_get_uranus_earth_dist(JD)
	double	JD

void
ln_get_uranus_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

void
ln_get_uranus_helio_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

double
ln_get_uranus_magnitude(JD)
	double	JD

double
ln_get_uranus_phase(JD)
	double	JD

void
ln_get_uranus_rect_helio(JD, position)
	double	JD
	struct ln_rect_posn *	position

int
ln_get_uranus_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

double
ln_get_uranus_sdiam(JD)
	double	JD

double
ln_get_uranus_solar_dist(JD)
	double	JD

double
ln_get_venus_disk(JD)
	double	JD

double
ln_get_venus_earth_dist(JD)
	double	JD

void
ln_get_venus_equ_coords(JD, position)
	double	JD
	struct ln_equ_posn *	position

void
ln_get_venus_helio_coords(JD, position)
	double	JD
	struct ln_helio_posn *	position

double
ln_get_venus_magnitude(JD)
	double	JD

double
ln_get_venus_phase(JD)
	double	JD

void
ln_get_venus_rect_helio(JD, position)
	double	JD
	struct ln_rect_posn *	position

int
ln_get_venus_rst(JD, observer, rst)
	double	JD
	struct ln_lnlat_posn *	observer
	struct ln_rst_time *	rst

double
ln_get_venus_sdiam(JD)
	double	JD

double
ln_get_venus_solar_dist(JD)
	double	JD

const char *
ln_get_version()

void
ln_hequ_to_equ(hpos, pos)
	struct lnh_equ_posn *	hpos
	struct ln_equ_posn *	pos

void
ln_hhrz_to_hrz(hpos, pos)
	struct lnh_hrz_posn *	hpos
	struct ln_hrz_posn *	pos

void
ln_hlnlat_to_lnlat(hpos, pos)
	struct lnh_lnlat_posn *	hpos
	struct ln_lnlat_posn *	pos

double
ln_hms_to_deg(hms)
	struct ln_hms *	hms

double
ln_hms_to_rad(hms)
	struct ln_hms *	hms

void
ln_hrz_to_hhrz(pos, hpos)
	struct ln_hrz_posn *	pos
	struct lnh_hrz_posn *	hpos

const char *
ln_hrz_to_nswe(pos)
	struct ln_hrz_posn *	pos

double
ln_interpolate3(n, y1, y2, y3)
	double	n
	double	y1
	double	y2
	double	y3

double
ln_interpolate5(n, y1, y2, y3, y4, y5)
	double	n
	double	y1
	double	y2
	double	y3
	double	y4
	double	y5

void
ln_lnlat_to_hlnlat(pos, hpos)
	struct ln_lnlat_posn *	pos
	struct lnh_lnlat_posn *	hpos

double
ln_rad_to_deg(radians)
	double	radians

void
ln_rad_to_dms(radians, dms)
	double	radians
	struct ln_dms *	dms

void
ln_rad_to_hms(radians, hms)
	double	radians
	struct ln_hms *	hms

double
ln_range_degrees(angle)
	double	angle

double
ln_range_radians(angle)
	double	angle

double
ln_range_radians2(angle)
	double	angle

double
ln_solve_barker(q, t)
	double	q
	double	t

double
ln_solve_hyp_barker(Q1, G, t)
	double	Q1
	double	G
	double	t

double
ln_solve_kepler(e, M)
	double	e
	double	M

void
ln_vsop87_to_fk5(position, JD)
	struct ln_helio_posn *	position
	double	JD

void
ln_zonedate_to_date(zonedate, date)
	struct ln_zonedate *	zonedate
	struct ln_date *	date

struct tm *
localtime(__timer)
	__const time_t *	__timer

struct tm *
localtime_r(__timer, __tp)
	__const time_t * __restrict	__timer
	struct tm * __restrict	__tp

time_t
mktime(__tp)
	struct tm *	__tp

int
nanosleep(__requested_time, __remaining)
	__const struct timespec *	__requested_time
	struct timespec *	__remaining

double
round(x)
	double	x

int
stime(__when)
	__const time_t *	__when

size_t
strftime(__s, __maxsize, __format, __tp)
	char * __restrict	__s
	size_t	__maxsize
	__const char * __restrict	__format
	__const struct tm * __restrict	__tp

size_t
strftime_l(__s, __maxsize, __format, __tp, __loc)
	char * __restrict	__s
	size_t	__maxsize
	__const char * __restrict	__format
	__const struct tm * __restrict	__tp
	__locale_t	__loc

char *
strptime(__s, __fmt, __tp)
	__const char * __restrict	__s
	__const char * __restrict	__fmt
	struct tm *	__tp

char *
strptime_l(__s, __fmt, __tp, __loc)
	__const char * __restrict	__s
	__const char * __restrict	__fmt
	struct tm *	__tp
	__locale_t	__loc

time_t
time(__timer)
	time_t *	__timer

time_t
timegm(__tp)
	struct tm *	__tp

time_t
timelocal(__tp)
	struct tm *	__tp

int
timer_create(__clock_id, __evp, __timerid)
	clockid_t	__clock_id
	struct sigevent * __restrict	__evp
	timer_t * __restrict	__timerid

int
timer_delete(__timerid)
	timer_t	__timerid

int
timer_getoverrun(__timerid)
	timer_t	__timerid

int
timer_gettime(__timerid, __value)
	timer_t	__timerid
	struct itimerspec *	__value

int
timer_settime(__timerid, __flags, __value, __ovalue)
	timer_t	__timerid
	int	__flags
	__const struct itimerspec * __restrict	__value
	struct itimerspec * __restrict	__ovalue

void
tzset()
*/



/*double
ln_get_ell_body_earth_dist(JD, orbit)
	double	JD
	struct ln_ell_orbit *	orbit
*/

MODULE = Astro::Nova		PACKAGE = Astro::Nova	PREFIX=ln_

INCLUDE: XS/Structs.xs

INCLUDE: XS/Abberation.xs

#### airmass.h
double
ln_get_airmass(alt, airmass_scale)
  double alt
  double airmass_scale

INCLUDE: XS/AngularSeparation.xs

INCLUDE: XS/ApparentPosition.xs

INCLUDE: XS/Asteroid.xs

INCLUDE: XS/Comet.xs

INCLUDE: XS/DynamicalTime.xs

INCLUDE: XS/Earth.xs

INCLUDE: XS/EllipticMotion.xs

INCLUDE: XS/Sidereal.xs

