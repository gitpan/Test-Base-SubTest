package Test::Base::SubTest;
use strict;
use warnings;
use utf8;
use parent qw(Exporter);
our @EXPORT = (@Test::More::EXPORT, qw/filters blocks register_filter run run_is run_is_deeply/);

our $VERSION = '0.1';

use parent qw/
    Test::Base::Less
    Test::Builder::Module Exporter
/;
use Test::More;
use Carp qw/croak/;
use Text::TestBase::SubTest;

my $SKIP;

sub blocks() { croak 'block() is not supported. Use run{} instead.' }

{
    no warnings 'once';
    *filters         = \&Test::Base::Less::filters;
    *register_filter = \&Test::Base::Less::register_filter;
}

sub run(&) {
    my $code = shift;

    my $content = _get_data_section();
    my $node = Text::TestBase::SubTest->new->parse($content);

    _exec_each_test($node, sub {
        my $block = shift;
        $code->($block);
    });
}

sub run_is($$) {
    my ($a, $b) = @_;
    my $content = _get_data_section();
    my $node = Text::TestBase::SubTest->new->parse($content);

    _exec_each_test($node, sub {
        my $block = shift;
        __PACKAGE__->builder->is_eq(
            $block->get_section($a),
            $block->get_section($b),
            $block->name || 'L: ' . $block->get_lineno
        );
    });
}

sub run_is_deeply($$) {
    my ($a, $b) = @_;
    my $package = scalar(caller(0));

    my $content = _get_data_section();
    my $node = Text::TestBase::SubTest->new->parse($content);

    _exec_each_test($node, sub {
        my $block = shift;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        Test::More::is_deeply(
            $block->get_section($a),
            $block->get_section($b),
            $block->name || 'L: ' . $block->get_lineno
        );
    });
}

sub _exec_each_test {
    my ($subtest, $code) = @_;

    my $executer = sub {
        for my $node (@{ $subtest->child_nodes }) {
            if ($node->is_subtest) {
                _exec_each_test($node, $code);
            } else {
                next if $SKIP;

                my @names = $node->get_section_names;
                for my $section_name (@names) {
                    my @data = $node->get_section($section_name);
                    if (my $filter_names = $Test::Base::Less::FILTER_MAP{$section_name}) {
                        for my $filter_stuff (@$filter_names) {
                            if (ref $filter_stuff eq 'CODE') { # filters { input => [\&code] };
                                @data = $filter_stuff->(@data);
                            } else { # filters { input => [qw/eval/] };
                                my $filter = $Test::Base::Less::FILTERS{$filter_stuff};
                                unless ($filter) {
                                    Carp::croak "Unknown filter name: $filter_stuff";
                                }
                                @data = $filter->(@data);
                            }
                        }
                    }
                    $node->set_section($section_name => @data);
                }
                if ($node->has_section('ONLY')) {
                    Carp::croak "Sorry, section 'ONLY' is not implemented...";
                    #  これLASTと全く一緒じゃね？
                    __PACKAGE__->builder->diag("I found ONLY: maybe you're debugging?");
                    $SKIP = 1;
                    $code->($node);
                    next;
                }
                if ($node->has_section('SKIP')) {
                    next;
                }
                if ($node->has_section('LAST')) {
                    $SKIP = 1;
                    $code->($node);
                    next;
                }

                $code->($node);
            }
        }
    };
    if ($subtest->depth == 0) {
        $executer->();
    } else {
        return if $SKIP;
        __PACKAGE__->builder->subtest(
            ($subtest->name || 'XXX lineno here') => $executer
        );
    }
}

sub _get_data_section {
    my $package = scalar(caller(1));
    my $d = do { no strict 'refs'; \*{"${package}::DATA"} };
    unless (defined fileno $d) {
        Carp::croak("Missing __DATA__ section in $package.");
    }
    seek $d, 0, 0;

    return join '', <$d>;
}

1;
__END__

=head1 NAME

Test::Base::Less - Enables Test::Base to use subtest

=head1 SYNOPSIS

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

=head1 DESCRIPTION

=head1 FUNCTIONS

=head1 SEE ALSO

Most of code is taken from L<Test::Base::Less>.

=head1 AUTHOR

Hiroki Honda E<lt>cside.story@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Hiroki Honda

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
