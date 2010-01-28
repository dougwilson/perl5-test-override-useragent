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
use Carp qw(croak);
use HTTP::Headers;
use HTTP::Response;
use LWP::UserAgent; # Not actually required here, but want it to be loaded
use Scalar::Util;
use Sub::Install 0.90;
use Sub::Override;
use URI;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# METHODS
sub handle_request {
	my ($self, $request) = @_;

	# Lookup the handler for the request
	my $handler = $self->_get_handler_for($request);

	if (!defined $handler) {
		# No handler defined for this request
		return;
	}

	# Get the response
	my $response = _convert_psgi_response($handler->($request));

	if (!defined $response->request) {
		# Set the request that made this response
		$response->request($request);
	}

	return $response;
}
sub install_in_user_agent {
	my ($self, $user_agent, %args) = @_;

	# Get the clone argument
	my $clone = exists $args{clone} ? $args{clone} : 0;

	if ($clone) {
		# Make a clone of the user agent
		$user_agent = $user_agent->clone;
	}

	# Add as a handler in the user agent
	$user_agent->add_handler(
		request_send => sub { return $self->handle_request(shift); },
		owner        => Scalar::Util::refaddr($self),
	);

	# Return the user agent
	return $user_agent;
}
sub override_request {
	my ($self, @args) = @_;

	# Get the handler from the end
	my $handler = pop @args;

	# Convert the arguments into a hash
	my %args = $self->_with_default_arguments(@args);

	# Register the handler
	$self->_register_handler($handler, %args);

	# Enable chaining
	return $self;
}
sub uninstall_from_user_agent {
	my ($self, $user_agent) = @_;

	# Remove our handlers from the user agent
	$user_agent->remove_handler(
		owner => Scalar::Util::refaddr($self),
	);

	# Return the user agent for some reason
	return $user_agent;
}

###########################################################################
# STATIC METHODS
sub import {
	my ($class, %args) = @_;

	# What this module is being used for
	my $use_for = $args{for} || 'testing';

	if ($use_for eq 'configuration') {
		# Create a new configuration object that will be wrapped in
		# closures.
		my $conf = $class->new;

		# Install override_request
		Sub::Install::install_sub({
			code => sub { return $conf->override_request(@_); },
			as   => 'override_request',
		});

		# Install custom configuration which retuns the config object
		Sub::Install::install_sub({
			code => sub { return $conf; },
			as   => 'configuration',
		});
	}

	return;
}

###########################################################################
# CONSTRUCTOR
sub new {
	my ($class, @args) = @_;

	# Get the arguments as a plain hash
	my %args = @args == 1 ? %{shift @args}
	                      : @args
	                      ;

	# Create a hash with configuration information
	my %data = (
		_default_args => { # Default arguments
			scheme => 'http',
		},
		_lookup_table => {},
	);

	# Bless the hash to this class
	my $self = bless \%data, $class;

	# Return our blessed configuration
	return $self;
}

###########################################################################
# PRIVATE METHODS
sub _get_handler_for {
	my ($self, $request) = @_;

	# Extract information from the request URI
	my $uri = URI->new($request->uri)->canonical;

	# Get the handler from the HASH
	my $handler = $self->{_lookup_table}
		->{$uri->host}
		->{$uri->port}
		->{$uri->scheme}
		->{$uri->path};

	return $handler;
}
sub _register_handler {
	my ($self, $handler, %args) = @_;

	# Create a URI object
	my $uri = URI->new;

	# Specify what the URI object normalizes
	my @uri_normalizes = qw(scheme host port path);

	# Set the pieces
	foreach my $piece (@uri_normalizes) {
		$uri->can($piece)->($uri, $args{$piece});
	}

	# Normalize the URI
	$uri = $uri->canonical;

	# Set the handler in the HASH
	$self->{_lookup_table}
		->{$uri->host}
		->{$uri->port}
		->{$uri->scheme}
		->{$uri->path} = $handler;

	return;
}
sub _with_default_arguments {
	my ($self, %args) = @_;

	# Mixin the defaults
	foreach my $key (keys %{$self->{_default_args}}) {
		if (!exists $args{$key}) {
			# Set the key to the default
			$args{$key} = $self->{_default_args}->{$key};
		}
	}

	# Return just a plain hash
	return %args;
}

###########################################################################
# PRIVATE FUNCTIONS
sub _convert_psgi_response {
	my ($response) = @_;

	if (!defined Scalar::Util::blessed($response)) {
		# Get the type of the response
		my $response_type = Scalar::Util::reftype($response);

		if (defined $response_type && $response_type eq 'ARRAY') {
			# This is a PSGI-formatted response
			my ($status_code, $headers, $body) = @{$response};

			# Change the headers to a header object
			$headers = HTTP::Headers->new(@{$headers});

			if (ref $body ne 'ARRAY') {
				# The body is a filehandle
				my $fh = $body;

				# Change the body to an array reference
				$body = [];

				while (defined(my $line = $fh->getline)) {
					# Push the line into the body
					push @{$body}, $line;
				}

				# Close the file
				$fh->close;
			}

			# Create the response object
			$response = HTTP::Response->new(
				$status_code, undef, $headers, join q{}, @{$body});
		}
	}

	return $response;
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

  override_request url => '/test.html', sub {
      my ($request) = @_;

      # Do something with request and make HTTP::Response

      return $response;
  };

  package main;

  # Load the module
  use Test::Override::UserAgent for => 'testing';

=head1 DESCRIPTION

This module allows for very easy overriding of the request-response cycle of
L<LWP::UserAgent> and any other module extending it. The override can be done
per-scope (where the API of a module doesn't let you alter it's internal user
agent obejct) or per-object, but modifying the user agent.

=head1 CONSTRUCTOR

=head2 new

This will construct a new configuration object to allow for configuring user
agent overrides.

=over 4

=item B<new(%attributes)>

C<%attributes> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<new($attributes)>

C<$attributes> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head1 ATTRIBUTES

There are no attributes.

=head1 METHODS

=head2 handle_request

This takes one argument, which is a L<HTTP::Request> object and will return
either a L<HTTP::Response> if the request had a corresponding override or
C<undef> if no override was present to handle the request.

=head2 install_in_user_agent

This will install the overrides directly in a user agent, allowing for
localized overrides. This is the perferred method of overrides. This will
return the user agent that has the overrides installed.

  # Install into a user agent
  $ua_override->install_in_user_agent($ua);

  # Install into a new copy
  my $new_ua = $ua_override->install_in_user_agent($ua, clone => 1);

The first argument is the user agent object (expected to have the C<add_handler>
method) that the overrides will be installed in. After that, the method takes a
hash of arguments:

=over 4

=item clone

This is a Boolean specifying to clone the given user agent (with the C<clone>
method) and install the overrides into the new cloned user agent. The default
is C<0> to not clone the user agent.

=back

=head2 override_request

This will add a new request override to the configuration. The argument is a
plain hash with the keys listed below and a subroutine reference as the last
argument. The subroutine must function as specified in L</HANDLER SUBROUTINE>.

=over 4

=item host

=item path

=item port

=item scheme

=back

=head2 uninstall_from_user_agent

This method will remove the handlers belonging to this configuration from
the specified user agent. The first argument is the user agent to remove
the handlers from.

=head1 HANDLER SUBROUTINE

The handler subroutine is what you will give to actualy handle a request and
return a response. The handler subroutine is always given a L<HTTP::Request>
object as the first argument, which is the request for the handler to handle.

The return value can be one of type kinds:

=over 4

=item L<HTTP::Response> object

=item L<PSGI> response array reference

=back

=head1 DEPENDENCIES

=over 4

=item * L<Carp>

=item * L<HTTP::Headers>

=item * L<HTTP::Response>

=item * L<LWP::UserAgent>

=item * L<Scalar::Util>

=item * L<Sub::Install> 0.90

=item * L<Sub::Override>

=item * L<URI>

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
