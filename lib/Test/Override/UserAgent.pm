package Test::Override::UserAgent;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.001';

###########################################################################
# MODULE IMPORTS
use LWP::UserAgent; # Not actually required here, but want it to be loaded
use Sub::Install 0.90;
use Sub::Override;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# STATIC METHODS
sub import {
	my ($class, %args) = @_;

	# What this module is being used for
	my $use_for = $args{for} || 'testing';

	if ($use_for eq 'configuration') {
		# The caller says it is a configuration module
		Sub::Install::install_sub({
			# Install handle_request
			code => sub {}, # TODO: write this
			as   => 'handle_request',
		});
	}

	return;
}

1;

__END__

=head1 NAME

Test::Override::UserAgent - Override the LWP::UserAgent to return canned
responses for testing

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

  package Test::My::Module::UserAgent::Configuration;

  # Load into configuration module
  use Test::Override::UserAgent for => 'configuration';

  # Allow unhandled requests to be live
  allow_live;

  handle_request url => '/test.html', sub {
      my ($request) = @_;

      # Do something with request and make HTTP::Response

      return $response;
  };

=head1 DESCRIPTION

This module allows for very easy overriding of the request-response cycle of
L<LWP::UserAgent> and any other module extending it. The override can be done
per-scope (where the API of a module doesn't let you alter it's internal user
agent obejct) or per-object, but modifying the user agent.

=head1 METHODS

There are no methods provided.

=head1 DEPENDENCIES

=over 4

=item * L<LWP::UserAgent>

=item * L<Sub::Install> 0.90

=item * L<Sub::Override>

=item * L<namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-test-override-useragent at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Override-UserAgent>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Test::Override::UserAgent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Override-UserAgent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Override-UserAgent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Override-UserAgent>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Override-UserAgent/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
