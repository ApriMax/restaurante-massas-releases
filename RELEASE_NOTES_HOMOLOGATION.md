# Homologação R18.41

R18.41 Homologação — corrige a impressão da Conferência do dia. A rota /print/cash-conference colidia com a rota dinâmica de impressão de pedidos /print/{order_id}, fazendo o sistema tentar interpretar 'cash-conference' como número de pedido. A impressão foi movida para uma rota própria sem conflito. Também aproxima os valores das respectivas formas de pagamento na tela da Conferência. Mantém os demais ajustes da R18.40/R18.39. Produção e Worker permanecem inalterados.
