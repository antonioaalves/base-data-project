SELECT ec.codigo as fk_colaborador,loja, secao, cav.nome, emp, convenio, puesto, min_dias_trabalhados, 
max_dias_trabalhados, tipo_de_turno, horario_partido_continuado, 
h_tm_in, h_tm_out, h_tt_in, h_tt_out, h_seg_in, h_seg_out, tipo_turno_seg, 
h_ter_in, h_ter_out, tipo_turno_ter, h_qua_in, h_qua_out, tipo_turno_qua, 
h_qui_in, h_qui_out, tipo_turno_qui, h_sex_in, h_sex_out, tipo_turno_sex, 
h_sab_in, h_sab_out, tipo_turno_sab, h_dom_in, h_dom_out, tipo_turno_dom, 
h_fer_in, h_fer_out, tipo_turno_fer, limite_superior_manha, limite_inferior_tarde, 
t_total, horas_trab_partido_slot_min, horas_trab_partido_slot_max, horas_trab_val_carga, 
horas_trab_dia_carga_min, horas_trab_dia_carga_max, horas_trab_semana_max, horas_trab_mensal, 
horas_trab_ano, horas_medias_p_dia, horas_base_dia_arredmedia, min_anual, max_anual, dc_inc_exc, 
dc_tempo_limite_nao_descanso, dc_duracao, dc_tmin_ate, dc_tmin_apos, desc_partidos_duracao_min, 
desc_partidos_duracao_max, horas_complementarias, hc_min_anual, hc_max_anual, polivalencia_1, 
polivalencia1_duracao_min, tipo_polivalencia_1, polivalencia_2, polivalencia2_duracao_min, 
tipo_polivalencia_2, polivalencia_3, polivalencia3_duracao_min, tipo_polivalencia_3, 
poli_duracao_min_posto_origem, t_total_elegivel, t_total_efetivo 
FROM wfm.core_algorithm_variables  cav
inner join WFM.ESC_COLABORADOR ec
on ec.matricula = cav.emp
WHERE ec.CODIGO IN (:colabs)
