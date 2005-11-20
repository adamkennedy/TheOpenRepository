use inc::Module::Install;

name         ( 'Task'                       );
abstract     ( 'The successor to Bundle:: for installing sets of modules' );
author       ( 'Adam Kennedy <cpan@ali.as>' );
version_from ( 'lib/Task.pm'                );
auto_install (                              );

# All the things we need for Task (err... nothing)
requires     ( 'perl'            => '5.005' );

&WriteAll;
