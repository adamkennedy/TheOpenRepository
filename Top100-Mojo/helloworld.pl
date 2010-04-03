#!/usr/bin/perl

use strict;
use warnings;
use Mojolicious::Lite;

get '/' => 'index';

shagadelic;

__DATA__

@@ index.html.ep
<html>
 <body>
  Hello World!
 </body>
</html>
