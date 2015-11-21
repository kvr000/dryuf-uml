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

package net::dryuf::uml::GenmapReader;

use strict;
use warnings;

use File::Basename;
use FileHandle;
use DB_File;
use net::dryuf::uml::Util;

sub new
{
	my $ref				= shift;
	my $class			= ref($ref) || $ref;
	my $listname			= shift;
	my $section			= shift;
	my $packages			= shift;

	my $this = bless {
		listname			=> $listname,
		section				=> $section,
		packages			=> $packages ? { map({ $_ => 1 } @$packages) } : undef,
	}, $class;

	return $this;
}

sub open
{
	my $listname			= shift;
	my $section			= shift;
	my $packages			= shift;

	if ($listname =~ m/\.db$/) {
		return net::dryuf::uml::GenmapReader::Db->new($listname, $section, $packages);
	}
	else {
		return net::dryuf::uml::GenmapReader::List->new($listname, $section, $packages);
	}
}

sub checkPackage
{
	my $this			= shift;
	my $cls				= shift;

	if ($this->{packages}) {
		my $conv = $cls;
		$conv =~ s/::/./g;
		for (; $conv ne ""; $conv = substr($conv, 0, rindex($conv, "."))) {
			return 1 if ($this->{packages}{$conv});
			return 0 unless (index($conv, ".") >= 0);
		}
		return 0;
	}
	else {
		return 1;
	}
}

package net::dryuf::uml::GenmapReader::List;

use strict;
use warnings;

use base qw(net::dryuf::uml::GenmapReader);

sub new
{
	my $class = shift; $class = ref($class) || $class;

	my $this = $class->SUPER::new(@_);

	$this->{list_fd} = FileHandle->new($this->{listname}, "<")
		or net::dryuf::uml::Util::doDie("failed to open $this->{listname}: $!");
	$this->{lineno} = 0;

	return $this;
}

sub getNext
{
	my $this			= shift;

	while (defined (my $line = $this->{list_fd}->getline())) {
		$this->{lineno}++;
		chomp($line);
		next if ($line =~ m/^\s*(#.*|)$/);
		net::dryuf::uml::Util::doDie("invalid format, need \"location classname\"") unless ($line =~ m/^(\S+)\s+((\w+::)*\w+)$/);
		my ( $loc, $cls ) = ( $1, $2 );
		return ( $loc, $cls ) if (return $this->checkPackage($cls));
	}
	return;
}

sub getContext
{
	my $this			= shift;

	return "$this->{listname}:$this->{lineno}";
}


package net::dryuf::uml::GenmapReader::Db;

use strict;
use warnings;

use base qw(net::dryuf::uml::GenmapReader);

use DB_File;
use File::Basename;
use Data::Dumper;
use net::dryuf::uml::Util;

sub new
{
	my $class = shift; $class = ref($class) || $class;

	my $this = $class->SUPER::new(@_);

	our %list_hash;
	$this->{list_db} = tie(%list_hash, 'DB_File', $this->{listname}, O_RDONLY, 0666, $DB_BTREE)
		or net::dryuf::uml::Util::doDie("failed to open $this->{listname}");
	$this->{cur_key} = undef;

	return $this;
}

sub getNext
{
	my $this			= shift;

	for (;;) {
		if (!defined ($this->{cur_key})) {
			$this->{cur_key} = "$this->{section}\t";
			return if ($this->{list_db}->seq($this->{cur_key}, my $val, R_CURSOR) != 0);
		}
		else {
			return if ($this->{list_db}->seq($this->{cur_key}, my $val, R_NEXT) != 0);
		}
		if ($this->{cur_key} =~ m/^$this->{section}\t\d+\t((\w+::)*\w+)$/) {
			my ( $loc, $cls ) = ( dirname($this->{listname}), $1 );
			return ( $loc, $cls ) if ($this->checkPackage($cls));
		}
	}
	return;
}

sub getContext
{
	my $this			= shift;

	return "";
}


1;
