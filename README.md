
# Events at home alone 

Uma coleção de análises baseadas em SQL para o Stripe.

- Observe que, enquanto os modelos core_entities e event_filters são bem genéricos e provavelmente relevantes para todas as empresas que usam o Stripe, os modelos transactions_prep e mrr podem ou não ser aplicáveis ao seu negócio. Se você os achar úteis em suas análises, ótimo! Caso contrário, desative-os em seu projeto definindo enabled: false para as pastas relevantes dentro do seu dbt_project.yml.

## Uso
- Todos os modelos de dados são construídos para serem compilados e executados com dbt. Instalação:
- Adicione este pacote como uma dependência ao seu projeto e execute dbt deps para baixar a fonte mais recente. Recomendamos que você faça referência a uma tag específica para que possa controlar o processo de atualização quando novas versões forem lançadas.
Adicione a seguinte configuração ao seu dbt_project.yml:

# dentro de `models:`
  stripe:
    enabled: true
    materialized: view
    vars:
      #insira a localização da sua tabela stripe_events aqui como 'schema.table'
      events_table: 'stripe.stripe_events'  


$voidboy$# home-alone
