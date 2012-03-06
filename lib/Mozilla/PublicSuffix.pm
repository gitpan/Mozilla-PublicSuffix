package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => "all";
use utf8;
use parent "Exporter";
use Carp ();
use Net::LibIDN qw(idn_prep_name idn_to_ascii idn_to_unicode);

our @EXPORT_OK = qw(public_suffix);

our $VERSION = 'v0.0.2'; # VERSION
# ABSTRACT: Get a domain name's "public suffix" via Mozilla's Public Suffix List

my %rules = qw();
sub public_suffix {
	my ($domain) = @_;

	# Test domain well-formedness:
	eval { $domain = idn_to_unicode idn_to_ascii idn_prep_name $domain }
		or Carp::croak("Argument passed is not a well-formed domain name");

	# Gather matching rules:
	my @labels = split /\./, $domain;
	my @matches = sort { $b->{label} =~ tr/.// <=> $a->{label} =~ tr/.// }
		map {
			my $label = $_ == 0 ? $domain : join ".", @labels[ $_ .. $#labels ];
			exists $rules{$label}
				? { type => $rules{$label}, label => $label }
				: (); } 0 .. $#labels;

	# Choose prevailing rule and return suffix, if one is to be found:
	return do {
		@matches == 0
			? undef
			: do {
				my @exc_rules = grep { $_->{type} eq "e" } @matches;
				@exc_rules > 0
					? @exc_rules == 1
						? undef
						# Recheck with left-mode label chopped off
						: public_suffix($exc_rules[0]{label} =~ /^[^.]+\.(.*)$/)
					: do {
						my ($type, $label) = @{$matches[0]}{qw(type label)};
						$type eq "w"
							and ($label) = $domain =~ /((?:[^.]+\.)$label)$/;
						$label ||= undef; } } }; }

1;
=encoding utf8

=head1 NAME

Mozilla::PublicSuffix - Get a domain name's public suffix via Mozilla's Public Suffix List

=head1 SYNOPSIS

	use feature "say";
	use Mozilla::PublicSuffix "public_suffix";

	say public_suffix("org");       # "org"
	say public_suffix("perl.org");  # "org"
	say public_suffix("perl.orc");  # undef
	say public_suffix("ga.gov.au"); # "gov.au"
	say public_suffix("ga.goo.au"); # undef

=head1 DESCRIPTION

This module provides a single function that returns the I<public suffix> of a
domain name by referencing a parsed copy of Mozilla's Public Suffix List
(official website at L<http://publicsuffix.org>). The algorithm is not the one
prescribed on Mozilla's website, but a robust test battery included in this
distribution should provide sufficient evidence that the one used in its placed
is an acceptable substitute.

A copy of the official list is bundled with the distribution. As the official
list continues to be updated, the bundled copy will inevitably fall out of date.
Therefore, if the bundled copy of found to be over thirty days old, this
distribution's installer provides the option to check for a new version of the
list and download/use it if one is found.

=head1 FUNCTIONS

=over

=item public_suffix

Exported on request. Simply returns the public suffix of the passed argument,
or C<undef> if the public suffix is not found. Croaks if the passed argument
is not a well-formed domain name.

=back

=head1 SEE ALSO

=over

=item L<Domain::PublicSuffix>

An alternative to this module, with an object-oriented interface and slightly
difference interpretation of the rules Mozilla stipulates for determining a
public suffix.

=back

=head1 AUTHOR

Richard Simões C<< <rsimoes AT cpan DOT org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 Richard Simões. This module is released under the terms of the
L<GNU Lesser General Public License v. 3.0|http://gnu.org/licenses/lgpl.html>
and may be modified and/or redistributed under the same or any compatible
license.
