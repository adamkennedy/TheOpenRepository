use inc::Module::Install;

name           'Number-WithError';
all_from       'lib/Number/WithError.pm';
requires       'Params::Util'            => '0.10';
requires       'prefork'                 => '1.00';
requires       'Math::BigFloat'          => '0';

build_requires 'Test::More'              => '0.47';
build_requires 'Test::LectroTest'        => '0';

WriteAll();
