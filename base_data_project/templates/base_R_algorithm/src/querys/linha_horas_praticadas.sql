SELECT
    t.fk_unidade,
    t.fk_secao,
    t.fk_tipo_posto,
    t.dia_semana,
    t.dia_semana_numero,
    to_char(t.data_inicial, 'YYYY-MM-DD') AS data_inicial,
    to_number(to_char(t.data_inicial, 'WW')) week,
    to_char(t.hora_inicio, 'YYYY-MM-DD HH24:MI') hora_inicio,
    nvl(t.alocado, 0) alocado
FROM
    (
        SELECT
            fk_unidade,
            unidade,
            fk_secao,
            secao,
            tipo_posto,
            fk_tipo_posto,
            TRIM(to_char(data, 'DAY', 'nls_date_language=Portuguese')) AS dia_semana,
            to_char(data, 'd') AS dia_semana_numero,
            CASE
                WHEN to_char(hora, 'ddmmyyyy') = '02012000' THEN
                    to_char(data + 1, 'YYYY-MM-DD', 'nls_date_language=portuguese')
                ELSE
                    to_char(data, 'YYYY-MM-DD', 'nls_date_language=portuguese')
            END data,
            data   data_inicial,
            hora   AS hora_inicio,
            alocado
        FROM
            (
                SELECT
                    fk_unidade,
                    unidade,
                    fk_secao,
                    secao,
                    tipo_posto,
                    fk_tipo_posto,
                    data,
                    hora,
                    alocado
                FROM
                    (
                        SELECT
                            temp_ideal.fk_secao,
                            temp_ideal.secao,
                            temp_ideal.fk_unidade,
                            temp_ideal.unidade,
                            temp_ideal.tipo_posto,
                            temp_ideal.fk_tipo_posto,
                            temp_ideal.data,
                            temp_ideal.hora,
                            SUM(nvl(alocado.total_alocado, 0)) alocado,
                            0 registro,
                            0 total_registros
                        FROM
                            (
                                SELECT
                                    fk_secao,
                                    secao,
                                    unidade,
                                    fk_unidade,
                                    tipo_posto,
                                    fk_tipo_posto,
                                    data,
                                    hora
                                FROM
                                    (
                                        SELECT
                                            fk_secao,
                                            secao,
                                            unidade,
                                            fk_unidade,
                                            tipo_posto,
                                            fk_tipo_posto,
                                            data,
                                            hora
                                        FROM
                                            (
                                                SELECT
                                                    pi.fk_secao,
                                                    es.nome      secao,
                                                    eu.nome      unidade,
                                                    eu.codigo    fk_unidade,
                                                    (
                                                        SELECT
                                                            nome
                                                        FROM
                                                            esc_tipo_posto
                                                        WHERE
                                                            codigo = pi.fk_tipo_posto
                                                    ) AS tipo_posto,
                                                    pi.fk_tipo_posto,
                                                    pi.data,
                                                    pi.horario   hora
                                                FROM
                                                    esc_tmp_pdv_ideal   pi,
                                                    esc_secao           es,
                                                    esc_unidade         eu
                                                WHERE
                                                    pi.fk_secao = es.codigo
                                                    AND es.fk_unidade IN (
                                                        :u
                                                    )
                                                    AND pi.fk_secao IN (
                                                        SELECT
                                                            codigo
                                                        FROM
                                                            esc_secao
                                                        WHERE
                                                            fk_unidade IN (
                                                                :u
                                                            )
                                                    )
                                                    AND es.fk_unidade = eu.codigo
                                                    AND pi.data between to_date(:i, 'YYYY-MM-DD') and to_date(:f, 'YYYY-MM-DD')
                                                    AND 1=1
                                                GROUP BY
                                                    es.nome,
                                                    eu.nome,
                                                    eu.codigo,
                                                    pi.fk_secao,
                                                    pi.fk_tipo_posto,
                                                    pi.data,
                                                    pi.horario
                                            )
                                    )
                                /*WHERE
                                    sum_ideal > 0*/
                            ) temp_ideal
                            LEFT JOIN (
                                SELECT DISTINCT
                                    all_colab.granularidade,
                                    all_colab.fk_secao,
                                    all_colab.fk_tipo_posto_ori,
                                    all_colab.data,
                                    all_hors.hora,
                                    nvl(SUM(
                                        CASE
                                            WHEN all_colab.tipo = 'T'
                                                 AND all_colab.poli_status = 1
                                                 AND((all_hors.hora >= all_colab.hora_ini
                                                      AND all_hors.hora < all_colab.hora_fim)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint
                                                        AND all_hors.hora < all_colab.hora_fim_cint)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint_ext
                                                        AND all_hors.hora < all_colab.hora_fim_cint_ext)) THEN
                                                1
                                            WHEN all_colab.tipo = 'T'
                                                 AND all_colab.poli_status = - 1
                                                 AND((all_hors.hora >= all_colab.hora_ini
                                                      AND all_hors.hora < all_colab.hora_fim)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint
                                                        AND all_hors.hora < all_colab.hora_fim_cint)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint_ext
                                                        AND all_hors.hora < all_colab.hora_fim_cint_ext)) THEN
                                                - 1
                                            WHEN all_colab.tipo = 'T'
                                                 AND all_colab.poli_status = 0
                                                 AND all_colab.poli_secao_status = 0
                                                 AND((all_hors.hora >= all_colab.hora_ini
                                                      AND all_hors.hora < all_colab.hora_fim)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint
                                                        AND all_hors.hora < all_colab.hora_fim_cint)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint_ext
                                                        AND all_hors.hora < all_colab.hora_fim_cint_ext)) THEN
                                                1
                                            WHEN all_colab.tipo = 'T'
                                                 AND all_colab.poli_status = 0
                                                 AND all_colab.poli_secao_status = 1
                                                 AND ctrl = 0
                                                 AND((all_hors.hora >= all_colab.hora_ini
                                                      AND all_hors.hora < all_colab.hora_fim)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint
                                                        AND all_hors.hora < all_colab.hora_fim_cint)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint_ext
                                                        AND all_hors.hora < all_colab.hora_fim_cint_ext)) THEN
                                                1
                                            WHEN all_colab.tipo = 'T'
                                                 AND all_colab.poli_status = 0
                                                 AND all_colab.poli_secao_status = 1
                                                 AND ctrl = - 1
                                                 AND((all_hors.hora >= all_colab.hora_ini
                                                      AND all_hors.hora < all_colab.hora_fim)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint
                                                        AND all_hors.hora < all_colab.hora_fim_cint)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint_ext
                                                        AND all_hors.hora < all_colab.hora_fim_cint_ext)) THEN
                                                - 1
                                            WHEN all_colab.tipo = 'P'
                                                 AND((all_hors.hora >= all_colab.hora_ini
                                                      AND all_hors.hora < all_colab.hora_fim)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint
                                                        AND all_hors.hora < all_colab.hora_fim_cint)
                                                     OR(all_hors.hora >= all_colab.hora_ini_cint_ext
                                                        AND all_hors.hora < all_colab.hora_fim_cint_ext)) THEN
                                                - 1
                                        END
                                    ) OVER(
                                        PARTITION BY all_colab.granularidade, all_colab.fk_secao, all_colab.fk_tipo_posto_ori, all_colab
                                        .data, all_hors.hora
                                    ), 0) total_alocado
                                FROM
                                    (
                                        SELECT
                                            granularidade,
                                            fk_colaborador,
                                            fk_secao fk_secao_ctrl,
                                            CASE
                                                WHEN fk_secao_poli IN (
                                                    SELECT
                                                        codigo
                                                    FROM
                                                        esc_secao
                                                    WHERE
                                                        fk_unidade IN (
                                                            :u
                                                        )
                                                )
                                                     AND ctrl = 0 THEN
                                                    fk_secao_poli
                                                ELSE
                                                    fk_secao
                                            END fk_secao,
                                            CASE
                                                WHEN fk_secao_poli IN (
                                                    SELECT
                                                        codigo
                                                    FROM
                                                        esc_secao
                                                    WHERE
                                                        fk_unidade IN (
                                                            :u
                                                        )
                                                )
                                                     AND ctrl = 0 THEN
                                                    fk_tipo_posto
                                                ELSE
                                                    nvl(fk_tipo_posto_ori, fk_tipo_posto)
                                            END fk_tipo_posto_ori,
                                            data,
                                            hora_ini,
                                            hora_fim,
                                            hora_ini_cint,
                                            hora_fim_cint,
                                            hora_ini_cint_ext,
                                            hora_fim_cint_ext,
                                            tipo,
                                            ctrl,
                                            CASE
                                                WHEN fk_secao <> fk_secao_poli
                                                     AND fk_secao IN (
                                                    SELECT
                                                        codigo
                                                    FROM
                                                        esc_secao
                                                    WHERE
                                                        fk_unidade IN (
                                                            :u
                                                        )
                                                )
                                                     AND fk_secao_poli IN (
                                                    SELECT
                                                        codigo
                                                    FROM
                                                        esc_secao
                                                    WHERE
                                                        fk_unidade IN (
                                                            :u
                                                        )
                                                ) THEN
                                                    1
                                                ELSE
                                                    0
                                            END poli_secao_status,
                                            CASE
                                                WHEN fk_secao = nvl(fk_secao_poli, fk_secao)
                                                     OR fk_secao_poli IN (
                                                    SELECT
                                                        codigo
                                                    FROM
                                                        esc_secao
                                                    WHERE
                                                        fk_unidade IN (
                                                            :u
                                                        )
                                                ) THEN
                                                    CASE
                                                        WHEN fk_secao_poli = fk_secao
                                                             AND fk_tipo_posto <> fk_tipo_posto_ori and ctrl = 0 THEN
                                                            0
                                                        WHEN fk_secao_poli = fk_secao
                                                             AND fk_tipo_posto <> fk_tipo_posto_ori and ctrl = -1 THEN
                                                            -1
                                                        WHEN fk_secao <> fk_secao_poli
                                                             AND fk_secao IN (
                                                            SELECT
                                                                codigo
                                                            FROM
                                                                esc_secao
                                                            WHERE
                                                                fk_unidade IN (
                                                                    :u
                                                                )
                                                        )
                                                             AND fk_secao_poli NOT IN (
                                                            SELECT
                                                                codigo
                                                            FROM
                                                                esc_secao
                                                            WHERE
                                                                fk_unidade IN (
                                                                    :u
                                                                )
                                                        ) THEN
                                                            - 1
                                                        WHEN fk_secao <> fk_secao_poli
                                                             AND fk_secao IN (
                                                            SELECT
                                                                codigo
                                                            FROM
                                                                esc_secao
                                                            WHERE
                                                                fk_unidade IN (
                                                                    :u
                                                                )
                                                        )
                                                             AND fk_secao_poli IN (
                                                            SELECT
                                                                codigo
                                                            FROM
                                                                esc_secao
                                                            WHERE
                                                                fk_unidade IN (
                                                                    :u
                                                                )
                                                        ) THEN
                                                            0
                                                        ELSE
                                                            1
                                                    END
                                                WHEN fk_secao <> fk_secao_poli
                                                     AND fk_secao IN (
                                                    SELECT
                                                        codigo
                                                    FROM
                                                        esc_secao
                                                    WHERE
                                                        fk_unidade IN (
                                                            :u
                                                        )
                                                )
                                                     AND fk_secao_poli NOT IN (
                                                    SELECT
                                                        codigo
                                                    FROM
                                                        esc_secao
                                                    WHERE
                                                        fk_unidade IN (
                                                            :u
                                                        )
                                                ) THEN
                                                    - 1
                                            END poli_status
                                        FROM
                                            (
                                                SELECT
                                                    e.granularidade granularidade,
                                                    ehc.fk_colaborador,
                                                    ehc.fk_secao,
                                                    ehc.fk_secao_poli,
                                                    nvl(ehc.fk_tipo_posto_ori, nvl(LAG(ehc.fk_tipo_posto_ori IGNORE NULLS) OVER(
                                                        PARTITION BY ehc.fk_colaborador
                                                        ORDER BY
                                                            ehc.fk_colaborador, ehc.data
                                                    ), LEAD(ehc.fk_tipo_posto_ori IGNORE NULLS) OVER(
                                                        PARTITION BY ehc.fk_colaborador
                                                        ORDER BY
                                                            ehc.fk_colaborador, ehc.data
                                                    ))) AS fk_tipo_posto_ori,
                                                    nvl(ehc.fk_tipo_posto, nvl(LAG(ehc.fk_tipo_posto IGNORE NULLS) OVER(
                                                        PARTITION BY ehc.fk_colaborador
                                                        ORDER BY
                                                            ehc.fk_colaborador, ehc.data
                                                    ), LEAD(ehc.fk_tipo_posto IGNORE NULLS) OVER(
                                                        PARTITION BY ehc.fk_colaborador
                                                        ORDER BY
                                                            ehc.fk_colaborador, ehc.data
                                                    ))) AS fk_tipo_posto,
                                                    ehc.data,
                                                    ehc.hora_ini,
                                                    ehc.hora_fim,
                                                    ehc.hora_ini_cint,
                                                    ehc.hora_fim_cint,
                                                    ehc.hora_ini_cint_ext,
                                                    ehc.hora_fim_cint_ext,
                                                    ehc.tipo,
                                                    0 ctrl
                                                FROM
                                                    esc_horario_colaborador   ehc,
                                                    esc_escala                e,
                                                    esc_secao                 es
                                                WHERE
                                                    ehc.fk_escala = e.codigo
                                                    AND ehc.fk_secao = es.codigo
                                                    AND ehc.data between to_date(:i, 'YYYY-MM-DD') and to_date(:f, 'YYYY-MM-DD')
                                                    AND 3=3
                                                    AND ehc.tipo IN (
                                                        'T',
                                                        'P'
                                                    )
                                                    AND es.fk_unidade IN (
                                                        :u
                                                    )
                                                    AND ( ehc.fk_secao IN (
                                                        SELECT
                                                            codigo
                                                        FROM
                                                            esc_secao
                                                        WHERE
                                                            fk_unidade IN (
                                                                :u
                                                            )
                                                    )
                                                          OR ehc.fk_secao_poli IN (
                                                        SELECT
                                                            codigo
                                                        FROM
                                                            esc_secao
                                                        WHERE
                                                            fk_unidade IN (
                                                                :u
                                                            )
                                                    ) )
                                                UNION ALL
                                                select
                                                    granularidade,
                                                    fk_colaborador,
                                                    fk_secao,
                                                    fk_secao_poli,
                                                    fk_tipo_posto_ori,
                                                    fk_tipo_posto,
                                                    data,
                                                    hora_ini,
                                                    hora_fim,
                                                    hora_ini_cint,
                                                    hora_fim_cint,
                                                    hora_ini_cint_ext,
                                                    hora_fim_cint_ext,
                                                    tipo,
                                                    -1 ctrl
                                                    from (
                                                SELECT
                                                    e.granularidade granularidade,
                                                    ehc.fk_colaborador,
                                                    ehc.fk_secao,
                                                    ehc.fk_secao_poli,
                                                    nvl(ehc.fk_tipo_posto_ori, nvl(LAG(ehc.fk_tipo_posto_ori IGNORE NULLS) OVER(
                                                        PARTITION BY ehc.fk_colaborador
                                                        ORDER BY
                                                            ehc.fk_colaborador, ehc.data
                                                    ), LEAD(ehc.fk_tipo_posto_ori IGNORE NULLS) OVER(
                                                        PARTITION BY ehc.fk_colaborador
                                                        ORDER BY
                                                            ehc.fk_colaborador, ehc.data
                                                    ))) AS fk_tipo_posto_ori,
                                                    nvl(ehc.fk_tipo_posto, nvl(LAG(ehc.fk_tipo_posto IGNORE NULLS) OVER(
                                                        PARTITION BY ehc.fk_colaborador
                                                        ORDER BY
                                                            ehc.fk_colaborador, ehc.data
                                                    ), LEAD(ehc.fk_tipo_posto IGNORE NULLS) OVER(
                                                        PARTITION BY ehc.fk_colaborador
                                                        ORDER BY
                                                            ehc.fk_colaborador, ehc.data
                                                    ))) AS fk_tipo_posto,
                                                    ehc.data,
                                                    ehc.hora_ini,
                                                    ehc.hora_fim,
                                                    ehc.hora_ini_cint,
                                                    ehc.hora_fim_cint,
                                                    ehc.hora_ini_cint_ext,
                                                    ehc.hora_fim_cint_ext,
                                                    ehc.tipo
                                                FROM
                                                    esc_horario_colaborador   ehc,
                                                    esc_escala                e,
                                                    esc_secao                 es
                                                WHERE
                                                    ehc.fk_escala = e.codigo
                                                    AND ehc.fk_secao = es.codigo
                                                    AND ehc.data between to_date(:i, 'YYYY-MM-DD') and to_date(:f, 'YYYY-MM-DD')
                                                    AND 3=3
                                                    AND ehc.tipo = 'T'
                                                    AND es.fk_unidade IN (
                                                        :u
                                                    )
                                                    
                                                    AND ( ehc.fk_secao IN (
                                                        SELECT
                                                            codigo
                                                        FROM
                                                            esc_secao
                                                        WHERE
                                                            fk_unidade IN (
                                                                :u
                                                            )
                                                    )
                                                          AND ehc.fk_secao_poli IN (
                                                        SELECT
                                                            codigo
                                                        FROM
                                                            esc_secao
                                                        WHERE
                                                            fk_unidade IN (
                                                                :u
                                                            )
                                                    ) )
                                                    ) where  (fk_secao <> fk_secao_poli or (fk_secao = fk_secao_poli and fk_tipo_posto_ori <> fk_tipo_posto))
                                            )
                                    ) all_colab,
                                    (
                                        WITH tabela_parametros AS (
                                            SELECT DISTINCT
                                                granularidade AS minutos
                                            FROM
                                                esc_escala
                                            WHERE
                                                situacao = 'G'
                                                AND fk_secao IN (
                                                    SELECT
                                                        codigo
                                                    FROM
                                                        esc_secao
                                                    WHERE
                                                        fk_unidade IN (
                                                            :u
                                                        )
                                                )
                                                AND ( to_date(:i, 'YYYY-MM-DD') BETWEEN data_ini AND data_fim
                                                      OR to_date(:f, 'YYYY-MM-DD') BETWEEN data_ini AND data_fim
                                                      OR data_ini BETWEEN to_date(:i, 'YYYY-MM-DD') AND to_date(:f, 'YYYY-MM-DD')
                                                      OR data_fim BETWEEN to_date(:i, 'YYYY-MM-DD') AND to_date(:f, 'YYYY-MM-DD')
                                                      )
                                        ), lista_horas (
                                            hora,
                                            intervalo
                                        ) AS (
                                            SELECT
                                                trunc(TO_DATE('01012000', 'ddmmyyyy')) hora_inicial,
                                                minutos
                                            FROM
                                                tabela_parametros
                                            UNION ALL
                                            SELECT
                                                hora + numtodsinterval(intervalo, 'minute'),
                                                intervalo
                                            FROM
                                                lista_horas
                                            WHERE
                                                hora <= trunc(TO_DATE('01012000', 'ddmmyyyy') + 2) - numtodsinterval(intervalo, 'minute'
                                                )
                                        )
                                        SELECT
                                            intervalo,
                                            hora
                                        FROM
                                            lista_horas
                                    ) all_hors
                                WHERE
                                    all_colab.granularidade = all_hors.intervalo
                            ) alocado ON ( temp_ideal.fk_secao = alocado.fk_secao
                                           AND temp_ideal.fk_tipo_posto = alocado.fk_tipo_posto_ori
                                           AND temp_ideal.data = alocado.data
                                           AND temp_ideal.hora BETWEEN alocado.hora AND ( alocado.hora + ( 1 / 24 / 60 ) * ( alocado
                                           .granularidade - 1 ) ) )
                        GROUP BY
                            temp_ideal.fk_secao,
                            temp_ideal.secao,
                            temp_ideal.fk_unidade,
                            temp_ideal.unidade,
                            temp_ideal.tipo_posto,
                            temp_ideal.fk_tipo_posto,
                            temp_ideal.data,
                            temp_ideal.hora
                    )
            )
)t
