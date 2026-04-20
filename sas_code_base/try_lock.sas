
%macro try_lock(target=, retry=60, alert=30);
%local starttime;
%global lock_result;
%let starttime = %sysfunc(datetime());

lock &target.;

%if (&retry eq 0)
           %then %do;

           %do %until (&syslckrc. le 0) ;
                      data _null_; x=sleep(10); run;
                      lock &target.;

                      %if (&syslckrc. gt 0 and %sysfunc(datetime()) gt %sysevalf(&starttime. + &alert.) )
                                 %then %do;
                                 x "Echo 'Lock not successfull for &target. after &alert. attempts' | mailx -s 'Lock failure' katja.palojoki@aureolis.com" 
                                 %end;
                      %end;

           %end;

           %else %do;

           %do %until (&syslckrc. le 0 or %sysfunc(datetime()) gt %sysevalf(&starttime. + &retry.) ) ;
                      data _null_; x=sleep(10); run;
                      lock &target.;

                                 %if (&syslckrc. gt 0 and %sysfunc(datetime()) gt %sysevalf(&starttime. + &alert.) )
                                 %then %do;
                                 x "Echo 'Lock not successfull for &target. after &alert. attempts' | mailx -s 'Lock failure' katja.palojoki@aureolis.com" 
                                 %end;
                      %end;

           %end;

%put lock_result=&syslckrc.;
%let lock_result=&syslckrc.;

%mend;


/*
T‰m‰ %trylock(target=dw_dw.jokutaulu);
Yritt‰‰ 10 sekunnin v‰lein lukita dw_dw.jokutaulua. uovuttaa 60 skunnin kuluttua ja alkaa l‰hett‰m‰‰n minulle mieli‰ 30 sekunnin kuluttua

Jos ei haluta ikin‰ luovuttaa niin kutsutaan n‰in
%trylock(target=dw_dw.jokutaulu, retry=0);

Ja jos halutaan ett‰ meili‰ l‰htee vasta esim. tunnin yritt‰misen j‰lkeen niin n‰in
%trylock(target=dw_dw.jokutaulu, retry=0, alert=3600);

Makrokoodi alla. En liattanut mihink‰‰n ymp‰ristˆˆn viel‰.
Kun makrolooppi p‰‰ttyy nin se tallentaa paluuarvon lock_result nimiseen muuttujaan

0 tarkoittaa, ett‰ taul ulukittiin
negatiivinen arvo sit‰, ett‰ taulu oli jo ennest‰‰n t‰ll‰ prosessilla lukossa
positiivinen arvo on lukitsevan prosesin PID, jos taulu oli jo jollain muulla lukossa.
*/
