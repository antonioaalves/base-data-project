# Pacotes necessários
library(dplyr)
library(plotly)
library(lubridate)


write.csv(matriz_dcast,'dist_sabados_68072.csv', row.names = F)

# Criar a coluna de DATA em formato de data
df <- matriz_dcast %>%
  mutate(DATA = as.Date(DATA),
         wday = wday(DATA))

# Filtrar os dados para wday == 7 e HORARIO começando com 'L'
df_filtered <- df %>%
  filter(#wday == 7, 
         #HORARIO %in% c('M','T','MoT'))
         #grepl("^L", HORARIO))
    HORARIO == 'LQ')

# Criar uma coluna de mês/ano e calcular o acumulado por colaborador
df_accum <- df_filtered %>%
  mutate(month_year = floor_date(DATA, "month")) %>%  # Agrupar por mês
  group_by(COLABORADOR, month_year) %>%
  summarise(accumulate_count = n()) %>%  # Contagem por mês
  ungroup() %>%
  arrange(COLABORADOR, month_year) %>%
  group_by(COLABORADOR) %>%
  mutate(cumulative_count = cumsum(accumulate_count))  # Contagem acumulada

# Para exibir o valor final, vamos identificar o último ponto de cada colaborador
df_final_points <- df_accum %>%
  group_by(COLABORADOR) %>%
  filter(month_year == max(month_year))  # Último mês de cada colaborador

# Plotar o gráfico com Plotly
plot_ly(df_accum, x = ~month_year, y = ~cumulative_count, color = ~COLABORADOR, 
        type = 'scatter', mode = 'lines+markers', 
        marker = list(size = 8), 
        line = list(width = 2)) %>%
  # Adicionar os valores finais como texto à direita do último ponto
  add_trace(data = df_final_points, x = ~month_year, y = ~cumulative_count, 
            text = ~cumulative_count, 
            textposition = 'right',  # Coloca o texto à direita
            showlegend = FALSE, 
            mode = 'markers+text', 
            marker = list(size = 8), 
            textfont = list(size = 12)) %>%
  layout(title = "Contagem Acumulada de sabados trabalhados",
         xaxis = list(title = "Mês/Ano", type = "date", tickformat = "%b-%Y"),
         yaxis = list(title = "Contagem Acumulada"),
         legend = list(title = list(text = 'Colaborador')))



# Plotar o gráfico com Plotly
plot_ly(df_accum, x = ~month_year, y = ~cumulative_count, color = ~COLABORADOR, 
        type = 'scatter', mode = 'lines+markers', 
        marker = list(size = 8), 
        line = list(width = 2)) %>%
  # Adicionar os valores finais como texto à direita do último ponto
  add_trace(data = df_final_points, x = ~month_year, y = ~cumulative_count, 
            text = ~cumulative_count, 
            textposition = 'right',  # Coloca o texto à direita
            showlegend = FALSE, 
            mode = 'markers+text', 
            marker = list(size = 8), 
            textfont = list(size = 12)) %>%
  layout(title = "Contagem Acumulada de sabados trabalhados",
         xaxis = list(title = "Mês/Ano", type = "date", tickformat = "%b-%Y"),
         yaxis = list(title = "Contagem Acumulada"),
         legend = list(title = list(text = 'Colaborador')))
