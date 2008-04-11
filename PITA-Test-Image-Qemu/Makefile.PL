use strict;
use inc::Module::Install;

name           'PITA-Test-Image-Qemu';
all_from       'lib/PITA/Test/Image/Qemu.pm';
requires       'File::ShareDir' => '0.03';
test_requires 'File::Spec'     => '0.80';
test_requires 'Test::More'     => '0.47';
install_share;

WriteAll;
