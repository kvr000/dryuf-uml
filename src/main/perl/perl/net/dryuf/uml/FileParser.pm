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

package net::dryuf::uml::FileParser;

use strict;
use warnings;

use FileHandle;
use net::dryuf::uml::Util;

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

sub getFd
{
	my $this		= shift;

	return $this->{fd};
}

sub readLine
{
	my $this		= shift;

	my $line;
	if (defined ($line = $this->{pending})) {
		undef $this->{pending};
	}
	elsif (defined ($line = $this->{fd}->getline())) {
		$this->{lineno}++;
	}
	return $line;
}

sub unreadLine
{
	my $this		= shift;
	my $line		= shift;

	net::dryuf::uml::Util::doDie("File $this->{fname} already has unread line") if (defined $this->{pending});
	$this->{pending} = $line;
}

sub getContext
{
	my $this		= shift;

	return "$this->{fname}:$this->{lineno}";
}


1;
