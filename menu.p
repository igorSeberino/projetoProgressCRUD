CURRENT-WINDOW:WIDTH = 85.

DEFINE BUTTON btCidades     LABEL "Cidades" SIZE 15 BY 1.
DEFINE BUTTON btProdutos    LABEL "Produtos" SIZE 15 BY 1.
DEFINE BUTTON btClientes    LABEL "Clientes" SIZE 15 BY 1.
DEFINE BUTTON btPedidos     LABEL "Pedidos" SIZE 15 BY 1.
DEFINE BUTTON btRelClientes LABEL "Relatório de Clientes" SIZE 25 BY 1.
DEFINE BUTTON btRelPedidos  LABEL "Relatório de Pedidos" SIZE 25 BY 1.
DEFINE BUTTON btSair        LABEL "Sair" AUTO-ENDKEY SIZE 15 BY 1.     

DEFINE FRAME f-menu
    btCidades AT 1 btProdutos btClientes btPedidos btSair SKIP
    btRelClientes AT 1 btRelPedidos
        WITH VIEW-AS DIALOG-BOX TITLE "Hamburgueria XTudo" SIZE 85 BY 4.

ON CHOOSE OF btCidades DO:
    RUN piChamaPrograma (INPUT SELF:name).    
END.

ON CHOOSE OF btProdutos DO:
    RUN piChamaPrograma (INPUT SELF:name).    
END.

ON CHOOSE OF btClientes DO:
    RUN piChamaPrograma (INPUT SELF:name).    
END.

ON CHOOSE OF btPedidos DO:
    RUN piChamaPrograma (INPUT SELF:name).    
END.

ON CHOOSE OF btRelClientes DO:
    RUN piChamaPrograma (INPUT SELF:name).    
END.

ON CHOOSE OF btRelPedidos DO:
    RUN piChamaPrograma (INPUT SELF:name).    
END.

ENABLE ALL WITH FRAME f-menu.
WAIT-FOR WINDOW-CLOSE OF FRAME f-menu.

PROCEDURE piChamaPrograma:
    DEFINE INPUT PARAMETER nome AS CHARACTER FORMAT "x(15)" NO-UNDO. 
    
    ASSIGN nome = LC(REPLACE(nome, "bt", "") + ".p").
    
    RUN VALUE("c:/treinamento/workspace/projetofinal/" + nome) NO-ERROR.
END PROCEDURE.