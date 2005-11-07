use inc::Module::Install;

name           ( 'CPAN-Metrics'                   );
abstract       ( 'Create and maintain a Perl::Metrics database for all of CPAN' );
author         ( 'Adam Kennedy <cpan@ali.as>'     );
version_from   ( 'lib/CPAN/Metrics.pm'            );
license        ( 'perl'                           );
requires       ( 'perl'                => '5.005' );
requires       ( 'Carp'                => 0       );
requires       ( 'File::HomeDir'       => '0.06'  );
requires       ( 'Perl::Metrics'       => '0.03'  );
requires       ( 'CPAN::Mini::Extract' => '0.10'  );
install_script ( 'bin/cpanmetrics'                );
auto_install   (                                  );

&WriteAll;
