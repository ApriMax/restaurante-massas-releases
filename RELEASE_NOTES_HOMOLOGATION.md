# Homologação R18.46.3

R18.46.3 Homologação — correção final da sobreposição das janelas abertas a partir de Pagers em uso. Foi identificada uma regra antiga de modal com `!important` e especificidade maior, que anulava a correção anterior. A regra final usa seletor mais específico e fica no fim da folha de estilos, garantindo que Visualizar, Receber, Cancelar, Pager e Pronto abram acima da lista Pagers em uso. Ao fechar a ação, a lista permanece aberta atrás. Mantém todos os ajustes de privacidade do Operador aprovados na R18.46.1. Produção e Worker permanecem inalterados.
