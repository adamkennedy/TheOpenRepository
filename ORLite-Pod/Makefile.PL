use inc::Module::Install 0.77;

all_from       'lib/ORLite/Pod.pm';
requires       'File::Spec'       => winlike() ? '3.2701' : '0.80';
requires       'File::Path'       => '2.07';
requires       'File::Basename'   => 0;
requires       'Getopt::Long'     => 0;
requires       'Params::Util'     => '0.33';
requires       'Class::Inspector' => '1.23';
requires       'ORLite'           => '1.17';
requires       'Template'         => '2.20';
test_requires  'Test::More'       => '0.47';
test_requires  'Test::Script'     => '1.03';
install_script 'orlite2pod';

WriteAll;
