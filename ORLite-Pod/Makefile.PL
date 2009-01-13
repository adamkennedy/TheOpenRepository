use inc::Module::Install 0.77;

all_from      'lib/ORLite/Pod.pm';
requires      'File::Spec'   => winlike() ? '3.2701' : '0.80';
requires      'Params::Util' => '0.33';
requires      'ORLite'       => '1.17';
test_requires 'Test::More'   => '0.47';

WriteAll;
