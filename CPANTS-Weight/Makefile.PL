use inc::Module::Install 0.81;

all_from       'lib/CPANTS/Weight.pm';
requires_from  'lib/CPANTS/Weight.pm';
requires       'File::Spec'      => winlike() ? '3.2701' : '0.80';
requires       'ORLite::Mirror'  => '1.12';
test_requires  'Test::More'      => '0.42';
test_requires  'Test::Script'    => '1.03';
install_script 'cpants-weight';
install_share;

WriteAll;
