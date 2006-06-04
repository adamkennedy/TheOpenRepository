use inc::Module::Install;

name           ( 'Perl-Metrics'                  );
abstract       ( 'The Perl Code Metrics System'  );
author         ( 'Adam Kennedy <cpan@ali.as>'    );
version_from   ( 'lib/Perl/Metrics.pm'           );
license        ( 'perl'                          );
requires       ( 'perl'              => '5.005'  );
requires       ( 'Carp'              => 0        );
requires       ( 'List::Util'        => '1.15'   );
requires       ( 'Class::Inspector'  => '1.12'   );
requires       ( 'Params::Util'      => '0.06'   );
requires       ( 'File::Find::Rule'  => '0.20'   );
requires       ( 'Module::Pluggable' => '2.2'    );
requires       ( 'DBI'               => '1.143'  );
requires       ( 'DBD::SQLite'       => '1.08'   );
requires       ( 'Class::DBI'        => '3.0.9'  );
requires       ( 'PPI'               => '1.103'  );
build_requires ( 'Test::More'        => '0.47'   );
build_requires ( 'File::Spec'        => '0.80'   );
no_index       ( 'directory'         => 't.data' );

&WriteAll;
