package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => "all";
use utf8;
use Exporter "import";
use URI::_idna;

our @EXPORT_OK = qw(public_suffix);

our $VERSION = 'v0.1.17'; # VERSION
# ABSTRACT: Get a domain name's public suffix via the Mozilla Public Suffix List

my $dn_re = do {
    my $alf = "[[:alpha:]]";
    my $aln = "[[:alnum:]]";
    my $anh = "[[:alnum:]-]";
    my $re_str = join(
        "",
        "(?:$aln(?:(?:$anh){0,61}$aln)?",
        "(?:\\.$aln(?:(?:$anh){0,61}$aln)?)*)"
    );
    qr/^$re_str$/;
};
sub public_suffix {

    # Decode domains in punycode form:
    my $domain = defined($_[0]) && ref($_[0]) eq ""
        ? index($_[0], "xn--") == -1
            ? lc $_[0]
            : eval { lc URI::_idna::decode($_[0]) }
        : "";

    # Return early if domain is not well-formed:
    return unless $domain =~ $dn_re;

    # Search using the full domain and a substring consisting of its lowest
    # levels:
    return _find_rule($domain);
}

my %rules = qw();

# Right-hand side of a domain name:
sub _rhs {
    my ($domain) = @_;
    return substr($domain, index($domain, ".") + 1);
}

sub _find_rule {
    my ($domain) = @_;
    my $rhs = _rhs($domain);
    my $rule = $rules{$domain};

    return do {
        # Test for rule match with full domain:
        if (defined $rule) {
            # An identity rule match means the full domain is the public suffix:
            if ( $rule eq "i" ) { $domain } # return undef in scalar context

            # If a wilcard rule matches the full domain, fail out:
            elsif ( $rule eq "w" ) { () }

            # An exception rule means the right-hand side is the public suffix:
            else { $rhs }
        }

        # Fail if no match found and the full domain and right-hand side are
        # identical:
        elsif ( $domain eq $rhs ) { () } # return undef in scalar context

        # No match found with the full domain, but there are more levels of the
        # domain to check:
        else {
            my $rrule = $rules{$rhs};

            # Test for rule match with right-hand side:
            if (defined $rrule) {

                # If a wildcard rule matches the right-hand side, the full
                # domain is the public suffix:
                if ( $rrule eq "w" ) { $domain }

                # An identity rule match means it's the right-hand side:
                elsif ( $rrule eq "i" ) { $rhs }

                # An exception rule match means it's the right-hand side of the
                # right-hand side:
                else { _rhs($rhs) }
            }

            # Recurse with the right-hand side as the full domain, and the old
            # right-hand side sans its lowest domain level as the new right-hand
            # side:
            else {
                _find_rule($rhs, _rhs($rhs));
            }
        }
    }
}

1;
=encoding utf8

=head1 NAME

Mozilla::PublicSuffix - Get a domain name's public suffix via the Mozilla Public Suffix List

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
domain name by referencing a parsed copy of Mozilla's Public Suffix List.
From the official website at L<http://publicsuffix.org/>:

=over

A "public suffix" is one under which Internet users can directly register names.
Some examples of public suffixes are com, co.uk and pvt.k12.wy.us. The Public
Suffix List is a list of all known public suffixes.

=back

A copy of the official list is bundled with the distribution. As the official
list continues to be updated, the bundled copy will inevitably fall out of date.
Therefore, if the bundled copy of found to be over thirty days old, this
distribution's installer provides the option to check for a new version of the
list and download/use it if one is found.

=head1 FUNCTIONS

=over

=item public_suffix($domain)

Exported on request. Simply returns the public suffix of the passed domain name,
or C<undef> if the public suffix is not found.

=back

=head1 SEE ALSO

=over

=item L<Domain::PublicSuffix>

Similar to this module, with an object-oriented interface and somewhat
alternative interpretation of the rules Mozilla stipulates for determining a
public suffix.

=back

=head1 AUTHOR

Richard Simões C<< <rsimoes AT cpan DOT org> >>

=head1 COPYRIGHT & LICENSE

Copyright © 2013 Richard Simões. This module is released under the terms of the
B<MIT License> and may be modified and/or redistributed under the same or any
compatible license.
