use inc::Module::Install;

name           ( 'PITA-Report'                     );
abstract_from  ( 'lib/PITA/Report.pm'              );
author         ( 'Adam Kennedy <adam@phase-n.com>' );
version_from   ( 'lib/PITA/Report.pm'              );
license        ( 'perl'                            );
requires       ( 'perl'                 => '5.005' );
requires       ( 'Carp'                 => 0       );
build_requires ( 'File::Spec'           => '0.80'  );
build_requires ( 'Test::More'           => '0.47'  );
auto_install   (                                   );

&WriteAll;
