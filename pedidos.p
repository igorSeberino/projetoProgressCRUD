USING Progress.Json.ObjectModel.JsonArray FROM PROPATH.
USING Progress.Json.ObjectModel.JsonObject FROM PROPATH.

DEFINE BUTTON bt-pri  LABEL "<<".
DEFINE BUTTON bt-ant  LABEL "<".
DEFINE BUTTON bt-prox LABEL ">".
DEFINE BUTTON bt-ult  LABEL ">>".
DEFINE BUTTON bt-add  LABEL "Adicionar".
DEFINE BUTTON bt-mod  LABEL "Modificar".
DEFINE BUTTON bt-del  LABEL "Eliminar".
DEFINE BUTTON bt-save LABEL "Salvar".
DEFINE BUTTON bt-canc LABEL "Cancelar".
DEFINE BUTTON bt-exp  LABEL "Exportar".
DEFINE BUTTON bt-addItem  LABEL "Adicionar".
DEFINE BUTTON bt-modItem  LABEL "Modificar".
DEFINE BUTTON bt-delItem  LABEL "Eliminar".
DEFINE BUTTON bt-sair LABEL "Sair" AUTO-ENDKEY.

DEFINE VARIABLE cAction  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cTable   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iNumItem AS INTEGER     NO-UNDO.

DEFINE QUERY qPed FOR Pedidos, Clientes SCROLLING.
DEFINE QUERY qItem FOR Itens, Produtos SCROLLING.

DEFINE BROWSE browseItem QUERY qItem DISPLAY
    iNumITem LABEL "Item" Itens.CodProduto LABEL "Codigo" Produtos.NomProduto 
    Itens.NumQuantidade Produtos.ValProduto Itens.ValTotal
    WITH SEPARATORS 10 DOWN.

DEFINE BUFFER bPedidos  FOR Pedidos.
DEFINE BUFFER bItens    FOR Itens.

DEFINE FRAME f-ped
    bt-pri AT 10
    bt-ant 
    bt-prox 
    bt-ult SPACE(3) 
    bt-add bt-mod bt-del bt-save bt-canc bt-exp SPACE(3)
    bt-sair  SKIP(1)
    Pedidos.CodPedido    COLON 20 Pedidos.DatPedido
    Pedidos.CodCliente   COLON 20 Clientes.NomCliente NO-LABELS
    Clientes.CodEndereco COLON 20
    Clientes.CodCidade   COLON 20 Cidades.NomCidade NO-LABELS
    Pedidos.Observacao   COLON 20 SKIP(1)
    browseItem      AT 3 SKIP(1)
    bt-addItem AT 3
    bt-modItem
    bt-delItem
        WITH SIDE-LABELS THREE-D SIZE 140 BY 22
            VIEW-AS DIALOG-BOX TITLE "Pedidos".
            
DEFINE FRAME f-item
    Itens.CodProduto    COLON 20 Produtos.NomProduto NO-LABELS
    Itens.NumQuantidade COLON 20
    Itens.ValTotal      COLON 20 SKIP
    bt-save AT 3 bt-canc
        WITH SIDE-LABELS THREE-D SIZE 90 BY 15
            VIEW-AS DIALOG-BOX TITLE "Pedidos".

ON CHOOSE OF bt-pri DO:
    GET FIRST qPed.
    RUN piMostra.
END.

ON CHOOSE OF bt-ant DO:
    GET PREV qPed.
    IF AVAILABLE Pedidos THEN
        RUN piMostra.
    ELSE DO:
        GET FIRST qPed.
        RUN piMostra.
    END.
END.

ON CHOOSE OF bt-prox DO:
    GET NEXT qPed.
    IF AVAILABLE Pedidos THEN
        RUN piMostra.
    ELSE DO:
        GET LAST qPed.
        RUN piMostra.
    END.
END.

ON CHOOSE OF bt-ult DO:
    GET LAST qPed.
    RUN piMostra.
END.

ON CHOOSE OF bt-add DO:
    ASSIGN cAction = "add".
    RUN piHabilitaBotoes (INPUT FALSE).
    RUN piHabilitaCampos (INPUT TRUE).

    CLEAR FRAME f-ped.
    DISPLAY NEXT-VALUE(seqPedido) @ Pedidos.CodPedido WITH FRAME f-ped.
END.

ON CHOOSE OF bt-addItem DO:
    RUN c:/treinamento/workspace/projetoFinal/item.p(INPUT Pedidos.CodPedido).
    
    RUN piOpenQuery.
END.

/*ON CHOOSE OF bt-mod DO:                                                            */
/*    ASSIGN cAction = "mod".                                                        */
/*    RUN piHabilitaBotoes (INPUT FALSE).                                            */
/*    RUN piHabilitaCampos (INPUT TRUE).                                             */
/*                                                                                   */
/*    DISPLAY Pedidos.CodCliente WITH FRAME f-ped.                                   */
/*    RUN piMostra.                                                                  */
/*END.                                                                               */
/*                                                                                   */
/*ON CHOOSE OF bt-del DO:                                                            */
/*    DEFINE VARIABLE lConf AS LOGICAL     NO-UNDO.                                  */
/*                                                                                   */
/*    DEFINE BUFFER bCliente FOR Pedidos.                                            */
/*                                                                                   */
/*    MESSAGE "Confirma a eliminacao do cliente " Pedidos.NomCliente "?" UPDATE lConf*/
/*            VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO                              */
/*                TITLE "Elimina‡Æo".                                                */
/*    IF  lConf THEN DO:                                                             */
/*        FIND bPedidos                                                              */
/*            WHERE bPedidos.CodCliente = Pedidos.CodCliente                         */
/*                EXCLUSIVE-LOCK NO-ERROR.                                           */
/*        IF  AVAILABLE bPedidos THEN DO:                                            */
/*            FIND FIRST Pedidos WHERE Pedidos.CodCliente = Pedidos.CodCliente       */
/*                NO-LOCK NO-ERROR.                                                  */
/*            IF AVAILABLE Pedidos THEN                                              */
/*                MESSAGE "Cidade cont‚m Pedidos, opera‡Æo cancelada!"               */
/*                    VIEW-AS ALERT-BOX.                                             */
/*            ELSE DO:                                                               */
/*                DELETE bPedidos.                                                   */
/*                RUN piOpenQuery.                                                   */
/*            END.                                                                   */
/*        END.                                                                       */
/*    END.                                                                           */
/*END.                                                                               */
/*                                                                                   */
ON LEAVE OF Pedidos.CodCliente DO:
    DEFINE VARIABLE lValid AS LOGICAL     NO-UNDO.
    RUN piValidaCliente (INPUT Pedidos.CodCliente:SCREEN-VALUE,
                          OUTPUT lValid).
    IF NOT lValid THEN DO:
        RETURN NO-APPLY.
    END.
    FIND FIRST Cidades WHERE Cidades.CodCidade = Clientes.CodCidade NO-LOCK.
    DISPLAY Clientes.NomCliente
            Clientes.CodEndereco
            Clientes.CodCidade
            Cidades.NomCidade
                WITH FRAME f-ped.
END.

ON CHOOSE OF bt-save IN FRAME f-ped DO:
   IF cAction = "add" THEN DO:
      CREATE bPedidos.
      ASSIGN bPedidos.CodPedido  = INPUT Pedidos.CodPedido.
   END.
   IF  cAction = "mod" THEN DO:
       FIND FIRST bPedidos
            WHERE bPedidos.CodPedido = Pedidos.CodPedido
                EXCLUSIVE-LOCK NO-ERROR.
   END.

   ASSIGN bPedidos.CodCliente  = INPUT Pedidos.CodCliente
          bPedidos.DatPedido   = INPUT Pedidos.DatPedido
          bPedidos.Observacao  = INPUT Pedidos.Observacao.

   RUN piHabilitaBotoes (INPUT TRUE).
   RUN piHabilitaCampos (INPUT FALSE).
   RUN piOpenQuery.
END.

ON CHOOSE OF bt-save IN FRAME f-item DO:
   CREATE bItens.
   ASSIGN bItens.CodProduto  = INPUT Itens.CodProduto
          bItens.NumQuantidade   = INPUT Itens.NumQuantidade.

   RUN piHabilitaBotoes (INPUT TRUE).
   RUN piHabilitaCampos (INPUT FALSE).
   RUN piOpenQuery.
END.
/*                                                                                   */
/*ON CHOOSE OF bt-canc DO:                                                           */
/*    RUN piHabilitaBotoes (INPUT TRUE).                                             */
/*    RUN piHabilitaCampos (INPUT FALSE).                                            */
/*    RUN piMostra.                                                                  */
/*END.                                                                               */
/*                                                                                   */
/*ON CHOOSE OF bt-exp DO:                                                            */
/*    DEFINE VARIABLE cArq AS CHARACTER NO-UNDO.                                     */
/*                                                                                   */
/*    // Arquivo CSV                                                                 */
/*    ASSIGN cArq = SEARCH("Pedidos.p")                                              */
/*           cArq = REPLACE(cArq, "Pedidos.p", "Pedidos.csv").                       */
/*    OUTPUT to value(cArq).                                                         */
/*    FOR EACH Pedidos NO-LOCK:                                                      */
/*        PUT UNFORMATTED                                                            */
/*                Pedidos.CodCidade   ";"                                            */
/*                Pedidos.CodCliente  ";"                                            */
/*                Pedidos.CodEndereco ";"                                            */
/*                Pedidos.NomCliente  ";"                                            */
/*                Pedidos.Observacao  ";".                                           */
/*        PUT UNFORMATTED SKIP.                                                      */
/*    END.                                                                           */
/*    OUTPUT close.                                                                  */
/*                                                                                   */
/*    // Arquivo JSON                                                                */
/*    DEFINE VARIABLE oObj    AS JsonObject NO-UNDO.                                 */
/*    DEFINE VARIABLE oOrd    AS JsonObject NO-UNDO.                                 */
/*    DEFINE VARIABLE aCust   AS JsonArray  NO-UNDO.                                 */
/*    DEFINE VARIABLE aOrders AS JsonArray  NO-UNDO.                                 */
/*                                                                                   */
/*    ASSIGN cArq = REPLACE(cArq, "Pedidos.csv", "Pedidos.json")                     */
/*           aCust = NEW JsonArray().                                                */
/*    FOR EACH Pedidos NO-LOCK:                                                      */
/*        oObj = NEW JsonObject().                                                   */
/*        oObj:add("CodCliente",  Pedidos.CodCliente).                               */
/*        oObj:add("CodCidade",   Pedidos.CodCidade).                                */
/*        oObj:add("CodEndereco", Pedidos.CodEndereco).                              */
/*        oObj:add("NomCliente",  Pedidos.NomCliente).                               */
/*        oObj:add("Observacao",  Pedidos.Observacao).                               */
/*        aCust:add(oObj).                                                           */
/*    END.                                                                           */
/*    aCust:WriteFile(INPUT cArq, INPUT YES, INPUT "UTF-8").                         */
/*                                                                                   */
/*END.                                                                               */

RUN piOpenQuery.
RUN piHabilitaBotoes (INPUT TRUE).
APPLY "choose" TO bt-pri.

WAIT-FOR WINDOW-CLOSE OF FRAME f-ped.

PROCEDURE piMostra:
    IF AVAILABLE Pedidos THEN DO:
        DISPLAY Pedidos.CodPedido  Pedidos.CodCliente Pedidos.DatPedido
                Clientes.CodEndereco Clientes.CodCidade Pedidos.Observacao
                    WITH FRAME f-ped.
        OPEN QUERY qItem FOR EACH Itens WHERE Itens.CodPedido = Pedidos.CodPedido, 
            FIRST Produtos WHERE Itens.CodProduto = Produtos.CodProduto.
    END.
    ELSE DO:
        CLEAR FRAME f-ped.
    END.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID       NO-UNDO.
    
    IF  AVAILABLE Pedidos THEN DO:
        ASSIGN rRecord = ROWID(Pedidos).
        OPEN QUERY qItem FOR EACH Itens WHERE Itens.CodPedido = Pedidos.CodPedido, 
            FIRST Produtos WHERE Itens.CodProduto = Produtos.CodProduto.
    END.
    
    OPEN QUERY qPed FOR EACH Pedidos,
        FIRST Clientes WHERE Clientes.CodCliente = Pedidos.CodCliente.

    REPOSITION qPed TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-ped:
       ASSIGN bt-pri:SENSITIVE     = pEnable
              bt-ant:SENSITIVE     = pEnable
              bt-prox:SENSITIVE    = pEnable
              bt-ult:SENSITIVE     = pEnable
              bt-sair:SENSITIVE    = pEnable
              bt-add:SENSITIVE     = pEnable
              bt-mod:SENSITIVE     = pEnable
              bt-del:SENSITIVE     = pEnable
              bt-exp:SENSITIVE     = pEnable
              browseItem:SENSITIVE = pEnable
              bt-addItem:SENSITIVE = pEnable
              bt-save:SENSITIVE    = NOT pEnable
              bt-canc:SENSITIVE    = NOT pEnable.
    END.
END PROCEDURE.

PROCEDURE piHabilitaCampos:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-ped:
       ASSIGN Pedidos.DatPedido:SENSITIVE  = pEnable
              Pedidos.CodCliente:SENSITIVE   = pEnable
              Pedidos.Observacao:SENSITIVE  = pEnable.
    END.
END PROCEDURE.

PROCEDURE piValidaCliente:
    DEFINE INPUT PARAMETER pCliente AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER pValid AS LOGICAL NO-UNDO INITIAL NO.
   
    FIND FIRST Clientes
        WHERE Clientes.CodCliente = pCliente
        NO-LOCK NO-ERROR.
    IF  NOT AVAILABLE Clientes THEN DO:
        MESSAGE "Cliente  " pCliente " nao existe!"
                VIEW-AS ALERT-BOX ERROR.
        ASSIGN pValid = NO.
    END.
    ELSE 
       ASSIGN pValid = YES.
END PROCEDURE.
