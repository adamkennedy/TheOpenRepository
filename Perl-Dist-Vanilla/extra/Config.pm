
# This is CPAN.pm's systemwide configuration file. This file provides
# defaults for users, and the values can be changed in a per-user
# configuration file. The user-config file is being looked for as
# ~/.cpan/CPAN/MyConfig.pm.

$CPAN::Config = {
  'cpan_home' => File::Spec->catdir( File::Spec->tmpdir, 'cpan' ),
  'make' => q[dmake.EXE],
  'urllist' => [ q[ftp://ftp.perl.org/pub/CPAN/] ],
  'prerequisites_policy' => q[follow],
  'make_install_arg' => q[UNINST=1],
  'ftp' => q[ ],
  'gpg' => q[ ],
  'gzip' => q[ ],
  'lynx' => q[ ],
  'ncftp' => q[ ],
  'ncftpget' => q[ ],
  'tar' => q[ ],
  'unzip' => q[ ],
  'wget' => q[ ],
};
1;
__END__
