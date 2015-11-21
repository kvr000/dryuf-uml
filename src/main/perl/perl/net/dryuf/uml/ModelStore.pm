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

package net::dryuf::uml::ModelStore::Util;

use strict;
use warnings;

use Scalar::Util;
use Data::Dumper;

sub genericLoad
{
	my $obj			= shift;
	my $reader		= shift;
	my $splitter		= shift;

	while (my ($k, $v) = $reader->getPair()) {
		if (my $func = $splitter->{$k}) {
			&$func($obj, $reader, $k, $v);
		}
		else {
			net::dryuf::uml::Util::doDie("unknown key '$k': ".Dumper($splitter));
		}
	}
}

sub genericDryTag
{
	my $val			= shift;

	net::dryuf::uml::Util::doDie("invalid format of drytag: $val") unless ($val =~ m/^(\w+)(\((\w+)\))?\s+(\S.*)$/s);
	return {
		name			=> $1,
		spec			=> $3,
		value			=> $4,
	};
}


package net::dryuf::uml::ModelStore::DryTag;

use strict;
use warnings;

sub new
{
	my $ref			= shift; my $class = ref($ref) || $ref;

	my $this = bless {
		drytag_list		=> [],
		drytag_hash		=> {},
		drytag_spec		=> {},
		drytag_cnt		=> 0,
	}, $class;

	return $this;
}

sub addTag
{
	my $this		= shift;
	my $val			= shift;

	my $drytag = net::dryuf::uml::ModelStore::Util::genericDryTag($val);
	$drytag->{order} = ++$this->{drytag_cnt};
	if (defined $drytag->{spec}) {
		$this->{drytag_spec}->{$drytag->{name}}->{$drytag->{spec}} = $drytag;
	}
	else {
		push(@{$this->{drytag_list}}, $drytag);
		$this->{drytag_hash}->{$drytag->{name}} = $drytag;
	}
}

sub getTag
{
	my $this		= shift;
	my $tag			= shift;

	if (defined (my $val = $this->{drytag_hash}->{$tag})) {
		return $val;
	}
	net::dryuf::uml::Util::doDie("tag '$tag' not found");
}

sub getTagValue
{
	my $this		= shift;
	my $tag			= shift;

	if (defined (my $val = $this->{drytag_hash}->{$tag})) {
		return $val->{value};
	}
	net::dryuf::uml::Util::doDie("tag '$tag' not found");
}

sub checkTag
{
	my $this		= shift;
	my $tag			= shift;

	return $this->{drytag_hash}->{$tag} if (defined $this->{drytag_hash}->{$tag});
	return;
}

sub checkTagValue
{
	my $this		= shift;
	my $tag			= shift;

	return $this->{drytag_hash}->{$tag}->{value} if (defined $this->{drytag_hash}->{$tag});
	return;
}

sub getSpec
{
	my $this		= shift;
	my $tag			= shift;

	if (defined (my $spec = $this->{drytag_spec}->{$tag})) {
		return $spec;
	}
	return {};
}

sub cloneTagger
{
	my $this		= shift;

	my $dup = $this->new();

	$dup->{drytag_list} = [ @{$this->{drytag_list}} ];
	$dup->{drytag_hash} = { %{$this->{drytag_hash}} };
	foreach (keys %{$this->{drytag_spec}}) {
		$dup->{drytag_spec}->{$_} = { %{$this->{drytag_spec}->{$_}} };
	}
	$dup->{drytag_cnt} = $this->{drytag_cnt};

	return $dup;
}

sub mergeReplacing
{
	my $this		= shift;
	my $merge		= shift;

	foreach (@{$merge->{drytag_list}}) {
		if ($this->{drytag_hash}->{$_->{name}}) {;
			for (my $i = 0; ; $i++) {
				splice(@{$this->{drytag_list}}, $i, 1), last if ($this->{drytag_list}->[$i]->{name} eq $_->{name});
			}
		}
		unshift(@{$this->{drytag_list}}, $_);
		$this->{drytag_hash}->{$_->{name}} = $_;
	}
	foreach (keys %{$merge->{drytag_spec}}) {
		my $spec = $merge->{drytag_spec};
		my $tspec;
		$this->{drytag_spec} = $tspec = {} unless (defined ($tspec = $this->{drytag_spec}->{$spec}));
		foreach (keys %{$spec}) {
			next if (defined $tspec->{$_});
			$tspec->{$_} = $spec->{$_};
		}
	}
}

sub mergeAdding
{
	my $this		= shift;
	my $merge		= shift;

	foreach (@{$merge->{drytag_list}}) {
		next if ($this->{drytag_hash}->{$_->{name}});
		push(@{$this->{drytag_list}}, $_);
		$this->{drytag_hash}->{$_->{name}} = $_;
	}
	foreach (keys %{$merge->{drytag_spec}}) {
		my $spec = $merge->{drytag_spec};
		my $tspec;
		$this->{drytag_spec} = $tspec = {} unless (defined ($tspec = $this->{drytag_spec}->{$spec}));
		foreach (keys %{$spec}) {
			next if (defined $tspec->{$_});
			$tspec->{$_} = $spec->{$_};
		}
	}
}


package net::dryuf::uml::ModelStore::ClassBase;

use strict;
use warnings;

use Data::Dumper;

sub new
{
	my $ref			= shift; my $class = ref($ref) || $ref;

	my $owner		= shift;
	my $basic		= shift;

	my $this = bless {
		owner			=> $owner,
		location		=> $basic->{location},
		package			=> $basic->{package},
		name			=> $basic->{name},
		filename		=> $basic->{filename},
		full			=> "$basic->{package}::$basic->{name}",
		stype			=> $basic->{stype},
		nested_names		=> [],
		comment			=> [],
		drytag			=> net::dryuf::uml::ModelStore::DryTag->new(),
	}, $class;

	Scalar::Util::weaken($this->{owner});

	return $this;
}

sub dieContext
{
	my $this			= shift;
	my $msg				= shift;
	my $cause			= shift;

	net::dryuf::uml::Util::doDie(((defined $cause)) ? "$this->{file_context}: $msg\n$cause" : "$this->{file_context}: $msg");
}

our %BASE_MAPPER = (
	nested				=> \&readNested,
	drytag				=> \&readBaseDryTag,
	comment				=> \&readBaseComment,
);

sub getPackageName
{
	my $this			= shift;
	my $separator			= shift;

	my $package = $this->{package};
	$package =~ s/::/$separator/g;
	return $package;
}

sub getPackageDotName
{
	return shift->getPackageName(".");
}

sub getPackageCxxName
{
	return shift->getPackageName("::");
}

sub getPackageBSlashName
{
	return shift->getPackageName("\\");
}

sub getFullDotName
{
	return shift->getFullName(".");
}

sub getFullCxxName
{
	return shift->getFullName("::");
}

sub getFullBSlashname
{
	return shift->getFullName("\\");
}

sub getFullName
{
	my $this			= shift;
	my $separator			= shift;

	my $fullname = $this->{full};
	$fullname =~ s/::/$separator/g if (defined $separator);
	return $fullname;
}

sub getBaseName
{
	my $this			= shift;

	return $this->{name};
}

sub getSubModel
{
	my $this			= shift;
	my $modelName			= shift;

	if ($modelName =~ m/^\.(.*)$/) {
		$modelName = "$this->{package}::$1";
	}
	if ($this->{owner}->{class_hash}->{$modelName}) {
		return $this->{owner}->{class_hash}->{$modelName};
	}
	return $this->{owner}->loadModel($this->{location}, $modelName);
}

sub isPrimitive
{
	return 0;
}

sub formatTyperef
{
	my $this			= shift;
	my $typeref			= shift;

	if ($typeref =~ m/^\.(.*)$/) {
		return "$this->{package}::$1";
	}
	else {
		return $typeref;
	}
}

sub checkSubModel
{
	my $this		= shift;
	my $modelName		= shift;

	net::dryuf::uml::Util::doDie("modelName undefined") unless (defined $modelName);

	if ($this->{owner}->{class_hash}->{$modelName}) {
		return $this->{owner}->{class_hash}->{$modelName};
	}
	return $this->{owner}->checkModel($this->{location}, $modelName);
}

sub getFinalTypeWithTagger
{
	my $this		= shift;

	return ( $this, $this->{drytag}->cloneTagger() );
}

sub getSubFinalTypeWithTagger
{
	my $this			= shift;
	my $subname			= shift;
	my $subtype			= shift;

	if (my $type = net::dryuf::uml::ModelStore::Primitive::checkPrimitive($this, $subtype)) {
		return ( $type, $this->{drytag} );
	}
	elsif ($subtype =~ m/ref:\s*(()|((.+)\.([^.]+))|((.+)\.)|(\.(.+)))\s*$/) {
		if (defined $2) {
			if (defined (my $typeref = $this->checkDryTagValue("typeref"))) {
				net::dryuf::uml::Util::doDie("reference target required") unless (defined $subname);
				return $this->getSubModel($this->formatTyperef($typeref))->getAttr($subname)->getFinalTypeWithTagger();
			}
			else {
				net::dryuf::uml::Util::doDie("reference target required") unless (defined $subname);
				return $this->getSubModel($this->{package})->getAttr($subname)->getFinalTypeWithTagger();
			}
		}
		elsif (defined $3) {
			return $this->getSubModel($4)->getAttr($5)->getFinalTypeWithTagger();
		}
		elsif (defined $6) {
			net::dryuf::uml::Util::doDie("reference target required") unless (defined $subname);
			return $this->getSubModel($6)->getAttr($subname)->getFinalTypeWithTagger();
		}
		elsif (defined $8) {
			my $field_name = $9;
			if (defined (my $typeref = $this->checkDryTagValue("typeref"))) {
				return $this->getSubModel($this->formatTyperef($typeref))->getAttr($field_name)->getFinalTypeWithTagger();
			}
			else {
				return $this->getSubModel($this->{package})->getAttr($field_name)->getFinalTypeWithTagger();
			}
		}
		else {
			die "unexpected regexp result";
		}
	}
	else {
		return $this->getSubModel($subtype)->getFinalTypeWithTagger();
	}
}

sub getDryTagger
{
	my $this		= shift;

	return $this->{drytag};
}

sub getDryTag
{
	my $this		= shift;
	my $tag			= shift;

	eval {
		return $this->{drytag}->getTag($tag);
	}
		or $this->dieContext($@);
}

sub getDryTagValue
{
	my $this		= shift;
	my $tag			= shift;

	eval {
		return $this->{drytag}->getTagValue($tag);
	}
		or $this->dieContext($@);
}

sub checkDryTagValue
{
	my $this		= shift;
	my $tag			= shift;

	return $this->{drytag}->checkTagValue($tag);
}

sub getParentName
{
	my $this			= shift;

	#net::dryuf::uml::Util::doDie("classname $this->{name} does not have prefix") unless ($this->{name} =~ m/^(.*)::.*$/);
	return $this->{package};
}

sub checkDryTagHierarchicalValue
{
	my $this			= shift;
	my $tag				= shift;

	for (my $classdef = $this; $classdef; $classdef = $this->checkSubModel($classdef->getParentName())) {
		if (defined (my $value = $this->checkDryTagValue($tag))) {
			return $value;
		}
	}
	return undef;
}

sub getNestedNames
{
	my $this			= shift;

	return $this->{nested_names};
}

sub getDrySpecs
{
	my $this		= shift;
	my $spec		= shift;

	return $this->{drytag}->getSpec($spec);
}

sub postLoad
{
	my $this			= shift;

	$this->{owner}->{class_hash}->{"$this->{package}::$this->{name}"} = $this unless ($this->checkDryTagValue("disabled"));
}

sub load
{
	my $this		= shift;
	my $reader		= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%BASE_MAPPER);

	$this->postLoad();
}

sub readBaseDryTag
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	$this->{drytag}->addTag(net::dryuf::uml::Util::unescapeString($val));
}

sub readBaseComment
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	push(@{$this->{comment}}, net::dryuf::uml::Util::unescapeString($val));
}

sub readNested
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	push(@{$this->{nested_names}}, net::dryuf::uml::Util::unescapeString($val));
}


package net::dryuf::uml::ModelStore::Primitive;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::ClassBase";

sub checkPrimitive
{
	my $owner		= shift;
	my $type		= shift;

	if ($type =~ m/^ref:/) {
		return;
	}
	elsif ($type =~ m/::/) {
		return;
	}
	else {
		return net::dryuf::uml::ModelStore::Primitive->new($owner, $type, $type);
	}
}

sub new
{
	my $ref			= shift;
	my $class		= ref($ref) || $ref;

	my $owner		= shift;
	my $name		= shift;
	my $type		= shift;

	my $this = $class->SUPER::new($owner, { package => "", name => $name, stype => "primitive" });

	$this->{type} = $type;

	return $this;
}

sub isPrimitive
{
	return 1;
}


package net::dryuf::uml::ModelStore::Class;

use strict;
use warnings;

use Data::Dumper;

use base "net::dryuf::uml::ModelStore::ClassBase";

sub new
{
	my $ref			= shift;
	my $class		= ref($ref) || $ref;

	my $owner		= shift;
	my $basic		= shift;

	my $this = $class->SUPER::new($owner, $basic);

	$this->{field_list} = [];
	$this->{field_hash} = {};
	$this->{action_list} = [];
	$this->{oper_list} = [];
	$this->{view_list} = [];
	$this->{compos} = undef;

	return $this;
}

sub checkCompos
{
	my $this		= shift;

	return $this->{compos};
}

sub getCompos
{
	my $this		= shift;

	net::dryuf::uml::Util::doDie("getting compos which is not defined for $this->{name}") if (!defined $this->{compos});

	return $this->{compos};
}

sub getPrimary
{
	my $this		= shift;

	if (!defined $this->{primary}) {
		$this->{primary} = [];
		foreach my $field (@{$this->{field_list}}) {
			push(@{$this->{primary}}, $field) if ($field->getRole()->{primary});
		}
	}

	return @{$this->{primary}};
}

sub getIndexes
{
	my $this		= shift;

	if (!defined $this->{index_list}) {
		$this->{index_list} = [];
		foreach my $def (sort({ $a->{order} <=> $b->{order} } values %{$this->{drytag}->getSpec("index")})) {
			$this->dieContext("invalid index format, expected (unique|nonunique) (col0 [ASC|DESC], col1...): $def->{value}") unless ($def->{value} =~ m/^(\w+)\s*\(\s*((\w+(\s+(ASC|DESC))?\s*,\s*)*(\w+(\s+(ASC|DESC))?))\s*\)\s*$/);
			my $type = $1;
			my @fields = split(/\s*,\s*/, $2);
			push(@{$this->{index_list}}, {
					name			=> $def->{spec},
					type			=> $type,
					fields			=> \@fields,
				});
		}
	}
	return @{$this->{index_list}};
}

sub getAttrs
{
	my $this		= shift;

	return $this->{field_list};
}

sub getOperations
{
	my $this		= shift;

	return $this->{oper_list};
}

our %CLASS_MAPPER = (
	%net::dryuf::uml::ModelStore::ClassBase::BASE_MAPPER,
	ancestor		=> \&readClassAncestor,
	implements		=> \&readClassImplements,
	compos			=> \&readClassCompos,
	field			=> \&readClassAttr,
	assoc			=> \&readClassAssoc,
	child			=> \&readClassChild,
	action			=> \&readClassAction,
	view			=> \&readClassView,
	oper			=> \&readClassOper,
);

sub load
{
	my $this		= shift;
	my $reader		= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%CLASS_MAPPER);

	$this->postLoad();
}

sub readClassAncestor
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	$this->{$key} = $val;
}

sub readClassImplements
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	$this->{$key} = [ split(/\s+/, $val) ];
}

sub readClassCompos
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	my $compos = net::dryuf::uml::ModelStore::Compos->new($this, { stype => "compos", name => $val });
	$compos->load($base->getSubLeveler());

	push(@{$this->{field_list}}, $compos);

	$this->{compos} = $compos;
}

sub readClassAttr
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	my $field = net::dryuf::uml::ModelStore::Attr->new($this, { stype => "field", name => $val });
	$field->load($base->getSubLeveler());

	if (!$field->checkDryTagValue("disabled")) {
		push(@{$this->{field_list}}, $field);
		$this->{field_hash}{$field->{name}} = $field;
	}
}

sub readClassAssoc
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	my $assoc = net::dryuf::uml::ModelStore::Assoc->new($this, { stype => "assoc", name => $val });
	$assoc->load($base->getSubLeveler());

	push(@{$this->{field_list}}, $assoc);
}

sub readClassChild
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	my $child = net::dryuf::uml::ModelStore::Child->new($this, { stype => "child", name => $val });
	$child->load($base->getSubLeveler());

	push(@{$this->{field_list}}, $child);
}

sub readClassAction
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	my $action = net::dryuf::uml::ModelStore::Action->new($this, { stype => "action", name => $val });
	$action->load($base->getSubLeveler());

	if (!$action->checkDryTagValue("disabled")) {
		push(@{$this->{action_list}}, $action);
	}
}

sub readClassView
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	my $view = net::dryuf::uml::ModelStore::View->new($this, { stype => "view", name => $val });
	$view->load($base->getSubLeveler());

	push(@{$this->{view_list}}, $view);
}

sub readClassOper
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	my $view = net::dryuf::uml::ModelStore::Oper->new($this, { stype => "oper", name => $val });
	$view->load($base->getSubLeveler());

	push(@{$this->{oper_list}}, $view);
}

sub getAttr
{
	my $this		= shift;
	my $field_name		= shift;

	$this->dieContext("field $field_name not found in $this->{name}") unless (defined $this->{field_hash}{$field_name});
	return $this->{field_hash}{$field_name}
}


package net::dryuf::uml::ModelStore::Typedef;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::ClassBase";

sub new
{
	my $ref			= shift;
	my $class		= ref($ref) || $ref;

	my $owner		= shift;
	my $basic		= shift;

	my $this = $ref->SUPER::new($owner, $basic);

	$this->{base} = undef;

	return $this;
}

sub getFinalTypeWithTagger
{
	my $this		= shift;

	if (my $type = net::dryuf::uml::ModelStore::Primitive::checkPrimitive($this->{owner}, $this->{base})) {
		return ( $type, $this->{drytag}->cloneTagger() );
	}
	else {
		my ( $type, $tagger );
		eval {
			( $type, $tagger ) = $this->getSubModel($this->{base})->getFinalTypeWithTagger();
			$tagger->mergeReplacing($this->{drytag});
			1;
		}
			or $this->dieContext("failed to open final type", $@);
		return ( $type, $tagger );
	}
}

our %TYPEDEF_MAPPER = (
	%net::dryuf::uml::ModelStore::ClassBase::BASE_MAPPER,
	base			=> \&readTypedefDirect,
);

sub load
{
	my $this		= shift;
	my $reader		= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%TYPEDEF_MAPPER);

	$this->postLoad();
}

sub readTypedefDirect
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	$this->{$key} = $val;
}


package net::dryuf::uml::ModelStore::Enum;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::ClassBase";

sub new
{
	my $ref				= shift;
	my $class			= ref($ref) || $ref;

	my $owner			= shift;
	my $basic			= shift;

	my $this = $class->SUPER::new($owner, $basic);

	$this->{literal_list} = [];

	return $this;
}

sub getLiterals
{
	my $this			= shift;

	return $this->{literal_list};
}

our %ENUM_MAPPER = (
	%net::dryuf::uml::ModelStore::ClassBase::BASE_MAPPER,
	enum				=> \&readEnumLiteral,
);

sub load
{
	my $this			= shift;
	my $reader			= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%ENUM_MAPPER);

	$this->postLoad();
}

sub readEnumLiteral
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	my $enum = net::dryuf::uml::ModelStore::Enum::Literal->new($this, { name => $val });
	$enum->load($base->getSubLeveler());

	push(@{$this->{literal_list}}, $enum);
}


package net::dryuf::uml::ModelStore::Enum::Literal;

use strict;
use warnings;

sub new
{
	my $ref			= shift;
	my $class		= ref($ref) || $ref;

	my $owner		= shift;
	my $basic		= shift;

	my $this = bless {
		owner			=> $owner,
		name			=> $basic->{name},
		value			=> undef,
		comment			=> [],
		drytag			=> net::dryuf::uml::ModelStore::DryTag->new(),
	}, $class;

	Scalar::Util::weaken($this->{owner});

	return $this;
}

our %ENUM_LITERAL_MAPPER = (
	value			=> \&readDirect,
	comment			=> \&readComment,
	drytag			=> \&readDryTag,
);

sub load
{
	my $this		= shift;
	my $reader		= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%ENUM_LITERAL_MAPPER);

	$this->postLoad();
}

sub postLoad
{
	my $this		= shift;

	# no checks here
}

sub readDirect
{
	my $enum		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	$enum->{value} = $val;
}

sub readComment
{
	my $enum		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	push(@{$enum->{comment}}, net::dryuf::uml::Util::unescapeString($val));
}

sub readDryTag
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	$this->{drytag}->addTag(net::dryuf::uml::Util::unescapeString($val));
}

sub getDryTagger
{
	my $this		= shift;

	return $this->{drytag};
}


package net::dryuf::uml::ModelStore::AttrBase;

use strict;
use warnings;

sub new
{
	my $ref				= shift;
	my $class			= ref($ref) || $ref;

	my $owner			= shift;
	my $basic			= shift;

	my $this = bless {
		owner			=> $owner,
		name			=> $basic->{name},
		stype			=> $basic->{stype},
		mandatory		=> undef,
		transient		=> 0,
		comment			=> [],
		drytag			=> net::dryuf::uml::ModelStore::DryTag->new(),
	}, $class;

	Scalar::Util::weaken($this->{owner});

	return $this;
}

sub dieContext
{
	my $this			= shift;
	my $msg				= shift;
	my $cause			= shift;

	net::dryuf::uml::Util::doDie(((defined $cause)) ? "$this->{file_context}: $msg\n$cause" : "$this->{file_context}: $msg");
}

sub getRole
{
	my $this			= shift;

	if (!defined $this->{role}) {
		$this->{role} = {};
		if (defined (my $tag = $this->checkDryTagValue("role"))) {
			foreach my $r (split(/\s+/, $tag)) {
				$this->{role}->{$r} = 1;
			}
		}
		if (my $tag = $this->checkDryTagValue("primary")) {
			$this->{role}->{primary} = 1;
		}
	}

	return $this->{role};
}

sub isPrimary
{
	my $this			= shift;

	return !!$this->getRole()->{primary};
}

sub isTransient
{
	my $this			= shift;

	return $this->{transient};
}

sub getDryTagger
{
	my $this			= shift;

	return $this->{drytag};
}

sub getDryTag
{
	my $this			= shift;
	my $tag				= shift;

	eval {
		return $this->{drytag}->getTag($tag);
	}
		or $this->dieContext($@);
}

sub getDryTagValue
{
	my $this			= shift;
	my $tag				= shift;

	eval {
		return $this->{drytag}->getTagValue($tag);
	}
		or $this->dieContext($@);
}

sub checkDryTagValue
{
	my $this			= shift;
	my $tag				= shift;

	return $this->{drytag}->checkTagValue($tag);
}

sub getDrySpecs
{
	my $this			= shift;
	my $spec			= shift;

	return $this->{drytag}->getSpecs($spec);
}

our %MODEL_ATTRBASE_MAPPER = (
	drytag			=> \&readClassAttrDryTag,
	comment			=> \&readClassAttrComment,
	type			=> \&readClassAttrDirect,
	mandatory		=> \&readClassAttrDirect,
	default			=> \&readClassAttrDirect,
);

sub load
{
	my $this			= shift;
	my $reader			= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%MODEL_ATTRBASE_MAPPER);

	$this->postLoad();
}

sub postLoad
{
	my $this			= shift;

	net::dryuf::uml::Util::doDie("$this->{owner}->{full}.$this->{name}: mandatory undefined") unless (defined $this->{mandatory});

	$this->{transient} = $this->checkDryTagValue("transient") || 0;
}

sub readClassAttrDirect
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	$this->{$key} = $val;
}

sub readClassAttrDryTag
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	$this->{drytag}->addTag(net::dryuf::uml::Util::unescapeString($val));
}

sub readClassAttrComment
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	push(@{$this->{comment}}, net::dryuf::uml::Util::unescapeString($val));
}


package net::dryuf::uml::ModelStore::Attr;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::AttrBase";

use Data::Dumper;

sub getFinalTypeWithTagger
{
	my $this			= shift;

	my @r = eval {
		my ( $type, $tagger ) = $this->{owner}->getSubFinalTypeWithTagger($this->{name}, $this->{type});
		$tagger->mergeReplacing($this->{drytag});
		return ( $type, $tagger );
	};
	$this->dieContext("failed to process $this->{owner}->{full}.$this->{name}", $@) if ($@);
	return @r;
}


package net::dryuf::uml::ModelStore::AssocBase;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::AttrBase";

sub new
{
	my $ref			= shift;
	my $class		= ref($ref) || $ref;

	my $owner		= shift;
	my $basic		= shift;

	my $this = $class->SUPER::new($owner, $basic);

	$this->{ref} = undef;

	return $this;
}

sub getAssocPrefix
{
	my $this		= shift;

	return $this->{assoc_prefix};
}

sub getAssocTarget
{
	my $this		= shift;

	eval { return $this->{owner}->getSubModel($this->{ref}); }
		or $this->dieContext("failed to open final type", $@);
};

sub getFinalTypeWithTagger
{
	my $this		= shift;

	my @refs = $this->expandAssocAttrs();
	if (@refs != 1) {
		$this->dieContext("getFinalTypeWithTagger called on reference to not single field: $this->{name}");
	}

	my ( $type, $tagger ) = $refs[0]->{field}->getFinalTypeWithTagger();
	$tagger->mergeReplacing($this->{drytag});

	return ( $type, $tagger );
}

sub expandAssocAttrs
{
	our $deeprec_check = 0;

	my $this		= shift;

	if (++$deeprec_check%1024  == 0 && caller(1024)) {
		net::dryuf::uml::Util::doDie("deep recursion");
	}
	my $target = $this->getAssocTarget();
	my @primary = $target->getPrimary();
	$this->dieContext("no primary key for $target->{full}") unless (@primary);

	my @exp_primary;

	foreach my $pa (@primary) {
		if ($pa->{stype} eq "field") {
			push(@exp_primary, { name => (@primary == 1 ? $this->{name} : $pa->{name}), field => $pa });
		}
		elsif ($pa->{stype} eq "assoc" || $pa->{stype} eq "compos") {
			my @targ_exp = $pa->expandAssocAttrs();
			if (@targ_exp == 1) {
				push(@exp_primary, { name => (@primary == 1 ? $this->{name} : $pa->{name}), field => $targ_exp[0]->{field} });
			}
			else {
				#STDERR->print("$this->{owner}->{full}: adding $pa->{name} with multi\n");
				foreach my $tpa (@targ_exp) {
					push(@exp_primary, { name => ($pa->getAssocPrefix() || "").$tpa->{name}, field => $tpa->{field} });
				}
			}
		}
		else {
			$this->dieContext("invalid field stype: $pa->{stype}");
		}
	}

	return @exp_primary;
}

our %MODEL_ASSOCBASE_MAPPER = (
	%MODEL_ATTRBASE_MAPPER,
	ref			=> \&readClassAssocBaseRef,
);

sub postLoad
{
	my $this		= shift;

	net::dryuf::uml::Util::doDie("$this->{owner}->{full}.$this->{name}: ref undefined") unless (defined $this->{ref});

	if (defined ($this->{assoc_prefix} = $this->{drytag}->checkTagValue("assoc_prefix"))) {
		$this->{assoc_prefix} = "" if ($this->{assoc_prefix} eq "NULL");
	}

	$this->SUPER::postLoad();
}

sub load
{
	my $this		= shift;
	my $reader		= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%MODEL_ASSOCBASE_MAPPER);

	$this->postLoad();
}

sub readClassAssocBaseRef
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	$this->{ref} = $val;
}


package net::dryuf::uml::ModelStore::Assoc;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::AssocBase";


package net::dryuf::uml::ModelStore::Compos;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::AssocBase";


package net::dryuf::uml::ModelStore::Child;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::AssocBase";


package net::dryuf::uml::ModelStore::OperInfo;

use strict;
use warnings;

use net::dryuf::uml::Util qw(unescapeString);

sub new
{
	my $ref			= shift;
	my $class		= ref($ref) || $ref;

	my $owner		= shift;
	my $basic		= shift;

	my $this = bless {
		owner			=> $owner,
		name			=> $basic->{name},
		stype			=> $basic->{stype},
		comment			=> [],
		drytag			=> net::dryuf::uml::ModelStore::DryTag->new(),
	}, $class;

	Scalar::Util::weaken($this->{owner});

	return $this;
}

sub getDryTagger
{
	my $this		= shift;

	return $this->{drytag};
}

sub getDryTag
{
	my $this		= shift;
	my $tag			= shift;

	eval {
		return $this->{drytag}->getTag($tag);
	}
		or $this->dieContext($@);
}

sub getDryTagValue
{
	my $this		= shift;
	my $tag			= shift;

	eval {
		return $this->{drytag}->getTagValue($tag);
	}
		or $this->dieContext($@);
}

sub checkDryTagValue
{
	my $this		= shift;
	my $tag			= shift;

	return $this->{drytag}->checkTagValue($tag);
}

sub getDrySpecs
{
	my $this		= shift;
	my $spec		= shift;

	return $this->{drytag}->getSpecs($spec);
}

sub dieContext
{
	my $this		= shift;
	my $msg			= shift;
	my $cause		= shift;

	net::dryuf::uml::Util::doDie(((defined $cause)) ? "$this->{file_context}: $msg\n$cause" : "$this->{file_context}: $msg");
}

our %MODEL_OPERINFO_MAPPER = (
	drytag			=> \&readDryTag,
	comment			=> \&readComment,
);

sub postLoad
{
	my $this		= shift;
}

sub load
{
	my $this		= shift;
	my $reader		= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%MODEL_OPERINFO_MAPPER);

	$this->postLoad();
}

sub readComment
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	push(@{$this->{comment}}, net::dryuf::uml::Util::unescapeString($val));
}

sub readDryTag
{
	my $this		= shift;
	my $base		= shift;
	my $key			= shift;
	my $val			= shift;

	$this->{drytag}->addTag(net::dryuf::uml::Util::unescapeString($val));
}


package net::dryuf::uml::ModelStore::OperBase;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::OperInfo";

sub new
{
	my $ref				= shift;
	my $class			= ref($ref) || $ref;

	my $owner			= shift;
	my $basic			= shift;

	my $this = $class->SUPER::new($owner, $basic);
	$this->{classify} = {};

	return $this;
}

our %MODEL_OPERATIONBASE_MAPPER = (
	%MODEL_OPERINFO_MAPPER,
	classify		=> \&readClassify,
);

sub load
{
	my $this			= shift;
	my $reader			= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%MODEL_OPERATIONBASE_MAPPER);

	$this->postLoad();
}

sub readClassify
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	foreach (split(/,\s*/, $val)) {
		$this->{classify}->{$_} = 1;
	}
}

sub getReturnTypeWithTagger
{
	my $this			= shift;

	my @r = eval {
		my ( $type, $tagger ) = $this->{owner}->getSubFinalTypeWithTagger(undef, $this->{returntype});
		$tagger->mergeReplacing($this->{drytag});
		return ( $type, $tagger );
	};
	$this->dieContext("failed to process $this->{owner}->{full}.$this->{name}().returntype", $@) if ($@);
	return @r;
}

sub isStatic
{
	my $this			= shift;

	return $this->{classify}->{static} // 0;
}


package net::dryuf::uml::ModelStore::OperParam;

use strict;
use warnings;

sub new
{
	my $ref				= shift;
	my $class			= ref($ref) || $ref;

	my $owner			= shift;
	my $basic			= shift;

	my $this = bless {
		owner				=> $owner,
		name				=> $basic->{name},
		stype				=> $basic->{stype},
		mandatory			=> undef,
		comment				=> [],
		drytag				=> net::dryuf::uml::ModelStore::DryTag->new(),
	}, $class;

	Scalar::Util::weaken($this->{owner});

	return $this;
}

sub dieContext
{
	my $this			= shift;
	my $msg				= shift;
	my $cause			= shift;

	net::dryuf::uml::Util::doDie(((defined $cause)) ? "$this->{file_context}: $msg\n$cause" : "$this->{file_context}: $msg");
}

sub getDryTagger
{
	my $this			= shift;

	return $this->{drytag};
}

sub getDryTag
{
	my $this			= shift;
	my $tag				= shift;

	eval {
		return $this->{drytag}->getTag($tag);
	}
		or $this->dieContext($@);
}

sub getDryTagValue
{
	my $this			= shift;
	my $tag				= shift;

	eval {
		return $this->{drytag}->getTagValue($tag);
	}
		or $this->dieContext($@);
}

sub checkDryTagValue
{
	my $this			= shift;
	my $tag				= shift;

	return $this->{drytag}->checkTagValue($tag);
}

sub getDrySpecs
{
	my $this			= shift;
	my $spec			= shift;

	return $this->{drytag}->getSpecs($spec);
}

our %MODEL_OPERATIONPARAM_MAPPER = (
	drytag			=> \&readOperParamDryTag,
	comment			=> \&readOperParamComment,
	type			=> \&readOperParamDirect,
	mandatory		=> \&readOperParamDirect,
	default			=> \&readOperParamDirect,
	direction		=> \&readOperParamDirect,
);

sub load
{
	my $this			= shift;
	my $reader			= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%MODEL_OPERATIONPARAM_MAPPER);

	$this->postLoad();
}

sub postLoad
{
	my $this			= shift;
	my $reader			= shift;
}

sub readOperParamDirect
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	$this->{$key} = $val;
}

sub readOperParamDryTag
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	$this->{drytag}->addTag(net::dryuf::uml::Util::unescapeString($val));
}

sub readOperParamComment
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	push(@{$this->{comment}}, net::dryuf::uml::Util::unescapeString($val));
}

sub getFinalTypeWithTagger
{
	my $this			= shift;

	my @r = eval {
		my ( $type, $tagger ) = $this->{owner}->{owner}->getSubFinalTypeWithTagger($this->{name}, $this->{type});
		$tagger->mergeReplacing($this->{drytag});
		return ( $type, $tagger );
	};
	$this->dieContext("failed to process $this->{owner}->{owner}->{full}.$this->{owner}->{name}().$this->{name}", $@) if ($@);
	return @r;
}


package net::dryuf::uml::ModelStore::Oper;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::OperBase";

sub new
{
	my $ref				= shift;
	my $class			= ref($ref) || $ref;

	my $owner			= shift;
	my $basic			= shift;

	my $this = $class->SUPER::new($owner, $basic);

	$this->{returntype} = undef;
	$this->{param_list} = [];

	return $this;
}

our %MODEL_OPERATION_MAPPER = (
	%MODEL_OPERATIONBASE_MAPPER,
	return				=> \&readOperReturn,
	param				=> \&readOperParam,
);

sub load
{
	my $this			= shift;
	my $reader			= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%MODEL_OPERATION_MAPPER);

	$this->postLoad();
}

sub readOperReturn
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	$this->{returntype} = $val;
}

sub readOperParam
{
	my $this			= shift;
	my $base			= shift;
	my $key				= shift;
	my $val				= shift;

	my $param = net::dryuf::uml::ModelStore::OperParam->new($this, { stype => "param", name => $val });
	$param->load($base->getSubLeveler());

	push(@{$this->{param_list}}, $param);
}


package net::dryuf::uml::ModelStore::ActionBase;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::OperBase";

sub new
{
	my $ref				= shift;
	my $class			= ref($ref) || $ref;

	my $owner			= shift;
	my $basic			= shift;

	my $this = $class->SUPER::new($owner, $basic);

	return $this;
}

our %MODEL_ACTIONBASE_MAPPER = (
	%MODEL_OPERATIONBASE_MAPPER,
);

sub load
{
	my $this			= shift;
	my $reader			= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%MODEL_ACTIONBASE_MAPPER);

	$this->postLoad();
}


package net::dryuf::uml::ModelStore::Action;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::ActionBase";


package net::dryuf::uml::ModelStore::View;

use strict;
use warnings;

use base "net::dryuf::uml::ModelStore::OperInfo";

our %MODEL_VIEW_MAPPER = (
	%MODEL_OPERINFO_MAPPER,
);

sub load
{
	my $this		= shift;
	my $reader		= shift;

	$this->{file_context} = $reader->getContext();

	net::dryuf::uml::ModelStore::Util::genericLoad($this, $reader, \%MODEL_VIEW_MAPPER);

	$this->postLoad();
}


package net::dryuf::uml::ModelStore;

use strict;
use warnings;

use net::dryuf::uml::IndentReader;

sub new
{
	my $ref			= shift;
	my $class		= ref($ref) || $ref;
	my $default_location	= shift;

	my $this = bless {
		class_hash		=> {},
		fixiers			=> [],
		default_location	=> $default_location,
	}, $class;

	return $this;
}

sub createClass
{
	my $this		= shift;
	my $basic		= shift;

	if ($basic->{stype} eq "class") {
		return net::dryuf::uml::ModelStore::Class->new($this, $basic);
	}
	elsif ($basic->{stype} eq "typedef") {
		return net::dryuf::uml::ModelStore::Typedef->new($this, $basic);
	}
	elsif ($basic->{stype} eq "enum") {
		return net::dryuf::uml::ModelStore::Enum->new($this, $basic);
	}
	elsif ($basic->{stype} eq "association") {
		$basic->{stype} = "assoc";
		return net::dryuf::uml::ModelStore::Class->new($this, $basic);
	}
	else {
		die "unknown stype: $basic->{stype}";
	}
}

sub registerFixier
{
	my $this			= shift;
	my $sub				= shift;

	push(@{$this->{fixiers}}, $sub);
}

sub loadModel
{
	my $this			= shift;
	my $location			= shift;
	my $modelName			= shift;

	net::dryuf::uml::Util::doDie("modelName undefined") unless (defined $modelName);

	if (!defined $location) {
		if (!defined ($location = $this->{default_location})) {
			net::dryuf::uml::Util::doDie("no location nor default location specified while loading $modelName");
		}
	}
	$modelName =~ s/\./::/g;
	my $fname = $modelName;
	$fname =~ s/::/\//g;
	$fname = "$location/$fname";
	my $reader = net::dryuf::uml::IndentReader->new("$fname.clsdef")->getBaseLeveler();

	my $model;
	eval {
		my $package;
		my $name;
		my $stype;
		while (my ( $k, $v )= $reader->getPair()) {
			if ($k eq "package") {
				$package = $v;
			}
			elsif ($k eq "name") {
				$name = $v;
			}
			elsif ($k eq "stype") {
				$stype = $v;
			}
			else {
				die "unexpected key found while still missing basic information (package, name and stype): $k";
			}
			last if (defined $package && defined $name && defined $stype);
		}
		$model = $this->createClass({ filename => "$fname.clsdef", location => $location, package => $package, name => $name, stype => $stype });
		$model->load($reader);
		&$_($model) foreach (@{$this->{fixiers}});
		1;
	}
		or die "\n".$reader->getContext().": $@";

	return undef if ($model->checkDryTagValue("disabled"));

	return $model;
}

sub checkModel
{
	my $this			= shift;
	my $location			= shift;
	my $modelName			= shift;

	net::dryuf::uml::Util::doDie("modelName undefined") unless (defined $modelName);

	if (!defined $location) {
		if (!defined ($location = $this->{default_location})) {
			net::dryuf::uml::Util::doDie("no location nor default location specified while loading $modelName");
		}
	}
	$modelName =~ s/\./::/g;
	my $fname = $modelName;
	$fname =~ s/::/\//g;
	$fname = "$location/$fname.clsdef";
	return undef if (!-f $fname);

	return $this->loadModel($location, $modelName);
}


1;
