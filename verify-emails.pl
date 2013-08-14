#!/usr/bin/perl -w

=pod

=head1 NAME

verify-emails.pl - Check the list of emails for valid addresses

=head1 USAGE

	./verify-emails.pl [OPTIONS]

=head1 OPTIONS

=over 

=item --emails (required)

Example: --emails=emails.txt

The file should be a plain text file with one email address per line. It's
OK for the file to contain duplicate addresses - all checks will be performed
only once for each unique email address.

=item --children (optional)

Example: --children=10 

This parameter can be used to specify the number of maximum parallel child
processes.  If not given, the default of 20 is used.

=item --blacklist (optional)

Example: --blacklist=blacklist.txt

The file should be a plain text file with blacklisted strings or regular
expressions for email addresses.  Any address matching any of the rules will be
skipped from all the checks.  This is useful for filtering out group email
addresses like sales@ or info@, as well as spam words in domains or local parts.

=item --output (optional)

Example: --output="%email% - %status% - %reason%\n"

This parameter defines the script's output.  You can use three macros that will be replaced
with content automatically:

* %email% - this will be replaced with the email address that is being checked

* %status% - this will be either OK or FAIL, depending on whether email address passed the check

* %reason% - for failed addresses this will provide a reason why validation failed

By default, the format is set to a simple CSV

=back

=head1 EXAMPLE

	./verify-emails.pl --emails=emails.txt --children=10 --blacklist=blacklist.txt > out.csv

=head1 DESCRIPTION

verify-emails.pl performs the following three checks for each email
in the given list:

	1. Check the format of the email address.
	2. Check that MX or A record is available for the domain part.
	3. Connect to the mail server via SMTP and use MAIL and RCPT commands
	   to check if the mailbox exists.  No actual email is being sent.

In order to speed up the processing of emails, the script will fork
multiple child processes.  The maximum can be defined through the
command line option.

=head1 REQUIREMENTS

This script relies on the following perl modules (available from CPAN):

=over

=item Getopt::Long

For reading command line parameters reliably.

=item List::MoreUtils

For removing duplicates in the lists of emails and blacklist rules.

=item Parallel::ForkManager

For easy forking.

=item Mail::CheckUser

For the actual email address checks.

=back

=head1 AUTHOR

Leonid Mamchenkov <leonidm@easy-forex.com>

=cut

use strict;
use Getopt::Long;
use List::MoreUtils qw(uniq);
use Parallel::ForkManager;
use Mail::CheckUser qw(check_email last_check);

my $emails_file = '';
my $blacklist_file = '';
my $max_children = 20;
my $output_format = "%email%,%status%,%reason%\n"; # simple CSV

GetOptions(
	'emails=s' => \$emails_file,
	'children=i' => \$max_children,
	'blacklist=s' => \$blacklist_file,
	'output=s' => \$output_format,
);

if (!$emails_file) {
	print_help();
	die("No --emails given");
}

my @emails = get_emails($emails_file);
if ($blacklist_file) {
	@emails = clean_emails($blacklist_file, @emails);
}

my $pm = Parallel::ForkManager->new($max_children);

foreach my $email (@emails) {
	$pm->start and next; # do the fork

	my $status;
	my $reason = '';
	eval {
		chomp($email);
		$status = check_email($email) if ($email);
	};
	if ($@) {
		$status = 'FAIL';
		$reason = $@;
	}
	else {
		if ($status) {
			$status = 'OK';
		}
		else {
			$status = 'FAIL';
			$reason = last_check()->{reason};
		}
	}
	my $out = $output_format;
	$out =~ s/%email%/$email/g;
	$out =~ s/%status%/$status/g;
	$out =~ s/%reason%/$reason/g;
	print $out;

	$pm->finish; # do the exit in the child process
}
$pm->wait_all_children;

# Print usage help
sub print_help {
	print "Usage:\n";
	print "\t$0 --emails=FILE [--children=NUMBER] [--blacklist=FILE]\n\n"
}

# Get emails from the given file
sub get_emails {
	my @result;

	my $email_file = shift;

	@result = get_uniq_file_lines($email_file);

	return @result;
}

# Clean emails using rules from blacklist file
sub clean_emails {
	my @result;

	my $blacklist_file = shift;
	my @emails = @_;

	my @rules = get_uniq_file_lines($blacklist_file);

	@result = @emails;
	foreach my $rule (@rules) {
		@result = grep !/$rule/, @result;
	}

	return @result;
}

# Get unique lines from file
sub get_uniq_file_lines {
	my @result;

	my $file = shift;

	open(my $fh, "<", "$file") or die "Failed to read $file: $@";
	@result = <$fh>;
	close($fh);
	chomp(@result);

	@result = uniq @result;

	return @result;
}
