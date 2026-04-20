%macro register_metadata(library=,folder=,tables=);
%local selection;

%if ("&tables."="")
	%then %do;
	%let selection=;
	%end;
	%else %do;
	%let selection=select ( &tables. );
	%end;

/*Get the filepath for library - macro returns variable filepath as an output*/
%get_path_from_metalibref(lib=&library.);

	
/*To be able to update metadata, libname need to be set as native engine */	
libname &library. "&filepath.";

/*Update tables into library*/
proc metalib;
	omr(library="&library.");
	folder="&folder.";
	update_rule=(delete);
	&selection.;
run;

/*Set libname  back to the metadata engine*/
libname &library. meta library="&library." metaout=datareg;

%mend;
