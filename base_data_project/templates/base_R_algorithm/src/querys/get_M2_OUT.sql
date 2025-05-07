select * from wfm.core_pre_schedule_algorithm 
where EMPLOYEE_ID in (select codigo from wfm.esc_colaborador where matricula in :colabas )
and schedule_day between to_date(:d1,'yyyy-mm-dd') AND to_date(:d2,'yyyy-mm-dd')
and exclusion_date is null
