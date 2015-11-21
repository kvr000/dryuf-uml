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

package net::dryuf::uml::prog::gen::CopyGenerator;

use strict;
use warnings;

use base qw(net::dryuf::uml::prog::gen::GenericGenerator);

sub process
{
	my $this			= shift;

	my $output = $this->{file_trans}->updateChanged("$this->{gen_dir}/$this->{in_fname}");

	while (defined (my $line = $this->{in_parser}->readLine())) {
		$output->print($line);
	}
	$output->flush();

	return 0;
}

sub getContext
{
	my $this		= shift;

	return $this->{in_parser}->getContext();
}

sub dieContext
{
	my $this		= shift;
	my $context		= shift;
	my $msg			= shift;

	net::dryuf::uml::Util::doDie("$context: $msg");
}


1;
