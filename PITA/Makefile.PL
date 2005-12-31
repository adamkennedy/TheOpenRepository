use inc::Module::Install;

name           'PITA';
all_from       'lib/PITA.pm';
requires       'Carp'          => 0;
requires       'File::Flock'   => '101.060501';
requires       'HTTP::Daemon'  => 0;
requires       'HTTP::Status'  => 0;
requires       'HTTP::Request' => 0;
requires       'URI'           => 0;
requires       'Params::Util'  => '0.07';
build_requires 'File::Spec'    => '0.80';
build_requires 'File::Remove'  => '0.22';
build_requires 'Test::More'    => '0.47';

auto_install;
WriteAll;
