use inc::Module::Install;

name          ( 'Apache2-PPI-HTML'           );
abstract      ( 'mod_perl2 interface to PPI::HTML syntax highlighter' );
author        ( 'Adam Kennedy <cpan@ali.as>' );
version_from  ( 'lib/Apache2/PPI/HTML.pm'    );
license       ( 'perl'                       );
requires      ( 'perl'            => '5.005' );
requires      ( 'CGI'             => '3.10'  );
requires      ( 'mod_perl'        => '2.0'   );
requires      ( 'PPI'             => '0.994' );
requires      ( 'PPI::HTML'       => '0.05'  );
build_requires( 'Test::More'      => '0.47'  );
build_requires( 'File::Spec'      => '0.80'  );

auto_install();

&WriteAll;
