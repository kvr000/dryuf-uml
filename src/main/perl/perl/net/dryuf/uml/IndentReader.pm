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

package net::dryuf::uml::IndentReader;

use strict;
use warnings;

sub new
{
	my $class = shift; $class = ref($class) || $class;
	my $fname		= shift;

	my $fd = FileHandle->new($fname, "<")
		or net::dryuf::uml::Util::doDie("failed to open $fname");

	my $this = bless {
		fname			=> $fname,
		lineno			=> 0,
		fd			=> $fd,
		pending			=> undef,
	}, $class;

	return $this;
}

sub cacheLine
{
	my $this		= shift;

	if (!defined $this->{pending}) {
		return unless (defined ($this->{pending} = $this->{fd}->getline()));
		$this->{lineno}++;
	}
	return $this->{pending};
}

sub resetLine
{
	my $this		= shift;

	undef $this->{pending};
}

sub getBaseLeveler
{
	my $this		= shift;

	return net::dryuf::uml::IndentReader::Leveler->new($this, 0);
}

sub getContext
{
	my $this		= shift;

	return "$this->{fname}:$this->{lineno}";
}


package net::dryuf::uml::IndentReader::Leveler;

use strict;
use warnings;

sub new
{
	my $class = shift; $class = ref($class) || $class;
	my $reader		= shift;
	my $level		= shift;

	my $this = bless {
		reader			=> $reader,
		level			=> $level,
	}, $class;

	return $this;
}

sub getPair
{
	my $this		= shift;

	if (defined (my $line = $this->{reader}->cacheLine())) {
		if ($line !~ m/^(\t*)(\w+)\s+(.*)$/) {
			die "invalid format: $line";
		}
		return if (length($1) < $this->{level});
		die "sub level not read" if (length($1) > $this->{level});
		$this->{reader}->resetLine();
		return ( $2, $3 );
	}
	else {
		return;
	}
}

sub skipRecursive
{
	my $this		= shift;

	while (my ($k, $v) = $this->getPair()) {
		$this->getSubLeveler()->skipRecursive();
	}
}

sub getSubLeveler
{
	my $this		= shift;

	return $this->new($this->{reader}, $this->{level}+1);
}

sub getContext
{
	my $this		= shift;

	return $this->{reader}->getContext();
}


1;
