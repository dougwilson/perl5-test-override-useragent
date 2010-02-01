use inc::Module::Install;

use Module::Install::AuthorRequires 0.02;
use Module::Install::AuthorTests 0.002;

name     'Test-Override-UserAgent';
all_from 'lib/Test/Override/UserAgent.pm';
author   'Douglas Christopher Wilson <doug@somethingdoug.com>';
license  'perl';

# Resources
resources homepage   => 'http://github.com/dougwilson/perl5-test-override-useragent/';
resources repository => 'git://github.com/dougwilson/perl5-test-override-useragent.git';

# Modules that are required
requires
	'Carp'              => 0,
	'HTTP::Config'      => '5.815',
	'HTTP::Date'        => 0,
	'HTTP::Headers'     => 0,
	'HTTP::Response'    => 0,
	'HTTP::Status'      => '5.817',
	'LWP::Protocol'     => 0,
	'LWP::UserAgent'    => 0,
	'Scalar::Util'      => 0,
	'Sub::Install'      => '0.90',
	'Sub::Override'     => 0,
	'Try::Tiny'         => 0,
	'URI'               => 0,
	'namespace::clean'  => '0.04';

# Modules that are required for tests in t/
test_requires
	'HTTP::Request'   => 0,
	'HTTP::Response'  => 0,
	'IO::String'      => 0,
	'LWP::UserAgent'  => 0,
	'Test::Exception' => '0.03',
	'Test::More'      => 0;

# Modules that are required for tests in xt/
author_requires
	'Test::More'     => 0,
	'Test::Requires' => '0.02';

# Enable tests to be in multi-level directories
tests_recursive;

# Author tests in xt/
recursive_author_tests('xt');

# Write the provided classes in the META
auto_provides;

WriteAll;
