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

package net::dryuf::uml::prog::java::JavaOutputGenerator;

use strict;
use warnings;

use Data::Dumper;
use net::dryuf::uml::Util qw(defvalue tabalign dumpSimple);

sub new
{
	my $classname			= shift;
	my $out_context			= shift;

	my $this = bless {
		out_context			=> $out_context,
	}, $classname;

	return $this;
}

sub generateNested
{
	my $this			= shift;
	my $model			= shift;

	if ($model->{stype} eq "typedef") {
		# ignore, java (unfortunately) does not have typedefs
	}
	elsif ($model->{stype} eq "enum") {
		$this->generateEnum($model);
	}
	else {
		net::dryuf::uml::Util::doDie("unknown nested stype: $model->{stype} for class $model->{full}");
	}
}

sub generateEnum
{
	my $this			= shift;
	my $model			= shift;

	my $out_context = $this->{out_context};

	$out_context->printCode("public static class $model->{name}\n{\n");
	my $inner = $out_context->getCodeIndented();
	foreach my $literal (@{$model->getLiterals()}) {
		$inner->print(tabalign("public static final int", 32).tabalign("$literal->{name}", 32)."= $literal->{value};\n");
	}
	$out_context->printCode("};\n");
}


1;
