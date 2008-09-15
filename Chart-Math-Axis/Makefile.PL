use inc::Module::Install 0.77;

all_from      'lib/Chart/Math/Axis.pm';
requires      'Math::BigInt'   => '1.70';
requires      'Math::BigFloat' => '1.44'; # Needs bdiv
requires      'Storable'       => '2.12';
requires      'Params::Util'   => '0.15';
test_requires 'Test::More'     => '0.42';

WriteAll;
