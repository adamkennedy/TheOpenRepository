use inc::Module::Install 0.78;

all_from      'lib/Alien/BatToExeConverter.pm';
requires      'File::Which'    => '0.05';
requires      'File::ShareDir' => '1.00';
test_requires 'Test::More'     => '0.47';
install_share;

WriteAll;
