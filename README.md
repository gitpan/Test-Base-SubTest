# NAME

Test::Base::Less - Enables Test::Base to use subtest

# SYNOPSIS

    use Test::Base::SubTest;

    filters { input => [qw/eval/] };
    run {
        my $block = shift;
        is($block->input, $block->expected);
    };
    done_testing;

    __DATA__

    ### subtest 1
      === test 1-1
      --- input:    4*2
      --- expected: 8

      === test 1-2
      --- input :   3*3
      --- expected: 9

    ### subtest 2
      === test 2-1
      --- input:    4*3
      --- expected: 12

# DESCRIPTION

# FUNCTIONS

# SEE ALSO

Most of code is taken from [Test::Base::Less](https://metacpan.org/pod/Test::Base::Less).

# AUTHOR

Hiroki Honda <cside.story@gmail.com>

# LICENSE

Copyright (C) Hiroki Honda

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
