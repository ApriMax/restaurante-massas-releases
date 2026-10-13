# Homologação R18.45

R18.45 Homologação — corrige os botões Redefinir senha e Excluir em Usuários e Permissões. A causa era a montagem do onclick com o nome do usuário entre aspas dentro do próprio atributo HTML, quebrando o clique. Os botões agora usam apenas o ID e resolvem o nome internamente. Administrador logado pode redefinir a senha de qualquer usuário sem informar a senha antiga; exclusão do próprio usuário conectado permanece bloqueada. Mantém todos os ajustes visuais e funcionais aprovados da R18.44. Produção e Worker permanecem inalterados.
