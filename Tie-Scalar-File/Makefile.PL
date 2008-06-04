use inc::Module::Install 0.75;

all_from      'lib/Tie/Scalar/File.pm';
requires      'File::Spec'  => '0.80';
requires      'Tie::Scalar' => 0;
test_requires 'Test::More'  => '0.42';

WriteAll;
