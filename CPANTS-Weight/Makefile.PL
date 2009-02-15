use inc::Module::Install 0.79;

all_from       'lib/CPANTS/Weight.pm';
requires       'File::Spec'                         => winlike() ? '3.2701' : '0.80';
requires       'File::HomeDir'                      => '0.82';
requires       'Algorithm::Dependency'              => '1.108';
requires       'Algorithm::Dependency::Source::DBI' => '0.05';
requires       'ORLite'                             => '1.20';
requires       'ORDB::CPANTS'                       => '0.03';
test_requires  'Test::More'                         => '0.42';
test_requires  'Test::Script'                       => '1.03';
install_script 'cpants100' if -d 'script';

WriteAll;
