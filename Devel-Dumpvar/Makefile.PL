use inc::Module::Install;

name          'Devel-Dumpvar';
all_from      'lib/Devel/Dumpvar.pm',
requires      'Scalar::Util' => '1.17';
test_requires 'File::Spec'   => '0.80';
test_requires 'Test::More'   => '0.42';

WriteAll;
