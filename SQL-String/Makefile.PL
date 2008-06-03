use inc::Module::Install;

name          ( 'SQL-String'           );
abstract      ( 'An object representation of a chunk of SQL' );
author        ( 'Adam Kennedy<cpan@ali.as>'         );
version_from  ( 'lib/SQL/String.pm'    );
license       ( 'perl'                              );

requires      ( 'perl'                 => '5.005'   );

build_requires( 'Test::More'           => '0.47'    );
build_requires( 'File::Spec'           => '0.82'    );

auto_install();

&WriteAll;
