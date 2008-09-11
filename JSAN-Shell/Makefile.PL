use inc::Module::Install;

all_from       'lib/JSAN/Shell.pm';
requires       'Term::ReadLine'       => '1.01';
requires       'Term::ReadLine::Perl' => '1.0302';
requires       'Getopt::Long'         => '2.34';
requires       'File::HomeDir'        => '0.63';
requires       'File::ShareDir'       => '0.05';
requires       'File::UserConfig'     => 0;
requires       'LWP::Online'          => '0.02';
requires       'Mirror::JSON'         => '0.01';
requires       'JSAN::Client'         => '0.16';
test_requires  'File::Spec'           => '0.80';
test_requires  'Test::More'           => '0.47';
test_requires  'Test::Script'         => 0;
install_script 'jsan2';
install_share;

WriteAll;
