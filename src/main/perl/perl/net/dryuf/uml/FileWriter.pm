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

package net::dryuf::uml::FileWriter::Context;

use strict;
use warnings;

sub new
{
	my $class			= shift;
	my $owner			= shift;

	return bless {
		owner				=> $owner,
		indent				=> $owner->{indent},
		context				=> $owner->{current},
	}, $class;
}

sub print
{
	my $this			= shift;
	my $content			= shift;

	$content =~ s/^(.+)$/$this->{indent}$1/gm;
	$this->{context}->{content} .= $content;
}

sub printPlain
{
	my $this			= shift;
	my $content			= shift;

	$this->{context}->{content} .= $content;
}

sub printf
{
	my $this			= shift;
	
	my $content			= 

	$this->print(sprintf(@_));
}

sub removeOptionalEnd
{
	my $this			= shift;
	my $over			= shift;

	substr($this->{context}->{content}, -length($over)) = "" if (substr($this->{context}->{content}, -length($over)) eq $over);
}

sub replaceOptionalEnd
{
	my $this			= shift;
	my $over			= shift;
	my $replace			= shift;

	substr($this->{context}->{content}, -length($over)) = $replace if (substr($this->{context}->{content}, -length($over)) eq $over);
}

sub printOnce
{
	my $this			= shift;
	my $content			= shift;

	my $owner = $this->{owner};

	return 0 if (defined $owner->{printed}->{$content});
	$owner->{printed}->{$content} = 1;
	$this->print($content);
	return 1;
}

sub indentContext
{
	my $this			= shift;
	my $level			= shift || 1;

	my $ind_ctx = $this->subContext();
	$ind_ctx->{indent} = $this->{indent}.("\t" x $level);

	return $ind_ctx;
}

sub subContext
{
	my $this			= shift;

	$this->{owner}->print("");

	my $new_context = { content => "", next => $this->{context}->{next} };
	my $ind_ctx = net::dryuf::uml::FileWriter::Context->new($this->{owner});
	$ind_ctx->{context} = { content => "", next => $new_context };
	$this->{context}->{next} = $ind_ctx->{context};
	$ind_ctx->{indent} = $this->{indent};

	$this->{context} = $new_context;

	return $ind_ctx;
}

sub subAfterContext
{
	my $this			= shift;

	$this->{owner}->print("");

	my $ind_ctx = net::dryuf::uml::FileWriter::Context->new($this->{owner});
	$ind_ctx->{context} = { content => "", next => $this->{context}->{next} };
	$this->{context}->{next} = $ind_ctx->{context};
	$ind_ctx->{indent} = $this->{indent};

	return $ind_ctx;
}


package net::dryuf::uml::FileWriter;

use strict;
use warnings;

use Data::Dumper;

sub new
{
	my $class			= shift;
	my $realfd			= shift;

	my $this = bless {}, $class;

	my $current_piece = { content => "", next => undef };
	$this->{realfd} = $realfd;
	$this->{pieces} = $current_piece;
	$this->{current} = $current_piece;
	$this->{printed} = {};
	$this->{indent} = "";

	return $this;
}

sub rememberContext
{
	my $this			= shift;

	$this->print("");

	return net::dryuf::uml::FileWriter::Context->new($this);
}

sub print
{
	my $this			= shift;
	my $content			= shift;

	$this->{current} = ($this->{current}->{next} = { content => $content, next => undef });
}

sub printf
{
	my $this			= shift;
	
	my $fmt				= shift;
	my $content			= sprintf($fmt, @_);

	$this->print($content);
}

sub printIndented
{
	my $this			= shift;
	my $content			= shift;

	$content =~ s/^(.+)$/$this->{indent}$1/gm;
	$this->print($content);
}

sub printAt
{
	my $this			= shift;
	my $context			= shift;
	my $content			= shift;

	$context->print($content);
}

sub printOnce
{
	my $this			= shift;
	my $context			= shift;
	my $content			= shift;

	$context->printOnce($content);
}

sub indent
{
	my $this			= shift;
	my $indent_change		= shift;

	if ($indent_change > 0) {
		$this->{indent} .= "\t" x $indent_change;
	}
	else {
		$this->{indent} = substr($this->{indent}, 0, $indent_change);
	}
}

sub flush
{
	my $this			= shift;

	if (defined $this->{current}) {
		for (my $context = $this->{pieces}; $context; $context = $context->{next}) {
			$this->{realfd}->print($context->{content});
		}
		$this->{current} = undef;
	}

	return $this->{realfd}->flush();
}

sub seek
{
	my $this			= shift;

	$this->flush();

	return $this->{realfd}->seek(@_);
}

sub read
{
	my $this			= shift;
	
	return $this->{realfd}->read(@_);
}

sub error
{
	my $this			= shift;

	return $this->{realfd}->error(@_);
}

sub binmode
{
	my $this			= shift;

	return $this->{realfd}->binmode(@_);
}

sub close
{
	my $this			= shift;

	return $this->{realfd}->close(@_);
}


1;
