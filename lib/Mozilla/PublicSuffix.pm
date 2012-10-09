package Mozilla::PublicSuffix;

use strict;
use warnings FATAL => "all";
use utf8;
use Carp;
use Exporter "import";
use URI::_idna;

our @EXPORT_OK = qw(public_suffix);

our $VERSION = 'v0.1.9'; # VERSION
# ABSTRACT: Get a domain name's public suffix via the Mozilla Public Suffix List

my $dn_re = do {
    my $alf = "[[:alpha:]]";
    my $aln = "[[:alnum:]]";
    my $anh = "[[:alnum:]-]";
    my $re_str = join(
        "",
        "(?:$alf(?:(?:$anh){0,61}$aln)?",
        "(?:\\.$alf(?:(?:$anh){0,61}$aln)?)*)"
    );
    qr/^$re_str$/;
};
sub public_suffix {
    # Decode domains in punycode form:
    my $domain = index($_[0], "xn--") == -1
        ? lc $_[0]
        : eval { lc URI::_idna::decode($_[0]) };

    # Test domain well-formedness:
    if ($domain !~ $dn_re) {
        croak("Argument passed is not a well-formed domain name");
    }

    # Search using the full domain and a substring consisting of its lowest
    # levels:
    return _find_rule($domain, substr($domain, index($domain, ".") + 1 ) );
}

my %rules = qw();
sub _find_rule {
    my ($string, $rhs) = @_;
    my $rule = $rules{$string};
    return do {
        # Test for rule match with full string:
        if (defined $rule) {
            # If a wilcard rule matches the full string; fail early:
            if ($rule eq "w") { undef }
            # All other rule matches mean success:
            else { $string }
        }
        # Fail if no match found and the full string and right-hand substring
        # are identical:
        elsif ($string eq $rhs) { undef }
        # No match found with the full string, but there are more levels of the
        # domain to check:
        else {
            my $rrule = $rules{$rhs};
            # Test for rule match with right-hand side:
            if (defined $rrule) {
                # If a wildcard rule matches the right-hand substring, the
                # full string is the public suffix:
                if ($rrule eq "w") { $string }
                # Otherwise, it's the substring:
                else { $rhs }
            }
            # Recurse with the right-hand substring as the full string, and the
            # old substring sans its lowest domain level as the new substring:
            else {
                _find_rule( $rhs, substr($rhs, index($rhs, ".") + 1 ) );
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
From the official website at L<http://publicsuffix.org>:

=over

A "public suffix" is one under which Internet users can directly register names.
Some examples of public suffixes are .com, .co.uk and pvt.k12.wy.us. The Public
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
or C<undef> if the public suffix is not found. Croaks if the passed argument is
not a well-formed domain name.

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

Copyright © 2012 Richard Simões. This module is released under the terms of the
B<MIT License> and may be modified and/or redistributed under the same or any
compatible license.
