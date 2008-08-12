use inc::Module::Install 0.77;

all_from       'lib/Perl/Shell.pm';
requires       'Params::Util'   => '0.25';
requires       'Term::ReadLine' => 0;
requires       'PPI'            => '1.200';
build_requires 'Test::More'     => '0.42';
build_requires 'Test::Script'   => '1.03';
install_script 'perlthon';

WriteAll;
