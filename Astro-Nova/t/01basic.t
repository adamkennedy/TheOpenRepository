use strict;
use warnings;
use Test::More tests => 10;
use Astro::Nova;

pass();
ok(Astro::Nova::get_apparent_sidereal_time(0) > 1., "apparent sidereal time is there");
my $date = Astro::Nova::Date->new();
isa_ok($date, "Astro::Nova::Date");
is($date->get_years, 0);

my $hequ_pos = Astro::Nova::HEquPosn->new();
isa_ok($hequ_pos, "Astro::Nova::HEquPosn");
my $hms = $hequ_pos->get_ra;
isa_ok($hms, "Astro::Nova::HMS");
is($hms->get_hours, 0);
$hms->set_hours(2);
is($hms->get_hours, 2);
is($hequ_pos->get_ra->get_hours, 0);
$hequ_pos->set_ra($hms);
is($hequ_pos->get_ra->get_hours, 2);



