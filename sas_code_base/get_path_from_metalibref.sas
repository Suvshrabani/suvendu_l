%macro get_path_from_metalibref(lib=,outvar=filepath);
   data _null_;
      putlog "NOTE: Getting physical path for &lib library";
      length lib_uri up_uri filepath $256;
      call missing (of _all_);
      /* get URI for the particular library */
      rc1=metadata_getnobj("omsobj:SASLibrary?@Libref ='&lib'",1,lib_uri);
      put rc1= lib_uri= ;
      /* get first object of the UsingPackages association (assumed to be Path) */
      rc2=metadata_getnasn(lib_uri,'UsingPackages',1,up_uri);
      put rc2= up_uri= ;
      /* get the DirectoryName attribute of the previous object */
      rc3=metadata_getattr(up_uri,'DirectoryName',filepath);
      put rc3= filepath=;
      call symputx("&outvar",filepath,'g');
   run;
%mend;
