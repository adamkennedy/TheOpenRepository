use inc::Module::Install;

name           ( 'PITA-Report'                             );
abstract_from  ( 'lib/PITA/Report.pm'                      );
author         ( 'Adam Kennedy <adam@phase-n.com>'         );
version_from   ( 'lib/PITA/Report.pm'                      );
license        ( 'perl'                                    );
requires       ( 'perl'                    => '5.005'      );
requires       ( 'Carp'                    => 0            );
requires       ( 'Params::Util'            => '0.07'       );
requires       ( 'IO::Handle'              => 0            );
requires       ( 'IO::File'                => 0            );
requires       ( 'IO::Seekable'            => 0            );
requires       ( 'File::Flock'             => '101.060501' );
requires       ( 'XML::SAX::ParserFactory' => '0.13'       );
requires       ( 'XML::Validator::Schema'  => '1.08'       );
build_requires ( 'File::Spec'              => '0.80'       );
build_requires ( 'Test::More'              => '0.47'       );
auto_install   (                                           );

&WriteAll;
