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

package net::dryuf::uml::prog::java::JavaOutFileContext;

use strict;
use warnings;

use Data::Dumper;
use net::dryuf::uml::Util qw(defvalue tabalign dumpSimple);


sub new
{
	my $classname			= shift; $classname = ref($classname) || $classname;
	my $model_store			= shift;
	my $sysimportCtx		= shift;
	my $appimportCtx		= shift;
	my $codeCtx			= shift;

	net::dryuf::uml::Util::doDie("codeCtx undefined") unless ($codeCtx);

	my $this = bless {
		model_store			=> $model_store,
		sysimportCtx			=> $sysimportCtx,
		appimportCtx			=> $appimportCtx,
		codeCtx				=> $codeCtx,
	}, $classname;

	return $this;
}

sub getSysimportCtx
{
	my $this			= shift;

	return $this->{sysimportCtx};
}

sub printSysimport
{
	my $this			= shift;
	my $line			= shift;

	$this->{sysimportCtx}->printOnce($line);
}

sub printAppimport
{
	my $this			= shift;
	my $line			= shift;

	$this->{appimportCtx}->printOnce($line);
}

sub printCode
{
	my $this			= shift;
	my $line			= shift;

	$this->{codeCtx}->print($line);
}

sub getCodeIndented
{
	my $this			= shift;

	return $this->{codeCtx}->indentContext(1);
}

sub getSubIndented
{
	my $this			= shift;

	return $this->new($this->{model_store}, $this->{sysimportCtx}, $this->{appimportCtx}, $this->getCodeIndented());
}

sub dupWithFileContext
{
	my $this			= shift;
	my $file_context		= shift;

	return $this->new($this->{model_store}, $this->{sysimportCtx}, $this->{appimportCtx}, $file_context);
}


1;
