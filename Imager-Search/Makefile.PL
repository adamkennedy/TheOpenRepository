use inc::Module::Install 0.77;

all_from      'lib/Imager/Search.pm';
requires      'IO::File'            => 0;
requires      'Params::Util'        => '0.33';
requires      'Object::Tiny'        => '1.06';
requires      'File::Slurp'         => '9999.12';
requires      'Imager'              => '0.65';
requires      'Imager::Screenshot'  => '0.007';
test_requires 'Test::More'          => '0.42';
test_requires 'Test::File::Cleaner' => '0.03';

WriteAll;
