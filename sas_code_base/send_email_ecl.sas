* -- Macro for sending email that a step in ECL run is done. Date should have format findfdd10 (dd.mm.yyyy). -- ;
%macro send_email_ecl(eclpart=, step=, perdate_fin=, msg=, to=, cc=);

  filename myemail email
    subject = "&eclpart per &perdate_fin"
    from    = "data@alandsbanken.fi"
    to      = (&to)
    cc      = (&cc)
    type    = 'Text/Plain';

  data _null_;
    file myemail;
    put "Hej,";
    put "&eclpart steg &step är klart:";
    put "&msg";
    put "Hälsningar,";
    put "BI & DW";
  run;

%mend send_email_ecl;

* -- Example -- ;
*%send_email_ecl(eclpart     = MEH, 
                step        = 5,
                perdate_fin = &fin_date,
                msg         = batch 02 har laddat dm-tabellerna.,
                to          = "emilio.bergroth@alandsbanken.fi", 
                cc          = "anna.debren@alandsbanken.fi" "riskcontrolaabfi2@alandsbanken.fi" "data@alandsbanken.fi");