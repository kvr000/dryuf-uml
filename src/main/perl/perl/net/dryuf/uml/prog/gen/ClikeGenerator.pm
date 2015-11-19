package net::dryuf::uml::prog::gen::ClikeGenerator;

use strict;
use warnings;

use Data::Dumper;
use net::dryuf::uml::prog::gen::GenericGenerator;

require Exporter;
our @ISA = qw(Exporter net::dryuf::uml::prog::gen::GenericGenerator);
our @EXPORT_OK = qw(CMT_UNKNOWN CMT_LINE CMT_BLOCK CMT_CONTINUOUS CMT_SINGLE);
our %EXPORT_TAGS = ( CMT => [ qw(CMT_UNKNOWN CMT_LINE CMT_BLOCK CMT_CONTINUOUS CMT_SINGLE) ] );

use base qw(net::dryuf::uml::prog::gen::GenericGenerator);

sub CMT_UNKNOWN			{ 0 }
sub CMT_LINE			{ 1 }
sub CMT_BLOCK			{ 2 }
sub CMT_CONTINUOUS		{ 3 }
sub CMT_SINGLE			{ 4 }

sub process
{
	my $this			= shift;

	my $errors = 0;

	$this->{out_main} = $this->openTargets();
	$this->{currentCtx} = $this->{out_main}->rememberContext();

	while (defined (my $line = $this->{in_parser}->readLine())) {
		eval {
			$errors += $this->processPrecheckLine($line);
			if ($line =~ m/^\s*\/\*dry\s*$/) {
				$this->processCommentBody();
			}
			elsif ($line =~ m/^\s*\/\/dry\s+(\w+):\s*(.*?)\s*$/) {
				$errors += $this->processCommentSingle($1, $2);
			}
			else {
				($this->{cur_indent} = $line) =~ s/^(\s*).*/$1/;
				$errors += $this->processLine($line);
			}
		};
		if ($@) {
			STDERR->print($this->{in_parser}->getContext().": fatal error occurred: $@");
			return 1;
		}
	}

	$this->finish() if ($errors == 0);

	return $errors;
}

sub openTargets
{
	my $this			= shift;

	return undef;
}

sub finish
{
	my $this			= shift;
}

sub processPrecheckLine
{
	my $this			= shift;
	my $line			= shift;

	return 0;
}

sub processLine
{
	my $this			= shift;
	my $line			= shift;

	$this->printLine($line);

	return 0;
}

sub processCommentBody
{
	my $this			= shift;

	my $errors = 0;

	$errors += $this->processCommentStart();
	while (defined (my $line = $this->{in_parser}->readLine())) {
		if ($line =~ m/^\s+\*\s*$/) {
			$this->processCommentEmpty($line);
			next;
		}
		elsif ($line =~ m/^\s+\*\s*(\w+):\s*(.*)/) {
			my $cmtag = $1;
			my $content = $2;
			my $cmtype = $this->getCommentType($1);

			if ($cmtype == CMT_UNKNOWN) {
				$errors += $this->printError("unknown comment type: $cmtag");
			}
			elsif ($cmtype == CMT_LINE) {
				$errors += $this->processCommentLine($cmtag, $content);
			}
			elsif ($cmtype == CMT_BLOCK) {
				die "expecting block format for $cmtag: $content" unless ($content =~ m/\{\s*$/);
				my $block = "";
				while (defined ($line = $this->{in_parser}->readLine())) {
					if (m/^\s*\*\s*}:$cmtag\s*$/) {
						$this->processCommentBlock($cmtag, $content, $block);
						last;
					}
					elsif (m/^\s*\*\s*(.*)$/) {
						$block .= $1;
					}
					else {
						die "unexpected content of block $cmtag";
					}
				}
			}
			elsif ($cmtype == CMT_CONTINUOUS) {
				while (defined ($line = $this->{in_parser}->readLine())) {
					if (m/^\s*\*\s*$/) {
						$this->processCommentContinuous($cmtag, $content);
						last;
					}
					elsif (m/^\s*\*\s+(.*)$/) {
						$content .= $1;
					}
					else {
						die "unexpected content of continuous $cmtag";
					}
				}
			}
			elsif ($cmtype == CMT_SINGLE) {
				die "unsupported CMT_SINGLE in this section";
			}
		}
		elsif ($line =~ m/^\s+\*\//) {
			$errors += $this->processCommentEnd();
			last;
		}
		else {
			die "invalid comment content: $line";
		}
	}

	return $errors;
}

sub processCommentStart
{
	my $this			= shift;
	my $line			= shift;

	return 0;
}

sub processCommentEnd
{
	my $this			= shift;
	my $line			= shift;

	return 0;
}

sub processCommentEmpty
{
	my $this			= shift;
	my $line			= shift;

	return 0;
}

sub processCommentLine
{
	my $this			= shift;
	my $cmtag			= shift;
	my $content			= shift;

	die "unsupported tag: $cmtag";
}

sub processCommentBlock
{
	my $this			= shift;
	my $cmtag			= shift;
	my $head			= shift;
	my $block			= shift;

	die "unsupported tag: $cmtag";
}

sub processCommentContinuous
{
	my $this			= shift;
	my $cmtag			= shift;
	my $head			= shift;
	my $block			= shift;

	die "unsupported tag: $cmtag";
}

sub processCommentSingle
{
	my $this			= shift;
	my $cmtag			= shift;
	my $content			= shift;

	die "unsupported tag: $cmtag";
}

sub processRegularLine
{
	my $this			= shift;
	my $line			= shift;

	$this->printLine($line);
}

sub getCommentType
{
	my $this			= shift;
	my $cmtag			= shift;
	my $cmcontent			= shift;

	return CMT_UNKNOWN;
}

sub printError
{
	my $this			= shift;
	my $msg				= shift;

	STDERR->print($this->{in_parser}->getContext().": $msg\n");
	return 1;
}

sub printLine
{
	my $this			= shift;
	my $line			= shift;

	$this->{currentCtx}->print($line) if (defined $this->{currentCtx});
}

sub printIndented
{
	my $this			= shift;
	my $text			= shift;

	my $ind = $this->{cur_indent};
	chomp($ind);

	$text =~ s/^/$ind/gm;
	$this->{currentCtx}->print($text) if (defined $this->{out_main});
}


1;
