********************************;
*macro code_converter_prepare	;
*								;
*Usage: 						;
********************************;
%macro code_converter_prepare(table);
	data cc_for_&table. (keep = bank_id internal_value_clause_final internal_value_prio target_column when_part); 
		set mac_ctrl.par_code_converter_h (where=(information_date = &active_date.));
		/*Select data*/
		if lowcase(target_table) = lowcase("&table.");
		if lowcase(internal_value_type) in ('char' 'num' 'clause' 'data' 'formula');

		/*Form expressions*/
		attrib when_part length=$200.;
		attrib internal_value_clause_temp data_value_clause length=$200.;
		attrib internal_value_clause_final length=$400.;

		if lowcase(internal_value_type) in ('data') then do;
			data_value_clause="if bank_id='"||trim(left(bank_id))||"' then "||trim(left(target_column))||"="||trim(left(internal_column))||";";
		end;

		if lowcase(internal_value_type) in ('formula') then do;
			data_value_clause="if bank_id='"||trim(left(bank_id))||"' then "||trim(left(target_column))||"="||trim(left(internal_value_clause))||";";
		end;

		if lowcase(internal_value_type) in ('char') then do;
			internal_value_clause_temp="bank_id='"||trim(left(bank_id))||"' and "||trim(left(internal_column))||"='"||trim(left(internal_value_char))||"'";
		end;

		if lowcase(internal_value_type) in ('clause') and internal_value_clause ne '' then do;
			internal_value_clause_temp="bank_id='"||trim(left(bank_id))||"' and "||trim(left(internal_value_clause));
		end;

		if lowcase(internal_value_type) in ('num') and internal_value_num ne . then do;
			internal_value_clause_temp="bank_id='"||trim(left(bank_id))||"' and "||trim(left(internal_column))||'='||trim(left(internal_value_num));
		end;

		if lowcase(internal_value_type) in ('num') and internal_value_num =. and internal_value_num_start ne . and internal_value_num_end ne . then do;
			internal_value_clause_temp="bank_id='"||trim(left(bank_id))||"' and "||trim(left(internal_value_num_start))||'<='||trim(left(internal_column))||'<='||trim(left(internal_value_num_end));
		end;

		if code_value_num = . and code_value_char not in ('',' ') then do;
			when_part=trim(left(target_column))||"='"||trim(left(code_value_char))||"'";
		end;

		if code_value_num ne . and code_value_char in ('',' ') then do;
			when_part=trim(left(target_column))||"="||trim(left(put(code_value_num, 8.)));
		end;

		/*IEr 14.5.2018: clause and formula combination*/
		if lowcase(internal_value_type) in ('clause') and internal_column ne '' then do;
			when_part=trim(left(target_column))||"="||trim(left(internal_column));
		end;

		if lowcase(internal_value_type) ne ('formula') and internal_value_clause_temp ne '' 
				   then internal_value_clause_final='if '||trim(left(internal_value_clause_temp))||' then '||trim(left(when_part))||';';
		if internal_value_clause_final='' and data_value_clause ne '' then internal_value_clause_final=data_value_clause;

		if internal_value_prio=. then internal_value_prio=1;

	run;
%mend;
