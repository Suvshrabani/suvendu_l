%macro unify_datastructure(input_data_1=,input_data_2=,output_data=);

proc contents noprint data=&input_data_1. out=source_1a noprint ; run;
proc contents noprint data=&input_data_2. out=source_2a noprint ; run;

data source_1b;
set source_1a;
length informatstr formatstr $50.;
if strip(format) eq ''
	then do;
	formatstr='';
	end;
	else do;
	formatstr=strip(format);
	if formatl ne 0 then formatstr=compress(formatstr || put(formatl,8.) || '.' || put (formatd,8.));
	if type=2 then formatstr='$' || strip(formatstr);
	end;

if strip(informat) eq ''
	then do;
	informatstr='';
	end;
	else do;
	informatstr=strip(informat);
	if informl ne 0 then informatstr=compress(informatstr || put(informl,8.) || '.' || put (informd,8.));
	if type=2 then informatstr='$' || strip(informatstr);
	end;
run;

data source_2b;
set source_2a;
length informatstr formatstr $50.;
if strip(format) eq ''
	then do;
	formatstr='';
	end;
	else do;
	formatstr=strip(format);
	if formatl ne 0 then formatstr=compress(formatstr || put(formatl,8.) || '.' || put (formatd,8.));
	if type=2 then formatstr='$' || strip(formatstr);
	end;

if strip(informat) eq ''
	then do;
	informatstr='';
	end;
	else do;
	informatstr=strip(informat);
	if informl ne 0 then informatstr=compress(informatstr || put(informl,8.) || '.' || put (informd,8.));
	if type=2 then informatstr='$' || strip(informatstr);
	end;
run;

proc sql noprint ;
create table combined_1 as

select	coalescec(s.name, t.name) as name,
		max(s.length,t.length) as length,
		s.type as s_type, t.type as t_type, coalesce(t.type, s.type) as  type,
		coalescec(t.informatstr, s.informatstr) as informatstr,
		coalescec(t.formatstr, s.formatstr) as formatstr,
		coalesce(t.varnum, s.varnum) as varnum

from source_1b as s
full join source_2b as t
on upcase(s.name)=upcase(t.name)
order by varnum
;
quit;

filename attribs temp;

data combined_2;
  length attribstr $300.;
  set combined_1;
  file attribs ;
  if (s_type ne t_type) and (s_type ne . and t_type ne . ) and not (substr(name,1,3)='_AT')
	then do;
	file log ;
	put "ERROR: datatype of field " name " is different on source and target tables";
	abort abend;
	end;
  if type=2 then attribstr=strip(name) || ' length=$' || strip(put(length,4.)) ;
  else attribstr=strip(name) || ' length=' || strip(put(length,4.)) ;
  if formatstr ne ' ' then attribstr=attribstr || ' format=' || strip(formatstr) ;
  if informatstr ne ' ' then attribstr=attribstr || ' informat=' || strip(informatstr) ;
  put attribstr;
run;

data	&output_data.;
attrib 
%include attribs;
; 
set		&input_data_1.
		&input_data_2.
		;
run;

%mend ;
