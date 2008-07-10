use inc::Module::Install 0.76;

all_from       'lib/File/LocalizeNewlines.pm';
requires       'FileHandle'       => 0;
requires       'Getopt::Long'     => 0;
requires       'File::Spec'       => '0.80';
requires       'File::Remove'     => '1.42';
requires       'File::Slurp'      => '9999.04';
requires       'File::Find::Rule' => '0.20';
requires       'Class::Default'   => '1.0';
requires       'Params::Util'     => '0.10';
test_requires  'Test::More'       => '0.42';
test_requires  'Test::Script'     => '1.02';
install_script 'localizenewlines';

WriteAll;
