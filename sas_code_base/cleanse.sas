%macro cleanse(source, target, library, tablename);

data	&target.;
set		&source.;
run;
%mend;