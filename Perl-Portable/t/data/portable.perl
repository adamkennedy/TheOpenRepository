---
class: Perl::Portable
c_bin: c/bin
c_lib: c/lib
c_include: c/include
perl_bin: perl/bin
perl_lib: perl/lib
perl_sitelib: perl/site/lib
cpan: cpan
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
