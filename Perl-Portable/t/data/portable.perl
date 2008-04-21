---
class: Perl::Portable
c_bin: c/bin
c_lib: c/lib
c_include: c/include
cpan: cpan
config:
  archlib: $prefix/lib
  archlibexp: $archlib
  bin: $prefix/bin
  binexp: $bin
  incpath: c/include
  installarchlib: $prefix/lib
  installbin: $prefix/bin
  installbin: $bin
  installhtml1dir: ''
  installhtml3dir: ''
  installhtmldir: $prefix\html
  installhtmlhelpdir: $prefix\htmlhelp
  installman1dir: $prefix\man\man1
  installman3dir: $prefix\man\man3
  installprefix: $prefix
  installprefixexp: $prefix
  installprivlib: $prefix\lib
  installscript: $bin
  installsitearch: $prefix\site\lib
  installsitebin: $bin
  installsitehtml1dir: ''
  installsitehtml3dir: ''
  installsitelib: $prefix\site\lib
  installsiteman1dir: ''
  installsiteman3dir: ''
  installsitescript: ''
  installstyle: lib
  installusrbinperl: ~
  installvendorarch: ''
  installvendorbin: ''
  installvendorhtml1dir: ''
  installvendorhtml3dir: ''
  installvendorlib: ''
  installvendorman1dir: ''
  installvendorman3dir: ''
  installvendorscript: ''
  lddlflags: '-mdll -s -L"$archlib\\CORE" -L"$libpth"'
  ldflags: '-s -L"$archlib\\CORE" -L"$libpth"'
  libpth: c/lib
  perlpath: perl/bin/perl.exe
  prefix: perl
  privlibexp: perl/lib
  scriptdir: perl/bin
  sitearchexp: perl/site/lib
  sitelibexp: perl/site/lib
  man1dir: $prefix/man/man1
  man1direxp: $prefix/man/man1
  man3dir: $prefix/man/man3
  man3direxp: $prefix/man/man3
  perlpath: $bin/perl.exe

ENV:
  PATH:
    - c/bin
    - perl/bin
  LIB:
    - c/lib
    - perl/bin
  INCLUDE:
    - c/include
    - perl/lib/CORE
