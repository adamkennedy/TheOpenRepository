#!/usr/bin/perl -w
use strict;
use OpenGL qw/ :all /;

# print a descrition of the current OpenGL connection

glutInit();
glutCreateWindow('');

my $version = glGetString(GL_VERSION);
printf "OpenGL version %s\n", defined $version?$version:'?';

my $vendor = glGetString(GL_VENDOR);
printf "Vendor: %s\n", defined $vendor?$vendor:'?';

my $renderer = glGetString(GL_RENDERER);
printf "Renderer: %s\n", defined $renderer?$renderer:'?';

my $extensions = glGetString(GL_EXTENSIONS);
print "Supported extensions:\n* ";
if (defined $extensions) {
  local $,="\n* ";
  print split ' ',$extensions;
}
__END__