What is Strawberry Perl Portable?
---------------------------------
* 'Perl' is a programming language suitable for writing simple scripts as well
  as complex applications. See http://perldoc.perl.org/perlintro.html

* 'Strawberry Perl' is a perl enviroment for Microsoft Windows containing all
  you need to run and develop perl applications. It is designed to be as close
  as possible to perl enviroment on UNIX systems. See http://strawberryperl.com/

* 'Strawberry Perl Portable' is Strawberry Perl that you do not need to install,
  you do not need admin privileges, you just extract provided ZIP on your disk.
  
How to use Strawberry Perl Portable?
------------------------------------

* Extract strawberry portable ZIP into e.g. c:\myperl\ 
  Note: choose directory name without spaces

* Launch c:\myperl\portableshell.bat - it should open a command prompt window

* In the command prompt window you can:

  1. run any perl script by launching
  
     c:\> perl c:\path\to\script.pl

  2. install additional perl modules (libraries) from http://www.cpan.org/ by

     c:\> cpan Module::Name
  
  3. run other tools included in strawberry like: perldoc, gcc, dmake ...

* You can add c:\myperl\perl\bin and c:\myperl\c\bin into your PATH enviroment
  variable if you want to use it not only from portableshell.bat