SELECT ec.codigo as fk_colaborador,loja, secao, puesto, convenio, cav.nome, emp, min_dias_trabalhados, max_dias_trabalhados, tipo_de_turno, seq_turno, t_total, l_total, DYF_MAX_T, Lq,Q, fds_cal_2d, fds_cal_3d, d_cal_xx, semana_1,OUT, upper(CICLO) as CICLO
FROM wfm.core_algorithm_variables cav
inner join WFM.ESC_COLABORADOR ec
on ec.matricula = cav.emp
WHERE ec.CODIGO IN (:colabs)