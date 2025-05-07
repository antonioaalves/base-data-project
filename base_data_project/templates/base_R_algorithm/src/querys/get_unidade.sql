SELECT
    u.codigo fk_unidade,
    u.nome   unidade,
    s.codigo fk_secao,
    s.nome   secao,
    p.codigo fk_tipo_posto,
    p.nome   posto
FROM
    esc_unidade u
    INNER JOIN esc_secao      s ON s.fk_unidade = u.codigo
    INNER JOIN esc_tipo_posto p ON p.fk_secao = s.codigo
    WHERE P.codigo = :s
