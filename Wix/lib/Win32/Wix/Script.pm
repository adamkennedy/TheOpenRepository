package Win32::Wix::Script;

# Top level package representing a single "wxs" XML file,
# with a single product inside it.

use strict;
use Carp             'croak';
use XML::Generator   ();
use Params::Util     '_INSTANCE';
use File::Find::Rule ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use constant XMLNS => 'http://schemas.microsoft.com/wix/2003/01/wi';

use Object::Tiny qw{
	product_id
	product_name
	product_language
	product_version
	product_manufacturer
	package_id
	package_description
	package_comments
	package_manufacturer
	targetdir
	installdir
	xml
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params and apply defaults
	unless ( $self->product_id ) {
		$self->{product_id} = '12345678-1234-1234-1234-123456789012';
	}
	unless ( $self->product_name ) {
		croak('Did not provide the product_name param');
	}
	unless ( $self->product_language ) {
		$self->{product_language} = '1033';
	}
	unless ( $self->product_version ) {
		croak('Did not provide the product_version param');
	}
	unless ( $self->product_manufacturer ) {
		croak('Did not provide the product_manufacturer param');
	}
	unless ( $self->package_id ) {
		$self->{package_id} = '12345678-1234-1234-1234-123456789012';
	}
	unless ( $self->package_description ) {
		croak('Did not provide the package_description param');
	}
	unless ( $self->package_comments ) {
		croak('Did not provide the package_comments param');
	}
	unless ( $self->package_manufacturer ) {
		$self->{package_manufacturer} = $self->product_manufacturer;
	}
	unless ( $self->targetdir ) {
		croak('Did not provide the targetdir param');
	}
	unless ( -d $self->targetdir ) {
		croak('The targetdir directory does not exist');
	}
	if ( defined $self->installdir ) {
		unless ( -d $self->installdir ) {
			croak('The installdir directory does not exist');
		}
		unless ( File::Spec->file_name_is_absolute($self->installdir) ) {
			croak('The installdir param must be an absolute path');
		}
	}
	unless ( $self->installdir ) {
		croak('You did not provide an installdir');
	}

	# Create the XML generator
	unless ( $self->xml ) {
		$self->{xml} = XML::Generator->new(
			escape      => 'always',
			conformance => 'strict',
			pretty      => 2,
			namespace   => [ XMLNS ],
		) or die("Failed to create default XML::Generator");
	}
	unless ( _INSTANCE($self->xml, 'XML::Generator') ) {
		croak('The xml param is not an XML::Generator object');
	}

	# Initialize Data Storage
	$self->{properties} = {};
	
	return $self;
}





#####################################################################
# Handle Property Objects

sub property {
	my $self  = shift;
	my $id    = shift;
	my $value = shift;
	if ( $self->{properties}->{$id} ) {
		croak("Property '$id' already exists");
	}

	# Add the property and return it as a convenience
	$self->{properties}->{$id} = Win32::Wix::Property->new(
		id    => $id,
		value => $value,
	);
}

sub properties {
	my $self = shift;
	my $prop = $self->{properties};
	map { $prop->{$_} } sort keys %$prop;
}





#####################################################################
# Transform to XML

sub as_xml {
	my $self = shift;
	my $X    = $self->xml;

	# Get the product XML document
	my $product = $self->xml_product( $self );

	# Wrap in the standard stuff and return
	my $string = $X->xml( $X->Wix( $product ) );
	return "$string";
}

sub xml_product {
	my $self    = shift;
	my $product = shift;
	$self->xml->Product( {
		Id           => $product->product_id,
		Name         => $product->product_name,
		Language     => $product->product_language,
		Version      => $product->product_version,
		Manufacturer => $product->product_manufacturer,
		},
		$self->xml_package,
		$self->xml_product_cab,
		$self->xml_properties,
		$self->xml->Directory( {
			Id   => 'TARGETDIR',
			Name => 'SourceDir',
			},
			$self->xml->Directory( {
				Id   => 'ProgramFilesFolder',
				Name => 'PFiles',
				},
				$self->xml->Directory( {
					Id   => 'MYAPPPATH',
					Name => '.',
					},
					$self->xml_component,
				),
			),
		),
	);
}

sub xml_package {
	my $self = shift;
	$self->xml->Package( {
		Id               => $product->package_id,
		Description      => $product->package_description,
		Comments         => $product->package_comments,
		Manufacturer     => $product->package_manufacturer,
		InstallerVersion => 200,
		Compressed       => 'yes',
	} );
}

sub xml_product_cab {
	my $self = shift;
	$self->xml->Media( {
		Id       => 1,
		Cabinet  => 'product.cab',
		EmbedCab => 'yes',
	} );
}

sub xml_properties {
	my $self = shift;
	map {
		$self->xml_property
	} $self->properties;
}

sub xml_property {
	my $self     = shift;
	my $property = shift;
	$self->xml->Property( {
		Id => $property->id
		},
		$property->value,
	);
}

sub xml_component {
	my $self = shift;
	$self->xml->Component( {
		Id   => 'MyComponent',
		Guid => '12345678-1234-1234-1234-123456789012',
	},
	$self->xml_files,
	);
}

sub xml_files {
	my $self = shift;
	map {
		$self->xml_file( $_ )
	} $self->files;
}

sub xml_file {
	my $self = shift;
	my $file = shift;
	$self->xml->File( {
		Id     => $file->id,
		Name   => $file->name,
		DiskId => $file->diskid,
		Src    => File::Spec->catfile(
			$self->targetdir,
			$file->src,
		),
	} );
}

1;
