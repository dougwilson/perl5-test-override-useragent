#!perl

use 5.008;
use strict;
use warnings 'all';

use Test::More;
use Test::Requires 0.02;

# Required modules for this test
test_requires 'Test::Module::Used' => '0.1.4';

if (!eval { Test::Module::Used->VERSION('0.1.9'); 1; }) {
	# Monkey patch Test::Module::Used 0.1.8 and lower to work correctly
	# until the module is patched.
	no strict 'refs';
	no warnings 'redefine';

	*{'Test::Module::Used::_test_files'} = sub {
		my $self = shift;
		return $self->_find_files_by_ext($self->_test_dir, qr/\.t$/),
		       $self->_pm_files_in_test;
	};
}

# Test that used in Makefile.PL, META.yml, and files all match
Test::Module::Used->new->ok;
