SELECT FK_UNIDADE   ,
    UNIDADE         ,
    FK_SECAO        ,
    SECAO           ,
    FK_TIPO_POSTO   ,
    TIPO_POSTO      ,
    DATA            ,
    WD              ,
    HORAS           ,
    HORAS_PESSOAS   
FROM WFM.CORE_ALG_HORASPESSOAS
WHERE FK_TIPO_POSTO = :p
AND DATA BETWEEN to_date(:i,'yyyy-mm-dd') AND to_date(:f,'yyyy-mm-dd')
