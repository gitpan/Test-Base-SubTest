use strict;
use warnings;
use utf8;
use Test::More;
use Test::Base::Less;
use Test::Base::SubTest;
filters {
    input => [qw(eval)],
    expected => [qw(eval)],
};

run {
    my $block = shift;
    is $block->input, $block->expected, $block->name;
};

done_testing;

__DATA__

### subtest 1
    ### subtest 1-1
        === test 1-1
        --- input:    4*2
        --- expected: 8

        === test 1-2
        --- input :   3*3
        --- expected: 9

    ### subtest 1-2
        === test 2-1
        --- input:    4*3
        --- expected: 12
