package Macropod::Signature;
use strict;
use warnings;
use Carp qw( confess );

use Digest::MD5;

sub local_digest {

}

sub digest {
	my $class = shift;
	my $data = shift;
	my $md5 = Digest::MD5->new;
	$md5->add($data);
	return $md5->hexdigest; 
}

sub digest_file {
	my $class = shift;
	my $file = shift;
	open ( my $fh , '<' , $file ) or confess "Unable to read '$file'";
	return Digest::MD5->new()->addfile($fh)->hexdigest;
}

1;

