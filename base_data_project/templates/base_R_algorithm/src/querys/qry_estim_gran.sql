SELECT FK_SECAO,
       WD,
       FK_UNIDADE,
       UNIDADE,
       SECAO,
       FK_TIPO_POSTO,
       TIPO_POSTO,
       DATA,
       HORA_INI,
       PESSOAS_ESTIMADO,
       PESSOAS_MIN,
       PESSOAS_FINAL
FROM WFM.CORE_ALG_GRANULARIDADE
WHERE FK_TIPO_POSTO = :p
    AND DATA BETWEEN to_date(:i,'yyyy-mm-dd') AND to_date(:f,'yyyy-mm-dd')
