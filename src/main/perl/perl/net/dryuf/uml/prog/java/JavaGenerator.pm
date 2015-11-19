package net::dryuf::uml::prog::java::JavaGenerator;

use strict;
use warnings;

use Data::Dumper;
use net::dryuf::uml::Util qw(defvalue tabalign dumpSimple);
use net::dryuf::uml::prog::gen::ClikeGenerator qw(:CMT);

use base qw(net::dryuf::uml::prog::gen::ClikeGenerator);

our %JAVA_TAGS = (
	model_subs		=> CMT_LINE,
	type			=> CMT_LINE,
	shortcut		=> CMT_LINE,
);

sub new
{
	my $classname			= shift;

	my $this = $classname->SUPER::new(@_);
	$this->{shortcut} = {};
	$this->{pending} = [];
	$this->{imports} = {};
	$this->{package_name} = undef;
	$this->{class_name} = undef;

	return $this;
}

our %JAVA_UML_TYPES = (
	void				=> "void",
	string				=> "String",
	String				=> "String",
	binary				=> "byte[]",
	blob				=> "byte[]",
	int				=> "Integer",
	Integer				=> "Integer",
	long				=> "Long",
	Long				=> "Long",
	float				=> "Float",
	Float				=> "Float",
	double				=> "Double",
	Double				=> "Double",
	boolean				=> "Boolean",
	Boolean				=> "Boolean",
);

our %JAVA_UML_DATASTRUCT = (
	Collection			=> "java.util.Collection",
	List				=> "java.util.List",
	Map				=> "java.util.Map",
	Set				=> "java.util.Set",
);

our %JAVA_UML_PRIMITIVES = (
	void				=> 1,
	boolean				=> 1,
	byte				=> 1,
	short				=> 1,
	int				=> 1,
	long				=> 1,
	float				=> 1,
	double				=> 1,
);

our %JAVA_STYPES = (
	""				=> "AST_None",
	"primitive"			=> "AST_None",
	"assoc"				=> "AST_Reference",
	"compos"			=> "AST_Compos",
	"child"				=> "AST_Child",
);

sub isJavaTypePrimitive
{
	my $type			= shift;

	return exists $JAVA_UML_PRIMITIVES{$type};
}

# static
## converts virtual type to java type
sub mapJavaType # javaType-string <- modelType
{
	my $type			= shift;

	my $primtype = $type->{type};
	if (!defined $primtype) {
		return "int" if ($type->{stype} eq "enum");
		net::dryuf::uml::Util::doDie("primtype undefined for $type->{full}");
	}
	elsif ($primtype =~ m/^(\w+)\((\d+)\)$/) {
		if (my $javat = $JAVA_UML_TYPES{$1}) {
			return $javat;
		}
		net::dryuf::uml::Util::doDie("cannot map '$primtype'");
	}
	elsif (defined (my $javat = $JAVA_UML_TYPES{$primtype})) {
		return $javat;
	}
	elsif ($primtype =~ m/\./) {
		return $primtype;
	}
	else {
		net::dryuf::uml::Util::doDie("cannot map '$primtype'");
	}
}

# static
## converts virtual type to java type
sub mapJavaPlain # javaType-string <- baseModel elementTypeString
{
	my $baseModel			= shift;
	my $typeString			= shift;

	if ($typeString =~ m/^(\w+)\((\d+)\)$/) {
		if (my $javat = $JAVA_UML_TYPES{$1}) {
			return $javat;
		}
		net::dryuf::uml::Util::doDie("cannot map '$typeString'");
	}
	elsif (defined (my $javat = $JAVA_UML_TYPES{$typeString})) {
		return $javat;
	}
	elsif ($typeString =~ m/^\./) {
		return $baseModel->getSubModel($typeString)->getFullDotName();
	}
	elsif ($typeString =~ m/\./) {
		return $typeString;
	}
	else {
		net::dryuf::uml::Util::doDie("cannot map '$typeString'");
	}
}

# static
sub mapJavaDatastruct
{
	my $type			= shift;	# string

	if (exists $JAVA_UML_DATASTRUCT{$type}) {
		return $JAVA_UML_DATASTRUCT{$type};
	}
	else {
		net::dryuf::uml::Util::doDie("cannot map datastruct $type");
	}
}

# static
sub mapJavaAttrType
{
	my $field			= shift;

	net::dryuf::uml::Util::doDie("field is null") if (!defined $field);

	net::dryuf::uml::Util::doDie("Field does not support getFinalTypeWithTagger: ".ref($field)) unless (ref($field) && UNIVERSAL::can($field, 'getFinalTypeWithTagger'));
	my ( $atype, $atagger ) = $field->getFinalTypeWithTagger();

	return mapJavaType($atype);
}

sub translateJavaName
{
	my ( $typename )		= @_;

	$typename =~ s/::/./g;

	return $typename;
}

sub getPkTypeName
{
	my $clsmodel			= shift;

	my @primary = $clsmodel->getPrimary();

	my $usePk = @primary > 1;

	if ($usePk) {
		return $clsmodel->getFullDotName().".Pk";
	}
	else {
		my $field = $primary[0];
		my $java_type = $field->{ref} ? getPkTypeName($clsmodel->getSubModel($field->{ref})) : net::dryuf::uml::prog::java::JavaGenerator::mapJavaAttrType($field);
	}
}

sub getPkFieldName
{
	my $clsmodel			= shift;

	my @primary = $clsmodel->getPrimary();

	my $usePk = @primary > 1 || defined $clsmodel->checkCompos();

	if ($usePk) {
		return "pk";
	}
	else {
		my $field = $primary[0];
		return $field->{name};
	}
}

sub formatClassRoles
{
	my $clsmodel			= shift;

	my $roles = "";
	foreach my $roleName (qw(roleNew roleGet roleSet roleDel)) {
		my $role = $clsmodel->checkDryTagValue($roleName);
		if (!defined $role) {
			if (!$clsmodel->checkDryTagValue("virtual")) {
				net::dryuf::uml::Util::doDie("role $roleName not defined for ".$clsmodel->getFullDotName());
			}
			else {
				$role = "guest";
			}
		}
		$roles .= ", $roleName = \"".net::dryuf::uml::Util::escapeString($role)."\"";
	}
	return substr($roles, 2);
}

sub formatStype
{
	my $stype			= shift;

	return $JAVA_STYPES{$stype};
}

sub formatFieldRoles
{
	my $clsmodel			= shift;
	my $field			= shift;

	my $roles = "";
	foreach my $roleName (qw(roleNew roleGet roleSet roleDel)) {
		my $role;
		if (defined ($role = $field->checkDryTagValue($roleName))) {
			# use field role
		}
		elsif ($field->{stype} eq "compos" && ($roleName eq "roleNew" || $roleName eq "roleSet")) {
			$role = "_denied_";
		}
		elsif ($field->getRole()->{primary} && $roleName eq "roleSet") {
			$role = "_denied_";
		}
		elsif (defined ($role = $clsmodel->checkDryTagValue($roleName))) {
			# use the role from clsmodel
		}
		elsif (!$clsmodel->checkDryTagValue("virtual")) {
			net::dryuf::uml::Util::doDie("role $roleName not defined for ".$clsmodel->getFullDotName());
		}
		else {
			$role = "guest";
		}
		$roles .= ", $roleName = \"".net::dryuf::uml::Util::escapeString($role)."\"";
	}
	return substr($roles, 2);
}

sub formatBoolean
{
	my $value			= shift;

	return $value ? "true" : "false";
}

sub getFullClassname
{
	my $this			= shift;
	my $name			= shift;

	if (defined $this->{imports}->{$name}) {
		return $this->{imports}->{$name};
	}
	elsif ($name =~ m/^([a-z]+)\./) {
		return $name;
	}
	else {
		return "$this->{package}.$name";
	}
}

sub loadModel
{
	my $this			= shift;
	my $name			= shift;

	return $this->{model_store}->loadModel(undef, $this->getFullClassname($name));
}

sub openTargets
{
	my $this		= shift;

	return $this->{file_trans}->createTruncated("$this->{gen_dir}/$this->{in_fname}");
}

sub finish
{
	my $this		= shift;

	$this->SUPER::finish();
}

sub processLine
{
	my $this		= shift;
	my $line		= shift;

	if ($line =~ m/^package\s+((\w+\.)*\w+);/) {
		$this->{package_name} = $1;
		$this->printLine($line);
	}
	elsif ($line =~ m/^\s*import\s*((\S*)\.(\w+))\s*;\s*$/) {
		$this->processImport($line, $1);
	}
	elsif ($line =~ m,^\s*//,) {
		$this->printLine($line);
	}
	elsif ($line =~ m/^{/) {
		return $this->processClassStart($line);
	}
	elsif ($line =~ m/^}/) {
		return $this->processClassEnd($line);
	}
	elsif ($line =~ m/^\s*$/) {
		$this->printLine($line);
	}
	else {
		$this->{currentCtx} = $this->{out_main}->rememberContext();
		while ($line =~ m/^(.*?)DR_TYPEOF\(((\w+\.)*\w+)\.(\w+)\)(.*)$/s) {
			my ( $start, $type, $field, $end ) = ( $1, $2, $4, $5 );
			my $classmodel = $this->loadModel($type);
			my $translated = mapJavaAttrType($classmodel->getAttr($field));
			$line = "$start$translated$end";
		}
		if ($line =~ m/^((public|private|protected)\s+|)((abstract)\s+|)class\s+((\w+)(\s*<.*>)?)\s+extends\s+((\w+\.)*\w+(<([<a-zA-Z_0-9.]+|\?)(\s*,\s*([\w<]+|\?))*.*?>*>)?)(\s+implements\s+.*|)\s*$/) {
			$this->{class_name} = $6;
			$this->{class_typed} = $5;
			$this->{ancestor_name} = $8;
			$this->processClassDef($line);
		}
		elsif ($line =~ m/^((public|private|protected)\s+|)((abstract)\s+|)enum\s+((\w+)(\s*<.*>)?)\s*.*$/) {
			$this->{class_name} = $6;
			$this->{class_typed} = $5;
			$this->processClassDef($line);
		}
		elsif ($line =~ m/^((public|private|protected)\s+|)((abstract)\s+|)\@*interface\s+((\w+)(\s*<.*>)?).*$/) {
			$this->{class_name} = $6;
			$this->{class_typed} = $5;
			$this->processClassDef($line);
		}
		elsif ($line =~ m,^\s+.*\babstract\b\)\s*;\s*(//.*|/\*.*|)$,) {
			$this->processMethodAbstract($line);
		}
		elsif ($line =~ m,^\s+.*\)\s*;\s*(//.*|/\*.*|)$,) {
			$this->processMethodDef($line);
		}
		elsif ($line =~ m/^\s*((public|protected|private)\s+)*([a-zA-Z_.]+(<.*?>|\[\]|)*)\s+(\w+)(|\s*=.*);.*$/) {
			$this->processFieldDef($line);
		}
		else {
			$this->processRegularLine($line);
		}
	}

	return 0;
}

sub processCommentLine
{
	my $this		= shift;
	my $cmtag		= shift;
	my $content		= shift;

	if ($cmtag eq "shortcut") {
		if ($content !~ m/^(\w+)=(.+?)\s*$/) {
			$this->printError("wrong shortcut definition: $content");
			return 1;
		}
		$this->{shortcut}->{$1} = $2;
	}
	elsif ($cmtag eq "model_subs") {
	}
	else {
		$this->SUPER::processCommentLine($cmtag, $content);
	}

	return 0;
} 
sub processCommentBlock
{
	my $this		= shift;
	my $cmtag		= shift;
	my $head		= shift;
	my $block		= shift;

	if (0) {
	}
	else {
		$this->SUPER::processCommentBlock($cmtag, $head, $block);
	}

	return 0;
}

sub processCommentContinuous
{
	my $this		= shift;
	my $cmtag		= shift;
	my $head		= shift;
	my $block		= shift;

	if (0) {
	}
	else {
		$this->SUPER::processCommentContinuous($cmtag, $head, $block);
	}

	return 0;
}

sub processCommentSingle
{
	my $this		= shift;
	my $cmtag		= shift;
	my $content		= shift;

	if ($cmtag eq "getset") {
		foreach (split(/\s+/, $content)) {
			push(@{$this->{pending}}, { context => $this->getContext(), name => "getset", value => $_ });
		}
	}
	else {
		$this->SUPER::processCommentSingle($cmtag, $content);
	}

	return 0;
}

sub getCommentType
{
	my $this			= shift;
	my $cmtag			= shift;
	my $content			= shift;

	return exists $JAVA_TAGS{$cmtag} ? $JAVA_TAGS{$cmtag} : CMT_UNKNOWN;
}

sub processImport
{
	my $this			= shift;
	my $line			= shift;

	net::dryuf::uml::Util::doDie("did not find import specification: $line") unless ($line =~ m/^\s*import\s*((\S*)\.(\w+))\s*;\s*$/);
	$this->{imports}->{$3} = $1;
	$this->{currentCtx} = $this->{importCtx} = $this->{out_main}->rememberContext() if (!defined $this->{importCtx});
	$this->{importCtx}->printOnce("import $1;\n");

	return 0;
}

sub processClassDef
{
	my $this			= shift;
	my $line			= shift;

	$this->printLine($line);

	return 0;
}

sub processClassStart
{
	my $this			= shift;
	my $line			= shift;

	die "did not find class specification" unless (defined $this->{class_name});
	#die "did not find ancestor specification" unless (defined $this->{ancestor_name});
	die "did not find package specification" unless (defined $this->{package_name});

	$this->{class_started} = 1;

	$this->printLine($line);

	return 0;
}

sub processClassEnd
{
	my $this		= shift;
	my $line		= shift;

	die "did not find class start" unless ($this->{class_started});

	$this->printLine($line);

	return 0;
}

sub processMethodDef
{
	my $this		= shift;
	my $line		= shift;

	$this->printLine($line);

	return 0;
}

our %ATTR_TAGS = (
	getset			=> "processFieldDefGetset",
);

sub processFieldDef
{
	my $this		= shift;
	my $line		= shift;

	$this->dieContext($this->getContext(), "failed to match field definition: $line") unless ($line =~ m/^\s*((public|protected|private)\s+)*([a-zA-Z_.]+(<.*?>|\[\])*)\s+(\w+)(|\s*=.*);.*$/);
	my ( $atype, $aname ) = ( $3, $5 );

	$this->printLine($line);

	foreach my $pending (@{$this->{pending}}) {
		if (exists $ATTR_TAGS{$pending->{name}}) {
			my $func = $ATTR_TAGS{$pending->{name}};
			$this->$func($atype, $aname, $pending);
		}
		else {
			$this->dieContext($pending->{context}, "unknown tag $pending->{name}");
		}
	}
	$this->{pending} = [];
}

sub processFieldDefGetset
{
	my $this		= shift;
	my $atype		= shift;
	my $aname		= shift;
	my $oper		= shift;

	if ($oper->{value} eq "get") {
		$this->printLine("\n");
		$this->printIndented(tabalign("public $atype", 32)."get".ucfirst($aname)."()\n{\n\treturn this.$aname;\n}\n");
	}
	elsif ($oper->{value} eq "getsame") {
		$this->printLine("\n");
		$this->printIndented(tabalign("public $atype", 32).$aname."()\n{\n\treturn this.$aname;\n}\n");
	}
	elsif ($oper->{value} eq "getis") {
		$this->printLine("\n");
		$this->printIndented(tabalign("public $atype", 32)."is".ucfirst($aname)."()\n{\n\treturn this.$aname;\n}\n");
	}
	elsif ($oper->{value} eq "set") {
		$this->printLine("\n");
		$this->printIndented(tabalign("public void", 32)."set".ucfirst($aname)."($atype ${aname}_)\n{\n\tthis.$aname = ${aname}_;\n}\n");
	}
	elsif ($oper->{value} eq "setdot") {
		$this->printLine("\n");
		$this->printIndented(tabalign("public $this->{class_typed}", 32)."set".ucfirst($aname)."($atype ${aname}_)\n{\n\tthis.$aname = ${aname}_;\n\treturn this;\n}\n");
	}
	else {
		$this->dieContext($oper->{context}, "invalid value for getset generator: $oper->{value}");
	}
}

sub processEnd
{
	my $this		= shift;

	if (@{$this->{pending}}) {
		foreach my $pending (@{$this->{pending}}) {
			$this->dieContext($pending->{context}, "found unprocessed tag $pending->{name}");
		}
	}
}


1;
