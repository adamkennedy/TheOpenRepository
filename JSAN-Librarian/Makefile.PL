use inc::Module::Install;

name           ( 'JSAN-Librarian'                   );
abstract       ( 'JavaScript::Librarian adapter for installed JSAN libs' );
author         ( 'Adam Kennedy <cpan@ali.as>'       );
version_from   ( 'lib/JSAN/Librarian.pm'            );
license        ( 'perl'                             );
requires       ( 'perl'                  => '5.005' );
requires       ( 'File::Spec'            => '0.80'  );
requires       ( 'File::Path'            => '1.06'  );
requires       ( 'Config::Tiny'          => '2.00'  );
requires       ( 'File::Find::Rule'      => '0.20'  );
requires       ( 'JSAN::Parse::FileDeps' => '0.02'  );
requires       ( 'JavaScript::Librarian' => '0.03'  );
build_requires ( 'URI'                   => '1.33'  );
build_requires ( 'Test::More'            => '0.47'  );

auto_install();

&WriteAll;
