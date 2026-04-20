%macro read_index_metadata(metapath);
data indexlist;
  length uri index_uri $256 rc n type 8.;
  rc=metadata_pathobj("","&metapath.","",type,uri);
  put "Metadata resolver returncode=" rc;
  n=1;
  do while (rc>0) ;
	rc=metadata_getnasn(uri,"Indexes",n,index_uri);
	if rc>0 then output;
	n=n+1;
  end;
  keep index_uri;
run;

data metaindex;
  length index_keys $300 /*IER 15.7.2019:increased size from $256 -> $300*/
		creator $256
		rc rc2 n 8.
		index_name key_name $32
		is_uniq $2
		key_uri $256 
		;
  set indexlist;
  rc=metadata_getattr(index_uri, "IndexName", index_name);
  put "Metadata resolver returncode=" rc;
  rc=1;
  n=1;
  do while (rc>0) ;
	rc=metadata_getnasn(index_uri, "Columns", n, key_uri);
	put rc=;
	if rc>0 then do;
		rc2=metadata_getattr(key_uri, "Name", key_name);
		index_keys=strip(index_keys) || ' ' || key_name;
		end;
	n=n+1;
  end;
  rc3=metadata_getattr(index_uri, "IsUnique", is_uniq);
  keep index_name index_keys is_uniq ;
run;

data _null_;
if _indexcount=0
	then do;
	put "!!!!!!!!!!!!!!!!!!!!!!!";
	put "NO INDEXDATA FOUND FOR";
	put "&metapath.";
	put "!!!!!!!!!!!!!!!!!!!!!!!";
	abort abend;
	end;
	
set metaindex nobs=_indexcount;
run;

proc datasets nolist library=work;
delete indexlist;
run; quit;
%mend;
