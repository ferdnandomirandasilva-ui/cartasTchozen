# Direção inicial das regras

Este documento separa decisões confirmadas de ideias que ainda precisam ser escolhidas. A meta é usar Hearthstone e Magic como referências de ritmo, variedade e decisões táticas, mantendo regras próprias para o grupo.

## Confirmado

- É um TCG para partidas multiplayer hospedadas localmente.
- As cartas usam piadas internas e referências do grupo.
- Hearthstone e Magic são inspirações para as regras.
- O jogo não terá terrenos.
- Balanceamento e satisfação das partidas são objetivos centrais.

## Direção em avaliação

Sem terrenos, a partida precisa de uma fonte de recurso que não dependa de comprar cartas de recurso. Uma opção simples para testar é aumentar o limite de mana automaticamente a cada turno até um teto e restaurar a mana disponível no início do turno. Isso reduz partidas travadas por compras ruins e torna os custos das cartas comparáveis. Ainda não é uma regra aprovada.

O modelo atual de cartas já comporta custos, criaturas com ataque/vida e feitiços, mas esses campos ainda não definem as regras de jogo. Efeitos escritos nas descrições também não são executados pelo protótipo.

## Decisões pendentes

- Mana: crescimento automático ou limite fixo; valor inicial, teto e momento de recarga.
- Baralho: tamanho, quantidade máxima de cópias e composição mínima.
- Compra: mão inicial, compra por turno, mulligan e limite de mão.
- Turno: ordem das fases e quem começa.
- Combate: quais permanentes podem atacar, quando ficam prontas, como o defensor escolhe bloqueadores e como dano é resolvido.
- Partida: vida inicial, condições de vitória e empate, e o que ocorre quando o baralho acaba.
- Efeitos: palavras-chave, duração, prioridades e ordem de resolução.
- Interação: ações permitidas fora do próprio turno e possibilidade de resposta do oponente.

## Princípios de implementação e balanceamento

- Definir cada regra com precisão suficiente para que host e clientes resolvam a mesma ação do mesmo jeito.
- O host valida ações e mantém o estado oficial da partida.
- Manter identidade de carta, custo, estatísticas e efeitos estruturados como dados, sem fazer a lógica depender do texto de ambientação.
- Mudar uma variável de balanceamento por vez e registrar a versão das regras usada em cada sessão de teste.
- Usar as referências como inspiração; nomes, textos e efeitos finais devem refletir o grupo e não exigir reproduzir cartas existentes.

## Mesa e compra confirmadas em 13/10/2026

- Cada participante começa com um deck de 60 cartas e uma mão de 7; limite de mão: 7.
- O deck fica com 53 cartas após a distribuição inicial.
- No início de cada turno, compra até 2 cartas, limitada pelas vagas na mão e pelas cartas restantes no deck. A distribuição inicial não recebe compra adicional.
- Jogador: cemitério à esquerda e deck à direita. Oponente: deck à esquerda e cemitério à direita da tela.
- Cartas nos campos dos dois participantes mostram as faces. Deck e cemitério mostram o verso; a mão do jogador local mostra faces e a mão adversária permanece oculta.
- O cemitério tem área e estado separados, mas ainda não existe regra de envio de cartas a ele.
- Deck vazio interrompe a compra; condição de vitória/derrota por esgotamento continua pendente.

### Limitações desta versão
O protótipo repete as definições disponíveis para preencher os decks de 60 e embaralha cada deck. Isto não estabelece um limite de cópias nem implementa construção de deck.
O turno adversário continua sendo uma espera automática; a compra adversária já respeita as mesmas regras, mas não há IA, combate ou multiplayer.
As faces usam as artes, a moldura Card.png e a fonte Beleren-Bold.ttf originais. O verso continua provisório, pois ainda não há um asset dedicado para ele.

## Inspeção de cartas
- Clique direito em uma carta da mão ou em campo abre uma cópia ampliada sobre a mesa, sem alterar escala, posição ou estado da carta original.
- Esc, outro clique direito ou clique esquerdo fora da prévia fecha a inspeção.
- A prévia não pode ser arrastada nem jogar cartas; bloqueia cliques na mesa enquanto estiver aberta.
- Na mão adversária, a prévia mostra somente o verso, sem copiar os dados ocultos.

## Animação da mão
A mão local usa novamente o leque em arco e transições de 0,2 segundo. A abertura cresce com a quantidade de cartas, até 7, e a escala se adapta à área da mão. Arrastar interrompe a transição da carta; jogar ou devolver reorganiza o leque. As cartas em campo continuam em fila e a inspeção ampliada não altera o leque.

## Apresentação da arte e descrição
Na mão e no campo, a arte ocupa a região inferior antes reservada à descrição. Nome, custo, tipo e atributos continuam visíveis. A inspeção por clique direito reduz suavemente a área da arte e revela a caixa de descrição, em uma transição de aproximadamente 0,24 segundo. Cartas ocultas não revelam descrição.

## Animação de compra
A distribuição inicial e as compras por turno são apresentadas carta a carta: uma carta com o verso sai do deck e desliza até a vaga na mão. O leque se reorganiza para recebê-la. Ao chegar à mão local, a carta vira e revela a face; a mão adversária mantém o verso. Os contadores acompanham cada compra. Arraste e finalizar turno ficam bloqueados até a sequência terminar. Limite de 7 e interrupção por deck vazio continuam sendo aplicados pelo estado do deck.

## Destaque da mão
Passar o mouse sobre uma carta da mão local a puxa 18 pixels para cima, sem mudar tamanho, inclinação ou posição horizontal, com transição de 0,16 segundo. Continua na mão e volta à posição e camada original ao sair. A ordem permanente é fixa: a carta à direita cobre a da esquerda. O destaque fica suspenso durante compras, arraste e inspeção ampliada; não se aplica ao campo. O mouse local não destaca a mão adversária. A animação adversária fica disponível para uma seleção feita pelo próprio oponente, puxando o verso para baixo sem revelar dados; a ligação com ações reais depende da futura IA ou integração multiplayer.

A mão adversária compartilha a mesma organização em leque, escala e transições da mão local, espelhada em 180 graus na borda superior. A distribuição e compras partem do deck adversário, mantendo o verso durante toda a animação e na inspeção ampliada.

O tamanho da mão local é calculado para 7 cartas e permanece constante ao comprar ou jogar, ajustando-se somente ao tamanho da janela. O leque fica junto à borda inferior, com a parte de baixo das cartas fora da tela. A carta que sai do deck já usa a escala final da mão e mantém essa escala durante o deslocamento; a virada ao chegar continua sendo uma animação separada.

## Camadas de profundidade
A mesa (campos, decks e cemitérios), as mãos, a interface, as cartas em movimento e o zoom ficam em grupos separados. A ordem de desenho é: mesa ao fundo; mãos à frente; interface; cartas em movimento; zoom no topo. A sobreposição da mão continua sendo controlada dentro de sua própria camada. Esta separação mantém a perspectiva e as dimensões atuais.

## Painel do jogador
O centro inferior reserva espaço para retrato, vida e mana na camada de interface, acima da mão. A mana usa o valor atual do estado da partida. Vida inicial e máxima: 100. O painel bloqueia cliques e destaque nas cartas que estiverem atrás dele.

O retrato usa o busto PNG transparente enviado pelo usuário, mantendo proporção e silhueta completas. A área central mede 140 × 140 na resolução de referência e ultrapassa a base superior dos contadores. Vida e mana ficam em distintivos escuros com borda dourada, aos lados. O avatar permanece acima da mão e não recebe recorte quadrado ou fundo adicional.

## Frascos de recursos
Vida inicial e máxima de 100. Coração vermelho à esquerda inferior do retrato e gota azul à direita, ambos em camada à frente do busto. As molduras originais cobrem os frascos; os líquidos ficam recortados no interior e possuem reflexo de vidro e ondulação discreta. Alterações de vida e mana animam o nível em 0,35 segundo; o número mostra o valor atual e a dica mostra atual/máximo. A mana segue gasto e recarga existentes. O estado de vida emite atualizações, mas dano e combate continuam pendentes.

O leque foi elevado mais 27 pixels e sua abertura máxima passou de 42 para 56 graus, criando uma curva mais acentuada para acomodar o retrato e os frascos. O tamanho das cartas permanece o mesmo na resolução de referência. A mão adversária mantém o espelhamento da organização.

## Ajuste atual do retrato e da mão
A mão voltou à abertura de 42 graus e à altura anterior ao último ajuste. O retrato e os frascos foram elevados em conjunto, ficando acima das cartas na posição da tela. A ordem de profundidade agora coloca mesa, retrato/recursos e mãos, nessa sequência; assim, cartas que sobreponham o retrato ou os frascos ficam à frente. As cartas não têm mais o destaque bloqueado pela região do retrato.

## Moldura atual com barras
A nova moldura substitui os frascos na interface ativa: retrato circular, barra superior de vida vermelha e barra inferior de mana azul, ambas com preenchimento horizontal animado e valores atual/máximo. Jogador no canto inferior esquerdo; oponente no canto superior direito, com moldura espelhada horizontalmente e textos legíveis. A vida começa em 100 para ambos. O retrato adversário permanece reservado até sua arte ser definida. Os recursos adversários têm estado próprio para futuras ações de IA ou multiplayer; atualmente seu turno só recarrega mana e compra cartas.
A camada das mãos continua à frente da moldura, enquanto cartas em movimento e zoom permanecem acima.

## Interface ativa restaurada
Foram restaurados o busto sem recorte circular, o coração de vida vermelho e a gota de mana azul. As posições continuam nos cantos atuais: jogador embaixo à esquerda e oponente em cima à direita. Os frascos ficam à frente do retrato dentro do painel; as cartas da mão continuam em uma camada acima do painel. Valores e animações de preenchimento permanecem ligados aos estados de cada participante.

O retrato adversário foi definido com o segundo busto transparente enviado pelo usuário (arquivo opponent_avatar.png). Substitui o marcador de posição no canto superior direito, preservando proporções e os ícones de vida e mana.

## Mesa 3D
A mesa ativa usa geometria 3D, câmera fixa em perspectiva, iluminação e sombras. Decks e espaços de cemitério ficam em lados espelhados. A arte da mesa e o verso 3D são provisórios. As mãos, retratos, frascos, compras e inspeção continuam em 2D, acima do cenário.

Arraste uma carta da mão para a metade inferior central da mesa. A jogada válida desconta mana e apresenta a carta com sua face sobre a mesa; solturas fora da área, no lado adversário ou sem mana retornam à mão. O campo organiza suas cartas automaticamente. Clique direito em uma carta do campo abre a inspeção com descrição; Esc fecha. A projeção acompanha o tamanho da janela e a compra parte da posição projetada do deck.

As regras existentes permanecem: 60 cartas por deck, mão inicial e limite de 7, compra de até 2 por turno quando há espaço, vida inicial 100 e mana 3. O adversário possui escolha automática de jogadas; combate e resolução de efeitos continuam pendentes.
## Turno automático do adversário
Ao finalizar o turno local, o adversário recarrega sua mana para 3 e compra até 2 cartas respeitando o limite de 7. Uma política separada da interface avalia combinações da mão: prioriza gastar a maior quantidade de mana possível, depois a soma de ataque e vida impressos, depois a quantidade de cartas. Empates mantêm a ordem da mão. Reavalia após cada jogada, até não haver carta pagável; cartas de custo zero também são removidas normalmente, sem repetir a mesma carta.

Cada escolha destaca o verso na mão adversária antes de deslizar até seu campo. A mana é descontada e a carta sai da mão; os dados são revelados apenas na carta pública 3D ao chegar à mesa. A mão restante conserva os versos e sua organização. O turno do jogador retorna automaticamente com recarga de mana e compras habituais. A interface local permanece bloqueada para jogadas durante toda a sequência.

Esta IA opera as mesmas jogadas de colocação do protótipo: não resolve descrições de feitiços, dano, ataques ou vitória. Custos e atributos vêm dos recursos CardData; cartas acima da mana disponível permanecem na mão.
Execução conferida no Godot 4.7.2, em dois turnos consecutivos: primeiro, mão adversária 7→6 e campo 0→1; segundo, compra de uma carta (6→7) e três jogadas (7→4), campo 1→4. Mana adversária terminou em 0 nos dois turnos; turno local retornou liberado. Cartas restantes mantiveram verso e nenhum dado visual associado. Captura do campo conferida. Nenhuma suíte de testes foi adicionada ou executada.
## Tamanho da mão em primeiro plano
As cartas de ambas as mãos usam escala 45% maior que o ajuste anterior. O raio de distribuição do leque mantém seu valor anterior para não espalhar as sete cartas por toda a largura da tela. A base permanece parcialmente fora da tela; compras usam a mesma escala final e o destaque continua puxando a carta para cima sem ampliá-la. A mesa mantém seu tamanho atual.
## Relação entre mão e deck
A escala da mão foi ampliada novamente: multiplicador base 2,1, com tamanho mínimo definido pela projeção do deck na tela. A largura de cada carta na mão é pelo menos 20% maior que a largura projetada do deck local. As duas mãos compartilham essa escala; o leque mantém seu raio anterior, a base segue fora da tela e a compra usa o tamanho final da mão.
A altura visível das mãos voltou à referência anterior ao último aumento. A escala atual permanece: o excedente de altura das cartas fica além da borda da tela, com ajuste espelhado no oponente. Compras e destaque continuam seguindo a posição final do leque.
## Perspectiva da mesa
Câmera elevada e mais próxima do eixo vertical, seguindo as referências enviadas de Magic Arena: posição base (0, 13, 4,6), alvo (0, 0, -0,15), FOV 38°. A mesa é vista a aproximadamente 70° acima do plano, com convergência lateral mais suave e faces menos encurtadas. A distância continua adaptada à proporção da janela; arraste, seleção e origem das compras usam a projeção da mesma câmera. As mãos e o HUD mantêm suas posições em 2D.Os contadores dos decks e cemitérios locais foram posicionados acima de seus espaços, voltados para o centro, evitando sobreposição com o retrato inferior. Os adversários permanecem abaixo de seus espaços.
## Deck e cemitério agrupados
Os dois espaços locais ficam lado a lado no setor inferior direito, recuados da borda e próximos da mão: deck à esquerda em (4, 0,04, 2,85), cemitério à direita em (5,8, 0,04, 2,85). O conjunto adversário é espelhado no setor superior esquerdo. A origem das compras acompanha automaticamente a nova posição do deck.

Os espaços dos montes são excluídos da área de soltura válida. A organização de campo mantém uma faixa livre junto ao conjunto: a fila única foi ligeiramente recuada; em duas filas, a fila mais próxima do participante ocupa menos largura e se desloca para o lado livre. O mesmo ajuste é espelhado para o adversário.
## Retratos na lateral e contadores quadrados
A interface ativa usa portrait_counters.gd no lugar dos frascos. Ambos os retratos ficam à esquerda: adversário na faixa superior (âncora vertical 27%) e jogador na inferior (57%), seguindo a referência marcada. Vida e mana aparecem em dois quadrados simples de 56×56 ao lado direito do busto, com vida vermelha em cima e mana azul embaixo. O adversário mantém exatamente a mesma ordem, sem inversão.

Os valores continuam ligados aos sinais de recursos de cada jogador e são atualizados diretamente, sem frascos, líquidos ou animação de preenchimento. Vida inicial 100 e mana atual do estado. Mãos, decks e cemitérios mantêm suas posições; os painéis permitem que cliques passem para a mesa. O código e os assets dos frascos antigos ficam disponíveis, mas não são usados pela interface ativa.
## Ajuste de centralização lateral
Os dois conjuntos de retrato e contadores agora usam âncoras verticais de 35% para o adversário e 65% para o jogador, distribuídos em torno do centro vertical da tela. Os montes locais foram baixados levemente, para z=3,0; o conjunto adversário acompanha o espelhamento em z=-3,0. Tamanhos e ordem dos elementos permanecem iguais.
## Mesa integrada e área útil ampliada
Cada metade colorida agora mede 12,8×4,2, abrangendo os montes sobre a superfície da mesa e deixando margem até a moldura externa. As posições aprovadas de deck e cemitério são mantidas. A faixa de cartas mais próxima do centro usa 12,8 unidades de largura; a faixa junto à mão usa 8,85 e deixa livre o canto dos montes. A área de soltura e o destaque visual seguem essas duas faixas, sem aceitar jogadas sobre deck ou cemitério.

Até oito cartas usam uma fila larga; acima disso passam a duas filas. Cada fila aproveita sua própria largura e só reduz escala quando necessário. O adversário recebe a mesma disposição espelhada. Retratos, mãos e seus contadores não mudam.As legendas das mãos foram retiradas para não cobrir cartas. O indicador de turno fica entre os retratos na lateral esquerda; os contadores de deck e cemitério ficam junto à borda externa de seus próprios montes, liberando as filas de cartas. Prévia visual com 12 cartas de cada lado usada para conferir ocupação e separação dos espaços.
## Combate ativo
O combate básico segue Magic: o jogador marca atacantes e confirma todas juntas; o adversário associa suas defensoras aos ataques. As criaturas atacam o jogador, sem selecionar criaturas inimigas como alvo. Há uma fase de combate normal por turno e uma segunda oportunidade de jogar cartas depois dela.

- Atacantes são viradas ao confirmar a declaração. Permanecem viradas durante o turno adversário e desviram no início do próximo turno do dono. Criaturas viradas não atacam nem bloqueiam.
- Criaturas recém-jogadas podem bloquear imediatamente, mas precisam aguardar o próximo turno do dono para atacar. Poder zero não impede atacar; o dano causado é zero.
- Cada defensora normalmente bloqueia uma atacante. Várias defensoras podem bloquear a mesma atacante. Bloquear não vira a defensora.
- Atacantes e defensoras causam dano simultaneamente, igual ao seu poder. Todas causam seu dano antes da remoção das criaturas derrotadas.
- Dano igual ou maior que a resistência derrota. Dano insuficiente fica marcado, pode acumular no mesmo turno e é removido no fim do turno para todas as sobreviventes. A resistência da definição da carta não é alterada.
- A atacante distribui seu poder entre os bloqueadores. Com bloqueio múltiplo, o jogador usa o painel de distribuição; é possível atribuir zero a um bloqueador e todo o dano a outro, sem ordenar mortes. A soma deve corresponder ao poder. O adversário usa uma distribuição automática válida.
- Atacantes sem bloqueio causam dano ao jogador. Ataques bloqueados não causam dano excedente ao jogador sem a habilidade atropelar.
- A IA escolhe bloqueios, pode agrupar defensoras e aplica as mesmas regras. Quando a IA ataca, a partida aguarda o jogador escolher e confirmar as defesas.
- Cartas derrotadas, incluindo atacantes, vão ao cemitério do dono. A vida começa em 20 neste projeto e mana/compra continuam seguindo nossas regras próprias.

### Limites atuais
O combate básico está implementado. As cartas atuais ainda não possuem habilidades de combate estruturadas (vigilância, ímpeto, voar, alcance, toque mortífero, iniciativa, golpe duplo, atropelar e indestrutível), planeswalkers ou batalhas. Não há pilha/prioridade para respostas instantâneas. Os efeitos de cartas permanecem pendentes; não se presume que o motor reproduz todas as exceções de Magic.

## Indicadores atuais
As atacantes têm contorno luminoso e legenda vermelha numerada, ambos translúcidos, sem setas para o retrato. As defensoras têm contorno luminoso azul translúcido. O arco azul aparece somente após associar uma defensora a uma atacante e aponta para o ataque bloqueado. A defensora selecionada recebe legenda; os arcos acompanham movimento e redimensionamento e não capturam cliques. Cancelamento e fim da resolução removem as conexões.
### Exibição de feitiços
- Feitiços usados por qualquer jogador aparecem diretamente em uma prévia lateral à direita, menor que o zoom tradicional e com descrição visível. Não entram na mesa.
- A prévia permanece por 3 segundos, além das transições de entrada e saída. Clique direito abre o zoom tradicional; a contagem pausa durante essa leitura.
- Ao terminar a exibição, a carta segue diretamente para o cemitério do dono, que mostra apenas o verso.
- Os efeitos de Preocupado e Sério continuam pendentes por decisão do usuário: suas descrições ainda não especificam regras ou valores de jogo.
- A prévia do feitiço fica mais próxima do centro (76% da largura e 56% da altura). A carta chega da região da mão do dono com uma volta completa em 0,55 segundo; os 3 segundos de exibição começam após a chegada.
- Cartas derrotadas levantam da mesa e percorrem um arco até o cemitério do dono em 0,65 segundo, alinhando-se ao monte e mostrando o verso na chegada. Feitiços voam diretamente da prévia lateral ao cemitério após os 3 segundos, reduzindo para o tamanho projetado do monte e virando para o verso durante o percurso.
- Atacantes e defensoras recebem contorno luminoso translúcido vermelho e azul, respectivamente. Legendas coloridas e arcos azuis também são translúcidos e permanecem durante a resolução. Antes de uma carta partir ao cemitério, removem-se seu contorno, legenda e todas as conexões que a envolvem. As marcas restantes desaparecem ao encerrar o combate.

## Recursos nativos atuais
- Vida inicial e limite máximo nativo: 20 para ambos os jogadores, substituindo os valores anteriores de 100.
- Cada jogador dispõe de 3 mana no primeiro turno. Após uma rodada completa (turno do jogador e turno do adversário), a capacidade de ambos aumenta simultaneamente em 1 até o limite de 9, e a mana de ambos recarrega. O primeiro turno do adversário também começa em 3.
- Aumentar capacidade só acontece ao concluir a rodada, não ao trocar para o turno adversário, confirmar ataques, bloqueios ou jogar cartas. Os limites nativos são aplicados pelo estado dos recursos e a interface acompanha as alterações.
