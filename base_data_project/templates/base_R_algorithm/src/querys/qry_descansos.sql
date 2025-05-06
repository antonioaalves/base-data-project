SELECT cas.FK_EMP, ec.codigo, cas.DATA, cas.TIPO_TURNO, cas.FK_TIPO_POSTO_ORIGEM 
FROM WFM.CORE_ALGORITHM_SCHEDULE cas
inner join WFM.ESC_COLABORADOR ec
    on cas.fk_emp = ec.matricula 
WHERE 1=1
AND DATA BETWEEN to_date(:i,'yyyy-mm-dd') AND to_date(:f,'yyyy-mm-dd')