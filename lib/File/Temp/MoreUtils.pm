package File::Temp::MoreUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001; # for // & state var
use strict;
use warnings;

use Fcntl ':DEFAULT';
use File::Temp ();

use Exporter 'import';
our @EXPORT_OK = qw(tempfile_named);

our %SPEC;

$SPEC{tempfile_named} = {
    v => 1.1,
    summary => 'Try to create a temporary file with certain name '.
        '(but used .tmp1, .tmp2, ... suffix if already exists) ',
    description => <<'_',

Unlike <pm:File::Temp>'s `tempfile()` which creates a temporary file with a
unique random name, this routine tries to create a temporary file with a
specific name, but adds a counter suffix when the specified name already exists.
This is often desirable in the case when we want the temporary file to have
a name similarity with another file.

And like <pm:File::Temp>'s `tempfile()`, will return:

    ($fh, $filename)

_
    result_naked => 1,
    args => {
        name => {
            schema => 'filename*',
            pos => 0,
            req => 1,
        },
        dir => {
            summary => 'If specified, will create the temporary file here',
            description => <<'_',

If specified and set to `undef`, will create new temporary directory using
<pm:File::Temp>'s `tempdir` (with CLEANUP option set to true unless DEBUG
environment variable is set to true) and use this temporary directory for the
directory, including for subsequent invocation for the same process whenever
`dir` is set to `undef` again.

_
            schema => 'dirname',
        },
        suffix_start => {
            schema => ['str*', min_len=>1],
            default => 1,
            description => <<'_',

Will use Perl's post-increment operator (`++`) to increment the suffix, so this
works with number as well as letter combinations, e.g. `aa` will be incremented
to `ab`, `ac` and so on.

_
        },
    },
    examples => [
        {
            args => {name=>'source.pdf'},
            summary => 'Attempt to create source.pdf, then if already exists source.1.pdf, and so on',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            args => {name=>'source', dir=>undef},
            summary => 'Attempt to create source.pdf in a temporary directory, then if already exists source.1, and so on',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            args => {name=>'source.pdf', suffix_start=>'tmp1'},
            summary => 'Attempt to create source.pdf, then if already exists source.tmp1.pdf, then source.tmp2.pdf, and so on',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub tempfile_named {
    my %args = @_;

    die "tempfile_named(): Please specify name" unless defined $args{name};

    state $tempdir;
    my $dir;
    if (exists $args{dir}) {
        if (defined $args{dir}) {
            $dir = $args{dir};
        } else {
            $tempdir //= File::Temp::tempdir(CLEANUP => !$ENV{DEBUG});
            $dir = $tempdir;
        }
        die "tempfile_named(): dir '$dir' is not a directory" unless -d $dir;
    }

    my $suffix_start = $args{suffix_start} // 1;
    my $suffix;
    my $fh;
    my $name0 = defined $dir ? "$dir/" . File::Basename::basename($args{name}) : $args{name};
    my $counter = 1;
    while (1) {
        my $name = $name0;
        if (defined $suffix) {
            $name =~ s/(.+\.)(?=.)/"$1$suffix."/e
                or $name .= ".$suffix";
            $suffix++;
        } else {
            $suffix = $suffix_start;
        }
        if (sysopen $fh, $name, O_CREAT | O_CREAT | O_EXCL) {
            return ($fh, $name);
        }
        unless ($! =~ /File exists/) {
            die "tempfile_named(): Can't create temporary file '$name': $!";
        }
        if ($counter++ > 10_000) {
            die "tempfile_named(): Can't create temporary file after many retries: $!";
        }
    }
}

1;
#ABSTRACT: Provide more routines related to creating temporary files/dirs

=head1 SYNOPSIS


=head1 SEE ALSO

L<File::Temp>


=head1 ENVIRONMENT

=head2 DEBUG
