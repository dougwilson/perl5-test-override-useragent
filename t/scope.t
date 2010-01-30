#!perl -T

use Test::More tests => 6;
use Test::Exception 0.03;

use LWP::UserAgent;
use Test::Override::UserAgent for => 'testing';
use Test::Override::UserAgent::Scope;

# Make a new override
my $conf = Test::Override::UserAgent->new->override_request(
	host => 'localhost',
	path => '/NOTHING',
	sub { return [200, ['Content-Type' => 'text/plain'], ['NO']]; },
);

# Make a user agent
my $ua = LWP::UserAgent->new(timeout => 1);

{
	# Install in scope
	my $scope;

	lives_ok { $scope = $conf->install_in_scope; }
		'Install into scope';

	# Make request
	is $ua->get('http://localhost/NOTHING')->content, 'NO',
		'Overridden request handled';
	is $ua->get('http://www.google.com/')->status_line, '404 Not Found (No Live Requests)',
		'www.google.com request failed';
}

# Make request
isnt $ua->get('http://localhost/NOTHING')->content, 'NO',
	'Overridden request no longer present';

{
	throws_ok { Test::Override::UserAgent::Scope->new }
		qr{\AMust supply override attribute}ms,
		'Constructor fails without override attribute';

	# Manually make a scope
	my $scope = new_ok 'Test::Override::UserAgent::Scope' => [{override => $conf}];
}
