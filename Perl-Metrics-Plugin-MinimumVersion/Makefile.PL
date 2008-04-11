use inc::Module::Install;

name           ( 'Perl-Metrics-Plugin-MinimumVersion' );
author         ( 'Adam Kennedy <cpan@ali.as>'         );
abstract       ( 'Perl::Metrics plugin for Perl::MinimumVersion' );
version_from   ( 'lib/Perl/Metrics/Plugin/MinimumVersion.pm'     );
license        ( 'perl'                               );
requires       ( 'perl'                    => '5.005' );
requires       ( 'Carp'                    => 0       );
# Version 0.48 gets rid of the XS bugs at least
# We need a newer version to deal with the qv() bug
requires       ( 'version'                 => '0.48'  );
requires       ( 'Perl::Metrics'           => '0.03'  );
requires       ( 'Perl::MinimumVersion'    => '0.10'  );
test_requires ( 'Test::More'              => '0.47'  );
test_requires ( 'File::Spec'              => '0.80'  );

&WriteAll;
