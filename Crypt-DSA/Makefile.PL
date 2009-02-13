# $Id: Makefile.PL 1938 2006-05-03 06:20:36Z btrott $

use inc::Module::Install;

name     'Crypt-DSA';
all_from 'lib/Crypt/DSA.pm';
requires 'Digest::SHA1' => 0;
requires 'Math::BigInt' => '1.60';
requires 'Data::Random' => '0.05' if $^O eq 'MSWin32';

features(
    'Read/write PEM-encoded files' => [
        -default => 0,
        recommends('Convert::PEM' => '0.07'),
    ],

    'Read/write SSH2 keyfiles' => [
        -default => 0,
        recommends('Data::Buffer' => '0.01'),
    ],
);

sign(1);
auto_install;
WriteAll;
