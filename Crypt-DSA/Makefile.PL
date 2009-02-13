use inc::Module::Install 0.79;

all_from      'lib/Crypt/DSA.pm';
requires      'IPC::Open3'   => 0;
requires      'File::Spec'   => 0;
requires      'Digest::SHA1' => 0;
requires      'MIME::Base64' => 0;
requires      'File::Which'  => '0.05';
requires      'Math::BigInt' => '1.60';
requires      'Data::Random' => '0.05' if $^O eq 'MSWin32';
requires      'Data::Buffer' => '0.01';
test_requires 'Test'         => 0;
test_requires 'Test::More'   => '0.42';

WriteAll;
