use inc::Module::Install 0.75;

all_from      'lib/ORLite/Mirror.pm';
requires      'File::Spec'       => winlike() ? '3.2701' : '0.80';
requires      'File::Path'       => '2.04';
requires      'File::HomeDir'    => '0.69';
requires      'Class::Inspector' => '1.20';
requires      'URI'              => '1.35';
requires      'LWP'              => '5.806';
requires      'ORLite'           => '0.07';
test_requires 'Test::More'       => '0.47';

WriteAll;
