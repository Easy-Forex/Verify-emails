NAME
    verify-emails.pl - Check the list of emails for valid addresses

USAGE
            ./verify-emails.pl [OPTIONS]
            
DEPENDENCIES

    On Ubuntu/Debian install: 
    $ sudo apt install libmail-checkuser-perl libparallel-forkmanager-perl

OPTIONS
    --emails (required)
        Example: --emails=emails.txt

        The file should be a plain text file with one email address per
        line. It's OK for the file to contain duplicate addresses - all
        checks will be performed only once for each unique email address.

    --children (optional)
        Example: --children=10

        This parameter can be used to specify the number of maximum parallel
        child processes. If not given, the default of 20 is used.

    --from_email (optional)
        Example: --from_email=someone@here.com

        This parameter can be used to specify the FROM email address for
        SMTP checks. If not given, the default of check@user.com is used.

    --from_domain (optional)
        Example: --from_domain=here.com

        This parameter can be used to specify the EHLO domain for SMTP
        checks. If not given, the domain of the from_email option is used.

    --blacklist (optional)
        Example: --blacklist=blacklist.txt

        The file should be a plain text file with blacklisted strings or
        regular expressions for email addresses. Any address matching any of
        the rules will be skipped from all the checks. This is useful for
        filtering out group email addresses like sales@ or info@, as well as
        spam words in domains or local parts.

    --output (optional)
        Example: --output="%email% - %status% - %reason%\n"

        This parameter defines the script's output. You can use three macros
        that will be replaced with content automatically:

        * %email% - this will be replaced with the email address that is
        being checked

        * %status% - this will be either OK or FAIL, depending on whether
        email address passed the check

        * %reason% - for failed addresses this will provide a reason why
        validation failed

        By default, the format is set to a simple CSV

EXAMPLE
            ./verify-emails.pl --emails=emails.txt --children=10 --blacklist=blacklist.txt > out.csv

DESCRIPTION
    verify-emails.pl performs the following three checks for each email in
    the given list:

            1. Check the format of the email address.
            2. Check that MX or A record is available for the domain part.
            3. Connect to the mail server via SMTP and use MAIL and RCPT commands
               to check if the mailbox exists.  No actual email is being sent.

    In order to speed up the processing of emails, the script will fork
    multiple child processes. The maximum can be defined through the command
    line option.

REQUIREMENTS
    This script relies on the following perl modules (available from CPAN):

    Getopt::Long
        For reading command line parameters reliably.

    List::MoreUtils
        For removing duplicates in the lists of emails and blacklist rules.

    Parallel::ForkManager
        For easy forking.

    Mail::CheckUser
        For the actual email address checks.

AUTHOR
    Leonid Mamchenkov <leonidm@easy-forex.com>

