libname DWI_HYPO '/sasdw/prod/dwh/data/int/hypo';

/* Borgo har M-1 förhållande för sina krediter mot säkerheterna. */
/* Flera avtal kan ha samma säkerhet, men ett avtal kan bara ha 1 säkerhet */
/* 13 månaders historik önskas */
proc sql;
  create table credits1 as
  select cred.information_date
        ,cred.account_id 					 
		,cred.account_number_official
        ,cred.account_type_cd           label='Distributör kod'          
        ,tpcd.description_internal_swe_txt as account_type_desc label='Distributör'
		/* Purpose blir default "MIGRATED" annars TAKEOVER, INCREASE mfl */
        ,coalesce(loan.application_purpose,'MIGRATED') as application_purpose label='Produkt' 
        /* Loan to value, kvot mellan lån och värde */
		,loan.ltv_system_ratio          label='LTV' 
        /* Bindningstid */
		,cred.ref_interest_fix_period_m	label='Bindningstid'	        

		,coalesce(cred.unmanaged_days_cnt,0) as unmanaged_days_cnt	label='Försenade betalningar'
		
        ,coll.object_type_cd 
        /* Villa, Bostadsrätt... */
        ,coll.object_type_txt label='Fastighetstyp'	     

	    /*	,coll.post_office_number finns bara för brf:er beställt för villor - översätt till län med lista om finns annars från nätet? */
		,coll.municipality_cd
		,coll.city
        ,compress(coalesce(post1.post_office_number_id,post2.post_office_number_id)) as post_office_number
        /* Snittränta */
		,cred.credit_interest_rate_pct		

        ,coll.market_value_amt as TOTAL_MV_COLLOBJ
		,link.internal_object_id as link_internal_object_id	
        ,coll.internal_object_id
        /* Utlåning */
		,cred.balance_amount				

		,sum(cred.balance_amount) as TotalObjectBalanceAmount 
		,cred.balance_amount/calculated TotalObjectBalanceAmount as CreditPartOfTotalBalAmt
		
		,count(*) as antalKrediterPerObjekt

  from dwi_hypo.bg_credit_list_HIST  as cred 
       left join dwi_hypo.dwi_loan_application as loan /* har historik */ 
         on  cred.external_application_id  = loan.application_id 
         and cred.information_date         = loan.information_date
       left join dwi_hypo.bg_credit_object_link as link  /* har historik */
         on  cred.account_id               = link.account_id 
         and cred.information_date         = link.information_date
       left join dwi_hypo.bg_collateral_object as coll  /* har historik */ 
         on  link.internal_object_id       = coll.internal_object_id
         and link.information_date         = coll.information_date

left join dwh_dw.real_property_swe_object as post1
on link.internal_object_id=cat(post1.bank_id,post1.internal_object_id) 
and link.information_date = post1.information_date
and coll.object_type_cd in ('113S' '116S')

left join dwh_dw.housing_object as post2
on link.internal_object_id=cat(post2.bank_id,post2.internal_object_id) 
and link.information_date = post2.information_date
and coll.object_type_cd in ('224')

	   left join dwh_dw.account_types as tpCd
	     on  intnx('Month',cred.information_date,-1,'END') = tpcd.information_date 
		 and cred.account_type_cd          = tpcd.account_type
  group by cred.information_date, link.internal_object_id
  having cred.information_date >= intnx('Month', today(),-13,'S') and 
         cred.information_date >= '10dec2021'd /*10 dec start date*/ ;
quit;
* Finns ingen ansökningsdata för lån som migrerats över (594 el 591) då ansökan bara finns på papper från upplägg hos ÅAB * ;


proc sql;
  create table credits2a as
  select credits1.*
        ,CreditPartOfTotalBalAmt*TOTAL_MV_COLLOBJ as MV_PER_CREDIT
		,(abs(balance_amount)/calculated MV_PER_CREDIT) * 100 as LTV
        ,max(p.county_name) as countyPart1
  from credits1 left join
       (select distinct post_office_number, municipality_cd, county_name 
        from dw_play.post_office_swe(where=(information_date = '31mar2022'd))) p
       on credits1.post_office_number=p.post_office_number and credits1.municipality_cd=p.municipality_cd
       group by information_Date, account_id, internal_object_id;
quit;

proc sql;
  create table credits2b as
  select C.*
        ,coalesce(C.countyPart1, P.county_name) as county_name
  from credits2a C left join
       (select distinct post_office_number, post_office_name, county_name 
        from dw_play.post_office_swe(where=(information_date = '31mar2022'd))) p
       on compress(C.post_office_number)=p.post_office_number and C.city=p.post_office_name
       order by information_Date, account_id, internal_object_id;
quit;

proc sort data=dwi_hypo.dwi_account_owners (where=(information_date >= intnx('Month', today(),-13,'S')))
          out=accOwn;
  by information_date account_id descending main_account_owner_flag;
run;

proc transpose data=accOwn
               out= trans_owner (drop=_name_ _label_) 
               prefix=OWNER;
  by information_date account_id;
  var owner_id;
run;

proc sql;
  create table DWI_HYPO.BG_CREDIT_VOLUME as 
  select cred.information_date         
        ,cred.account_id 				label='Account ID' 
		,cred.account_number_official   label='Account number'
		,cred.internal_object_id        label='ObjektID Säkerhet'
        ,cred.account_type_cd           label='Distributörskod'      
        ,cred.account_type_desc         label='Distributör' 
        ,cred.application_purpose       label='Produkt'			       
		,cred.ltv                       label='LTV'                    
		,cred.ref_interest_fix_period_m	label='Bindningstid'	     
        ,cred.credit_interest_rate_pct	label='Snittränta'             
		,cred.balance_amount			label='Utlåning'               
		,cred.mv_per_credit             label='Market value on credit'
		,cred.unmanaged_days_cnt		label='Försenade betalningar' 
        ,cred.object_type_txt			label='Fastighetstyp'		   
		,cred.county_name               label='Län'
		,cred.post_office_number		label='Postnummer'  /* Ska ej ingå i slutfil: finns bara för brf:er beställt för villor 
		                                                      - översätt till län med lista om finns annars från nätet? */
        ,own.owner1                     label='Låntagare 1'
        ,own.owner2                     label='Låntagare 2'
  from credits2b as cred left join trans_owner as own
       on  cred.account_id       = own.account_id
	   and cred.information_date = own.information_date
  order by cred.information_date;
quit;

proc datasets lib=work nolist;
  delete accown trans_owner credits1 credits2a credits2b ;
run;quit;