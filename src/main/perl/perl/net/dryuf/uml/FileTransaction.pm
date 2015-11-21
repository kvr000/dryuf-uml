#
# Dryuf framework
#
# ----------------------------------------------------------------------------------
#
# Copyright (C) 2000-2015 Zbyněk Vyškovský
#
# ----------------------------------------------------------------------------------
#
# LICENSE:
#
# This file is part of Dryuf
#
# Dryuf is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# Dryuf is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
# more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Dryuf; if not, write to the Free Software Foundation, Inc., 51
# Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# @author	2000-2015 Zbyněk Vyškovský
# @link		mailto:kvr@matfyz.cz
# @link		http://kvr.matfyz.cz/software/java/dryuf/
# @link		http://github.com/dryuf/
# @license	http://www.gnu.org/licenses/lgpl.txt GNU Lesser General Public License v3
#

package net::dryuf::uml::FileTransaction;

use strict;
use warnings;

use File::Basename;
use File::Path;
use File::Slurp;
use net::dryuf::uml::FileWriter;

use constant {
	TMP_SUFFIX		=> ".tmp",
};

sub new
{
	my $class = shift; $class = ref($class) || $class;

	return bless { opers => [], umask => eval { my $u = umask(0); umask($u); $u } }, $class;
}

sub flush
{
	my $this		= shift;

	foreach my $op (@{$this->{opers}}) {
		if ($op->{fd}) {
			$op->{fd}->flush();
		}
	}
}

sub commit
{
	my $this		= shift;

	foreach my $op (@{$this->{opers}}) {
		if ($op->{fd}) {
			$this->closeOp($op);
		}
	}

	$this->{opers} = [];
}

sub touch
{
	my $this		= shift;
	my ( $file ) = @_;

	if (-e $file) {
		die "Failed to touch $file: $!" unless (utime(undef, undef, $file));
	}
	else {
		die "Failed to create file $file: $!" unless (write_file($file, ""));
	}
}

sub rollback
{
	my $this		= shift;

	foreach my $op (@{$this->{opers}}) {
		if ($op->{fd}) {
			$op->{fd}->close();
			undef $op->{fd};
		}
		if ($op->{op} eq "rm") {
			unlink($op->{fname});
		}
		elsif ($op->{op} eq "update") {
		}
		else {
			die "unsupported operation: $op->{op}";
		}
	}
	$this->{opers} = [];
}

sub mkdir
{
	my $this			= shift;
	my $dir				= shift;

	-d $dir or mkpath($dir) or -d $dir
		or die "failed to create directory $dir: $!";
}

sub openRead
{
	my $this		= shift;
	my $fname		= shift;

	my $fd = FileHandle->new($fname, "<")
		or die "failed to open file $fname for reading: $!";
	return $fd;
}

sub createTruncated
{
	my $this		= shift;
	my $fname		= shift;

	if (my @st = stat($fname)) {
		chmod(($st[2]&07777)|(0222&~$this->{umask}), $fname);
	}
	my $fd;
	if (!defined ($fd = FileHandle->new($fname.TMP_SUFFIX, ">"))) {
		mkpath(dirname($fname));
		$fd = FileHandle->new($fname.TMP_SUFFIX, ">")
			or die "failed to open file $fname: $!";
	}
	$fd = net::dryuf::uml::FileWriter->new($fd);
	$fd->binmode();
	push(@{$this->{opers}}, { op => "rm", fname => $fname, fd => $fd });
	return $fd;
}

sub updateChanged
{
	my $this		= shift;
	my $fname		= shift;

	my $fd = net::dryuf::uml::FileWriter->new(net::dryuf::uml::Util::createStringStream());
	push(@{$this->{opers}}, { op => "update", fname => $fname, fd => $fd });
	return $fd;
}

sub closeFile
{
	my $this		= shift;
	my $fd			= shift;

	my $op;
	for (my $i = $#{$this->{opers}}; $i >= 0; $i--) {
		if (defined $this->{opers}[$i]->{fd} && $this->{opers}[$i]->{fd} == $fd) {
			$op = $this->{opers}[$i];
			unshift(@{$this->{opers}}, splice(@{$this->{opers}}, $i, 1)) if ($i != $#{$this->{opers}});
			$this->closeOp($op);
			return;
		}
	}
	die "fd $fd not opened within transaction";
}

sub closeOp
{
	my $this		= shift;
	my $op			= shift;

	$op->{fd}->flush();
	if ($op->{fd}->error()) {
		die "failed to write to $op->{fname}: ".$op->{fd}->error();
	}
	if ($op->{op} eq "update") {
		$op->{fd}->seek(0, 0);
		my $content = "";
		while ($op->{fd}->read(my $buf, 32768) > 0) { $content .= $buf; }
		my $orig_cont = read_file($op->{fname}, err_mode => 'quiet');
		if (!(defined $orig_cont) || $orig_cont ne $content) {
			my $updatefd = $this->createTruncated($op->{fname});
			$updatefd->print($content);
			$this->closeFile($updatefd);
		}
		undef $op->{fd};
	}
	else {
		$op->{fd}->close();
		undef $op->{fd};
		rename($op->{fname}.TMP_SUFFIX, $op->{fname});
		chmod((stat($op->{fname}))[2]&07555, $op->{fname}) if (defined $this->{umask});
	}
}

sub DESTROY
{
	my $this		= shift;

	$this->rollback();
}


1;
