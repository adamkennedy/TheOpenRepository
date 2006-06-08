use inc::Module::Install;

name          ( 'CSS-Tiny'                  );
abstract      ( 'Read/Write .css stylesheets with as little code as possible' );
author        ( 'Adam Kennedy<cpan@ali.as>' );
version_from  ( 'lib/CSS/Tiny.pm'           );
license       ( 'perl'                      );
requires      ( 'perl'           => '5.005' );
build_requires( 'File::Spec'     => '0.80'  );
build_requires( 'Test::More'     => '0.47'  );
recommends    ( 'Clone'          => '0.13'  );
auto_install  (                             );

&WriteAll;
