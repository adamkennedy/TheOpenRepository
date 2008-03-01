#!/usr/bin/perl

use inc::Module::Install;

name           ('Data-Vitals');
abstract       ('The Perl "Vital Statistics" Library');
author         ('Adam Kennedy<cpan@ali.as>');
version_from   ('lib/Data/Vitals.pm');
license        ('perl');

requires       ('perl'            => '5.005');

build_requires ('Test::More'      => '0.47' );
build_requires ('Test::ClassAPI'  => '1.02' );
build_requires ('File::Spec'      => '0.82' );

auto_install();

&WriteAll;
