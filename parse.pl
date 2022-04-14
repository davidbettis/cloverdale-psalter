#!/usr/bin/perl

use strict;
use Data::Dumper;
use JSON;

sub parsePsalm {
    my @psalm = @_;

    my $latinTitle = shift(@psalm);
    
    my %verses = ();
    my $verseNumber = 0;

    foreach my $verse (@psalm) {
        if ($verse =~ /^([0-9]+) (.*$)/) {
            $verseNumber = $1;
            my @newVerses = ();
            push(@newVerses, $2);
            $verses{$verseNumber} = \@newVerses;
        } elsif ($verseNumber > 0) {
            my @newVerses = @{$verses{$verseNumber}};
            push(@newVerses, $verse);
            $verses{$verseNumber} = \@newVerses;
        }
    }

    my $struct = {
        'latinTitle' => $latinTitle,
        'verses' => \%verses
    };

    return $struct;
}

sub formatPsalm {
    my ($psalm) = @_;

    my $formatted = {};
    $formatted->{psalmNumber} = $i - 1;
    $formatted->{verses} = ();
    $formatted->{latinTitle} = $psalm->{latinTitle};

    for my $verseIdx (sort { $a <=> $b } keys %{$psalm->{verses}}) {
        my $elt = {};
        $elt->{'verseIndex'} = $verseIdx;
        $elt->{'lines'} = $psalm->{verses}->{$verseIdx};

        push(@{$formatted->{verses}}, $elt);
    }

    return $formatted;
}

my @allPsalms;

# Example:
#
# day 1 : morning prayer
# 1
# Beatus vir qui non abiit
# 1 Blessed is the man who has not walked in the counsel
# of the ungodly, *
# nor stood in the way of sinners, and has not sat in the seat
# of the scornful;
# 2 But his delight is in the law of the Lord, *
# and on his law will he meditate day and night.
# 3 And he shall be like a tree planted by the waterside, *
# that will bring forth his fruit in due season.
# ...

# Keep track of which psalm is being parsed
my $i = 1;

# Accumulate the lines of a particular psalm in this array
my @contents = ();

while (my $line = <STDIN>) {
    chomp($line);

    # Each entry is designated for a particular day; ignore that entry
    next if $line =~ /^day/;

    # Take out non-ASCII characters
    $line =~ s/[^[:ascii:]\x{1F600}-\x{1F64F}]+//g;

    # Take out nulls
    #line =~ s/\x00//g;

    # We hit a new psalm
    if ($line eq "$i") {
        # Parse the stuff accumulated
        my $psalm = &parsePsalm(@contents);
        my $formatted = &formatPsalm($psalm);

        # When $i==1 (start), the content is empty
        if ($i > 1) {
            push(@allPsalms, $formatted);
        }

        # Reset the buffer
        @contents = ();
        # Move to the next psalm
        $i++;
    } elsif ($line =~ /[0-9][0-9][0-9]/) {
        # This is the page number from the PDF. Ignore it.
    } else {
        # Accumulate line
        push(@contents, $line);
    }
}

# Take care of the last item
my $psalm = &parsePsalm(@contents);
my $formatted = &formatPsalm($psalm);
push(@allPsalms, $formatted);

print to_json(\@allPsalms, {pretty => 1});
