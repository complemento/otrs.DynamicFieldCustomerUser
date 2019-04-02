# Mnaual de Instalação e Uso Complemento

## Dynamic Field Customer User 

## O que este Add On faz

Este aAdd On cria todos os mecanismos necessários dentro do sistema OTRS para criação de um novo campo dinâmico que permite inserir uma lista de clientes no ticket.

## Instalação

Realize a instalação deste Add On através do Gerenciamento de Pacotes do OTRS acessando *Admin*:

![Screenshot](img/img1.png)

Em *Administration* selecione a opção *Package Manager*:

![Screenshot](img/img2.png)

Em seguida, escolha o pacote do módulo *"DynamicFieldCustomerUser-6.0.opm"* e clique em *Install Package*

![Screenshot](img/img3.png)

## Configurando o AddOn 

Logo após a isntalação do AddOn, precisamos definir algumas configurações, para isso devemos acessar os seguintes passos __Admin->Processes & Automation-> Dynamic Field__, ou faça uma pesquisa no campo *Filter for Items*, por "Dynamic Fields".

![Screenshot](img/img4.png)

Este AddOn funciona para ações de Ticket e/ou Artigos.

No quadro *Actions* logo abaixo de "Ticket" selecione __CustomerUserReference__:

![Screenshot](img/img5.png)

Preencha os campos selecionando a validade e o tipo de entrada, clique __Save__:

![Screenshot](img/img6.png)

Após salvar será necessário vincular o Dynamic Field na tela de ticket, para isso acesse o seguinte:

__Admin->Adiministration->System Configuration__:

![Screenshot](img/img7.png)

Aqui neste ponto, à esquerda em *Navegation* clique na seta __Frontend->Agent->View__:

![Screenshot](img/img8.png)

![Screenshot](img/img9.png)

É possível adicionar o Dynamic Field em Tickets criados via telefone, via E-mail ou via Cliente, basta selecionar *TicketEmailNew* ou *TicketPhoneNew* ou qualquer outra desejada:

![Screenshot](img/img10.png)

Tickets via Cliente clique na seta __Customer->View__ e selecione *TicketMessage*:

![Screenshot](img/img11.png)

Nesta página no campo "Ticket::Frontend::AgentTicketPhone###DynamicField" clique em *Edit this setting*:

![Screenshot](img/img12.png)

Para adicionar o novo clique no icone __+__, insira o nome que deseja no Dynamic Field e clique no visto verde:

![Screenshot](img/img16.png)

Selecione *Enabled* para habilitar o Dynamic Field:

![Screenshot](img/img13.png)

Para salvar clique no visto verde no canto superior direito:

![Screenshot](img/img14.png)

Para concluir clique na mensagem laranja que aparece na superfície da página:

![Screenshot](img/img17.png)

Clique em *Deploy selected changes*:

![Screenshot](img/img18.png)

![Screenshot](img/img19.png)

Para visualizar o Dynamic Field no ticket, clique novamente em *System Configuration*:

![Screenshot](img/img20.png)

Na seta __Frontend->View->Ticket Zoom__:

![Screenshot](img/img21.png)

No campo "Ticket::Frontend::AgentTicketZoom###DynamicField", clique em *Edit this setting*:

![Screenshot](img/img22.png)

Adicione o Dynamic Field e em seguida clique no visto verde:

![Screenshot](img/img23.png)

Habilite o Dynamic Field e grave:

![Screenshot](img/img24.png)

Para concluir clique na mensagem laranja que aparece na suerficíe da página:

![Screenshot](img/img25.png)

![Screenshot](img/img26.png)

Clique em *Deploy now*:

![Screenshot](img/img27.png)

## Como Utilizar

Após configurado o Dynamic Field surgirá na página de criação de ticket para ser utilização, clique em __Ticket -> New phone tcket (ou New email ticket):

![Screenshot](img/img28.png)

![Screenshot](img/img29.png)

![Screenshot](img/img30.png)

![Screenshot](img/img31.png)