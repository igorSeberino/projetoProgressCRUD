DEFINE BUTTON bt-save LABEL "Salvar".
DEFINE BUTTON bt-canc LABEL "Cancelar" AUTO-ENDKEY.

DEFINE INPUT PARAMETER pCodPedido LIKE Pedidos.CodPedido NO-UNDO.
DEFINE VARIABLE dValTotal  AS   DECIMAL           NO-UNDO.

DEFINE SHARED VARIABLE cActionItem AS CHARACTER NO-UNDO.

DEFINE SHARED BUFFER bItens    FOR Itens.

DEFINE FRAME f-item
    Itens.CodProduto    COLON 20 Produtos.NomProduto NO-LABELS
    Itens.NumQuantidade COLON 20
    Itens.ValTotal      COLON 20 SKIP
    bt-save AT 3 bt-canc
        WITH SIDE-LABELS THREE-D SIZE 90 BY 15
            VIEW-AS DIALOG-BOX TITLE "Pedidos".

ON LEAVE OF Itens.CodProduto DO:
    DEFINE VARIABLE lValid AS LOGICAL     NO-UNDO.
    RUN piValidaProduto (INPUT Itens.CodProduto:SCREEN-VALUE,
                          OUTPUT lValid).
    IF NOT lValid THEN DO:
        RETURN NO-APPLY.
    END.
    DISPLAY Produtos.NomProduto
                WITH FRAME f-item.
END.

ON LEAVE OF Itens.NumQuantidade DO:
    ASSIGN dValTotal = Produtos.ValProduto * INPUT Itens.NumQuantidade.

    DISPLAY dValTotal @ Itens.ValTotal WITH FRAME f-item.
END.

ON CHOOSE OF bt-save DO:
    IF cActionItem = "add" THEN DO:
       CREATE bItens.
       ASSIGN bItens.CodPedido     = pCodPedido
              bItens.CodItem       = NEXT-VALUE(seqItem).
    END.        
    ASSIGN bItens.CodProduto    = INPUT Itens.CodProduto
           bItens.NumQuantidade = INPUT Itens.NumQuantidade
           bItens.ValTotal      = dValTotal.
              
    APPLY 'window-close' TO FRAME f-item.
END.
          
ENABLE ALL EXCEPT Produtos.NomProduto Itens.ValTotal WITH FRAME f-item.
IF cActionItem = "mod" THEN DO:
    DISPLAY bItens.CodProduto    @ Itens.CodProduto 
            bItens.NumQuantidade @ Itens.NumQuantidade
            bItens.Valtotal      @ Itens.ValTotal
        WITH FRAME f-item.
END.
WAIT-FOR WINDOW-CLOSE OF FRAME f-item.

PROCEDURE piValidaProduto:
    DEFINE INPUT PARAMETER pProduto AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER pValid AS LOGICAL NO-UNDO INITIAL NO.
   
    FIND FIRST Produtos
        WHERE Produtos.CodProduto = pProduto
        NO-LOCK NO-ERROR.
    IF  NOT AVAILABLE Produtos THEN DO:
        MESSAGE "Produto  " pProduto " nao existe!"
                VIEW-AS ALERT-BOX ERROR.
        ASSIGN pValid = NO.
    END.
    ELSE 
       ASSIGN pValid = YES.
END PROCEDURE.
