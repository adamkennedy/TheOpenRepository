use inc::Module::Install;

name           'Email-Send-Test';
all_from       'lib/Email/Send/Test.pm';
requires       'Email::Send' => '2.00';
build_requires 'Test::More'  => '0.47';
build_requires 'File::Spec'  => '0.80';
auto_install;

WriteAll;
