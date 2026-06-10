# t/13-function-calls.t
use strict;
use warnings;

use Test::More;
use File::Spec::Functions qw(catdir catfile);

use Config::INI::RefVars;

subtest 'simple function calls' => sub {
    my $ini = <<'INI';
[paths]
dir  := $(=& catdir, foo, bar, baz)
file := $(=& catfile, foo, bar.txt)
INI

    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini);

    my $vars = $obj->variables();

    is(
        $vars->{paths}{dir},
        catdir('foo', 'bar', 'baz'),
        'catdir works',
    );

    is(
        $vars->{paths}{file},
        catfile('foo', 'bar.txt'),
        'catfile works',
    );
};

subtest 'nested function calls' => sub {
    my $ini = <<'INI';
[paths]
nested1 := $(=& catfile, $(=& catdir, foo, bar), baz.txt)
nested2 := $(=& catdir, alpha, $(=& catdir, beta, gamma))
INI

    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini);

    my $vars = $obj->variables();

    is(
        $vars->{paths}{nested1},
        catfile(catdir('foo', 'bar'), 'baz.txt'),
        'nested catfile(catdir(...)) works',
    );

    is(
        $vars->{paths}{nested2},
        catdir('alpha', catdir('beta', 'gamma')),
        'nested catdir(..., catdir(...)) works',
    );
};

subtest 'function arguments may contain variable references' => sub {
    my $ini = <<'INI';
[paths]
base := foo
name := bar.txt
full := $(=& catfile, $(base), $(name))
INI

    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini);

    my $vars = $obj->variables();

    is(
        $vars->{paths}{full},
        catfile('foo', 'bar.txt'),
        'arguments may be expanded before function call',
    );
};

subtest 'whitespace and empty arguments' => sub {
    my $ini = <<'INI';
[paths]
dir1 := $(=&   catdir   ,  foo  ,  bar  )
dir2 := $(=& catdir, foo, , bar)
INI

    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini);

    my $vars = $obj->variables();

    is(
        $vars->{paths}{dir1},
        catdir('foo', 'bar'),
        'surrounding whitespace is ignored',
    );

    is(
        $vars->{paths}{dir2},
        catdir('foo', '', 'bar'),
        'empty arguments are preserved',
    );
};

subtest 'unknown function dies' => sub {
    my $ini = <<'INI';
[paths]
bad := $(=& does_not_exist, foo, bar)
INI

    my $ok = eval {
        my $obj = Config::INI::RefVars->new();
        $obj->parse_ini(src => $ini);
        1;
    };

    ok(!$ok, 'parse_ini dies for unknown function');
    like($@, qr/unknown function 'does_not_exist'/, 'error mentions unknown function');
};

#==================================================================================================
done_testing();
