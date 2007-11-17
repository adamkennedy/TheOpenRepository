use inc::Module::Install;

name          ( 'Template-Plugin-Dumpvar'           );
abstract      ( 'Dump template data in the same style as the debugger' );
author        ( 'Adam Kennedy<cpan@ali.as>'         );
version_from  ( 'lib/Template/Plugin/Dumpvar.pm'    );
license       ( 'perl'                              );

requires      ( 'perl'                 => '5.005'   );
requires      ( 'Template'             => '2.10'    );
requires      ( 'Devel::Dumpvar'       => '0.02'    );

build_requires( 'Test::More'           => '0.47'    );
build_requires( 'File::Spec'           => '0.82'    );

auto_install();

&WriteAll;
