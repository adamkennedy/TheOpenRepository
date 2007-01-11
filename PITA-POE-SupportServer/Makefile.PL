use inc::Module::Install;
name 'PITA-POE-SupportServer';
author 'Chris Williams <chris@bingosnet.co.uk>';
license 'perl';
version_from 'lib/PITA/POE/SupportServer.pm';
requires 'Carp' => 0;
requires 'POE'  => 0.38;
requires 'PITA::Test::Image::Qemu' => 0.02;
WriteAll();
