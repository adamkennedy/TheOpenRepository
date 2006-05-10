use inc::Module::Install;

name           'SMS-Send';
all_from       'lib/SMS/Send.pm';
requires       'Carp'              => 0;
requires       'Params::Util'      => '0.02';
requires       'Class::Adapter'    => '1.00';
requires       'Module::Pluggable' => '2.5';
build_requires 'File::Spec'        => '0.80';
build_requires 'Test::More'        => '0.47';

WriteAll;
