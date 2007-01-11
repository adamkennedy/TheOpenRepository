use inc::Module::Install;

name           'PITA';
all_from       'lib/PITA.pm';
requires       'Carp'             => 0;
requires       'version'          => '0.50';
requires       'File::Spec'       => '0.80';
requires       'File::Basename'   => 0;
requires       'File::Temp'       => 0;
requires       'File::Path'       => 0;
requires       'File::Copy'       => 0;
requires       'File::Flock'      => 0;
requires       'File::Remove'     => '0.22';
requires       'Storable'         => 0;
requires       'File::Find::Rule' => 0;
requires       'Data::GUID'       => '0.04';
requires       'Archive::Extract' => '0.07';
requires       'URI'              => 0;
requires       'HTTP::Daemon'     => 0;
requires       'LWP'              => '5.69';
requires       'Params::Util'     => '0.10';
requires       'Process'          => '0.16';
requires       'PITA::XML'        => '0.29';
requires       'PITA::Scheme'     => '0.29';
requires       'PITA::Image'      => '0.29';
build_requires 'Test::More'       => '0.47';

auto_install;
WriteAll;
