use inc::Module::Install;

name           ( 'VCS-CSync'                  );
abstract       ( 'Synchronize and publish code/content from a repository' );
author         ( 'Adam Kennedy <cpan@ali.as>' );
version_from   ( 'lib/VCS/CSync.pm'           );
license        ( 'perl'                       );
requires       ( 'perl'            => '5.005' );
requires       ( 'Params::Util'    => '0.05'  );
requires       ( 'Config::Tiny'    => '2.01'  );
requires       ( 'File::Flat'      => '0.93'  );
requires       ( 'Getopt::Long'    => 0       );
requires       ( 'File::Spec'      => '0.82'  );
build_requires ( 'Test::More'      => '0.47'  );
can_run        ( 'cvs'                        );
can_run        ( 'chmod'                      );
can_run        ( 'cd'                         );
can_run        ( 'export'                     );
install_script ( 'bin/csync'                  );

auto_install();

&WriteAll;
