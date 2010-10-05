package Deep::Encode;

use 5.008008;
use strict;
use warnings;

require Exporter;
require Encode;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Deep::Encode ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 
	all => [ qw( 
		deep_utf8_off
		deep_utf8_decode
	   	deep_utf8_encode
	   	deep_from_to
		deep_encode
		deep_decode
		) ], 
	 );

our @EXPORT_OK = ( map @$_, map  $EXPORT_TAGS{$_} , 'all' );

our @EXPORT =  ( map @$_, map  $EXPORT_TAGS{$_} , 'all');

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('Deep::Encode', $VERSION);

1;
__END__

=head1 NAME

Deep::Encode - Perl extension for  coding and decoding strings in arrays and hashes ( recursive )

=head1 SYNOPSIS

  use Deep::Encode;

  my $s = [ 1, 2, "string in cp1251 encoding" ];

  deep_from_to( $s, "cp1251", "utf8" ); # convert $s to [ [ 1, 2, "string in utf8 encoding" ]; using Encode::from_to

  deep_utf8_encode( $s ) ; # call utf8::encode on every string in $s
  deep_utf8_decode( $s ) ; # call utf8::decode on every string in $s

  deep_encode( $s, $encoding );  # call Encode::encode for every string scalar in
  deep_decode( $s, $encoding );  # call Encode::decode for every string scalar in 

=head1 DESCRIPTION

	This module allow apply Encode::from_to, utf8::decode, utf8::encode function on every scalar in array or hash recursively

=head2 EXPORT

  deep_from_to( $s, $from, $to )
  deep_utf8_decode( $s )
  deep_utf8_encode( $s )

  deep_encode( $s, $encoding );  # call Encode::encode on every string scalar in
  deep_decode( $s, $encoding );  # call Encode::decode on every string scalar in 
  deep_utf8_off( $s ); # checkoff utf8 flag. return number applied items.

=head1 FEATURES
  This module does not handle hash keys, but values it does.

  $encoding may be as string like "utf8", "cp1251" or object returned from &Encode::find_encoding ( It will be little faster than string )

=head1 BUGS && TODO
  For now this module can't handle self referrenced structures. 

=head1 SEE ALSO

L<Encode>, L<utf8>, L<Data::Recursive::Encode> (pure perl implementation)

=head1 AUTHOR

A.G. Grishaev, E<lt>grian@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by A.G. Grishaev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
