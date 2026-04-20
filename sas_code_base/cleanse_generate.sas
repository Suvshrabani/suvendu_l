%macro cleanse_generate;
/* Read the rules whcih apply to this table if any */
proc sort data=c_ctrl.cleanse_rules(where=(library="&library." and tablename="&tablename.")) out=cleanse_rules1; by ordinal; run;

/* Check that formats exist and are up to date if they are used for this table this */
%cleanse_check_formats;

proc sql;
create table cleanse_rules2 as
select a.*, b.id
from cleanse_rules1 a
left join c_cleans.formatlist b
on b.argument=a.argument and a.rule='dim'
order by a.ordinal
;
quit;

/* Generate cehck code */
data _null_;
length aux1 aux2 $10 str $1024;
set cleanse_rules2;
file rulelist mod;

aux1="";
aux2="";

put "cleanse_hit=0;";
put " ";

put "cleanse_field='" fieldname "';";
put "cleanse_rule='" rule "';";
put "cleanse_value=" fieldname ";";
/* Date check BEGIN*/
if strip(rule)="datecheck"
	then do;
	if strip(argument)='past' then aux1=" ge ";
	if strip(argument)='notpast' then aux1=" lt ";
	if strip(argument)='future' then aux1=" le ";
	if strip(argument)='notfuture' then aux1=" gt ";
	if strip(argument)='current' then aux1=" ne ";
	if strip(argument)='notcurrent' then aux1=" eq ";

	if aux1="" then do;
		str = "ERROR: Unknonw argument " || strip(argument) || " for rule datecheck";
		put str
		abort;
		end;

	put "if " fieldname aux1 " &active_date. then cleanse_hit=1;";
	end;
/* Date check END*/

/* Numeric range BEGIN */
if strip(rule)="range"
	then do;
	aux1=scan(" " || strip(argument) || " ", 1, ':');
	aux2=scan(" " || strip(argument) || " ", 2, ':');

	if strip(aux1) ne "" then put "if " fieldname " lt " aux1 " then cleanse_hit=1;";
	if strip(aux2) ne "" then put "if " fieldname " gt " aux2 " then cleanse_hit=1;";
	end;
/* Numeric range END */

/* Entity ID BEGIN */
if strip(rule)="entity_id"
	then do;
	put "cleanse_hit_a=0;";
	put "cleanse_hit_b=0;";

	put "if length(" fieldname ") ne 11 then cleanse_hit_a=1;";
	put "if substr(" fieldname ",7,1) not in ('+', '-', 'A') then cleanse_hit_a=1;";
	put "if input(substr(" fieldname ",1,6),ddmmyy6.) eq . then cleanse_hit_a=1;";
/*
TODO HETUTARKISTE 
0 	0 	16 	H
1 	1 	17 	J
2 	2 	18 	K
3 	3 	19 	L
4 	4 	20 	M
5 	5 	21 	N
6 	6 	22 	P
7 	7 	23 	R
8 	8 	24 	S
9 	9 	25 	T
10 	A 	26 	U
11 	B 	27 	V
12 	C 	28 	W
13 	D 	29 	X
14 	E 	30 	Y
15 	F
*/
	put "if length(" fieldname ") ne 9 then cleanse_hit_b=1;";
	put "if substr(" fieldname ",8,1) not in ('-') then cleanse_hit_b=1;";
	put "if input(substr(" fieldname ",1,7),7.) eq . then cleanse_hit_b=1;";

	if strip(argument) eq "person" then put "cleanse_hit=cleanse_hit_a;";
	if strip(argument) eq "corporate" then put "cleanse_hit=cleanse_hit_b;";
	if strip(argument) not in ("person" , "corporate") then put "cleanse_hit=cleanse_hit_a*clense_hit_b;";

	end;
/* Entity ID END */

/* Dimension check BEGIN */
if strip(rule)="dim"
	then do;
	aux1='F' || put(id,8.) || 'X';
	put "if put(" filedname "," aux1 ") eq '1' then cleanse_hit=1;";
	end;
/* Dimension check END; */

/* Value set BEGIN */
if strip(rule)="set_value"
	then do;
	str = fieldname || " = " || strip(argument) || ";";
	put str;
	end;
/* Value set END; */

/* raw code BEGIN */
if strip(rule)="condition_prove"
	then do;
	str = "if not (" || strip(argument) || ") then cleanse_hit=1;";
	put str;
	end;

if strip(rule)="condition_disprove"
	then do;
	str = "if (" || strip(argument) || ") then cleanse_hit=1;";
	put str;
	end;
/* raw code END; */

/* Set Empty value if BEGIN*/
if strip(rule)="set_empty_num"
	then do;
	str = "if (" || strip(argument) || ") then " || fieldname || " = . ;";
	put str;
	end;
	
if strip(rule)="set_empty_char"
	then do;
	str = 'if (' || strip(argument) || ') then ' || fieldname || ' = "" ;';
	put str;
	end;

/* Set Empty value if END;*/


put " ";
put "if cleanse_hit=1";
put "	then do;";
if error_is_suspect eq 'Y' then put "	output cleanse_suspect;";
if error_is_fatal eq 'Y' then put "	abort;";
if error_blocks eq 'Y' then put "	cleanse_block=1;";
put "	end;";
put " ";
run;

%mend;
