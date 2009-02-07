use inc::Module::Install 0.79;

all_from      'lib/CPANTS/Weight.pm';
requires      'File::Spec'                         => winlike() ? '3.2701' : '0.80';
requires      'File::HomeDir'                      => '0.82';
requires      'Algorithm::Dependency'              => '1.106';
requires      'Algorithm::Dependency::Source::DBI' => '0.05';
requires      'ORLite'                             => '1.19';
requires      'ORDB::CPANTS'                       => '0.02';
test_requires 'Test::More'                         => '0.42';

WriteAll;
