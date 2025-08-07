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
DEFINE BUTTON bt-sair LABEL "Sair" AUTO-ENDKEY.

DEFINE VARIABLE cAction  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lValid   AS LOGICAL     NO-UNDO.

DEFINE QUERY qCli FOR Clientes, Cidades SCROLLING.

DEFINE BUFFER bClientes  FOR Clientes.

DEFINE FRAME f-cli
    bt-pri AT 10
    bt-ant 
    bt-prox 
    bt-ult SPACE(3) 
    bt-add bt-mod bt-del bt-save bt-canc bt-exp SPACE(3)
    bt-sair  SKIP(1)
    Clientes.CodCliente  COLON 20
    Clientes.NomCliente  COLON 20
    Clientes.CodEndereco COLON 20
    Clientes.CodCidade   COLON 20 Cidades.NomCidade NO-LABELS
    Clientes.Observacao  COLON 20
        WITH SIDE-LABELS THREE-D SIZE 120 BY 15
            VIEW-AS DIALOG-BOX TITLE "Clientes".

ON CHOOSE OF bt-pri DO:
    GET FIRST qCli.
    RUN piMostra.
END.

ON CHOOSE OF bt-ant DO:
    GET PREV qCli.
    IF AVAILABLE Clientes THEN
        RUN piMostra.
    ELSE DO:
        GET FIRST qCli.
        RUN piMostra.
    END.
END.

ON CHOOSE OF bt-prox DO:
    GET NEXT qCli.
    IF AVAILABLE Clientes THEN
        RUN piMostra.
    ELSE DO:
        GET LAST qCli.
        RUN piMostra.
    END.
END.

ON CHOOSE OF bt-ult DO:
    GET LAST qCli.
    RUN piMostra.
END.

ON CHOOSE OF bt-add DO:
    ASSIGN cAction = "add".
    RUN piHabilitaBotoes (INPUT FALSE).
    RUN piHabilitaCampos (INPUT TRUE).
   
    CLEAR FRAME f-cli.
    DISPLAY NEXT-VALUE(seqCliente) @ Clientes.CodCliente WITH FRAME f-cli.
END.

ON CHOOSE OF bt-mod DO:
    ASSIGN cAction = "mod".
    RUN piHabilitaBotoes (INPUT FALSE).
    RUN piHabilitaCampos (INPUT TRUE).

    DISPLAY Clientes.CodCliente WITH FRAME f-cli.
    RUN piMostra.
END.

ON CHOOSE OF bt-del DO:
    DEFINE VARIABLE lConf AS LOGICAL     NO-UNDO.

    DEFINE BUFFER bCliente FOR Clientes.

    MESSAGE "Confirma a eliminacao do cliente " Clientes.NomCliente "?" UPDATE lConf
            VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO
                TITLE "Elimina‡Æo".
    IF  lConf THEN DO:
        FIND bClientes
            WHERE bClientes.CodCliente = Clientes.CodCliente
                EXCLUSIVE-LOCK NO-ERROR.
        IF  AVAILABLE bClientes THEN DO:
            FIND FIRST Pedidos WHERE Pedidos.CodCliente = Clientes.CodCliente 
                NO-LOCK NO-ERROR.
            IF AVAILABLE Pedidos THEN
                MESSAGE "Cidade cont‚m clientes, opera‡Æo cancelada!"
                    VIEW-AS ALERT-BOX.
            ELSE DO:
                DELETE bClientes.
                RUN piOpenQuery.
            END.
        END.
    END.
END.

ON LEAVE OF Clientes.CodCidade DO:
    RUN piValidaCidade (INPUT Clientes.CodCidade:SCREEN-VALUE, 
                        OUTPUT lValid).
    IF lValid THEN
        DISPLAY Cidades.NomCidade WITH FRAME f-cli.
    ELSE
        DISPLAY "Cidade nao encontrada" @ Cidades.NomCidade WITH FRAME f-cli.
END.

ON CHOOSE OF bt-save DO:
    RUN piValidaCidade (INPUT Clientes.CodCidade:SCREEN-VALUE, 
                        OUTPUT lValid).
    IF NOT lValid THEN DO:
        MESSAGE "Cidade " INPUT Clientes.CodCidade " nao existe!"
                VIEW-AS ALERT-BOX ERROR.
        RETURN NO-APPLY.
    END.
    IF cAction = "add" THEN DO:
        CREATE bClientes.
        ASSIGN 
            bClientes.CodCliente = INPUT Clientes.CodCliente.
    END.
    IF  cAction = "mod" THEN DO:
        FIND FIRST bClientes
            WHERE bClientes.CodCliente = Clientes.CodCliente
            EXCLUSIVE-LOCK NO-ERROR.
    END.

    ASSIGN 
        bClientes.NomCliente  = INPUT Clientes.NomCliente
        bClientes.CodCidade   = INPUT Clientes.CodCidade
        bClientes.CodEndereco = INPUT Clientes.CodEndereco
        bClientes.Observacao  = INPUT Clientes.Observacao.

    RUN piHabilitaBotoes (INPUT TRUE).
    RUN piHabilitaCampos (INPUT FALSE).
    RUN piOpenQuery.
END.

ON CHOOSE OF bt-canc DO:
    RUN piHabilitaBotoes (INPUT TRUE).
    RUN piHabilitaCampos (INPUT FALSE).
    RUN piMostra.
END.

ON CHOOSE OF bt-exp DO:
    DEFINE VARIABLE cArq AS CHARACTER NO-UNDO.
    
    // Arquivo CSV
    ASSIGN cArq = SEARCH("Clientes.p") 
           cArq = REPLACE(cArq, "Clientes.p", "Clientes.csv").
    OUTPUT to value(cArq).
    FOR EACH Clientes NO-LOCK:
        PUT UNFORMATTED
                Clientes.CodCidade   ";"
                Clientes.CodCliente  ";"
                Clientes.CodEndereco ";"
                Clientes.NomCliente  ";"
                Clientes.Observacao  ";".
        PUT UNFORMATTED SKIP.
    END.
    OUTPUT close.
    
    // Arquivo JSON
    DEFINE VARIABLE oObj    AS JsonObject NO-UNDO.
    DEFINE VARIABLE oOrd    AS JsonObject NO-UNDO.
    DEFINE VARIABLE aCust   AS JsonArray  NO-UNDO.
    DEFINE VARIABLE aOrders AS JsonArray  NO-UNDO.

    ASSIGN cArq = REPLACE(cArq, "Clientes.csv", "Clientes.json")
           aCust = NEW JsonArray().
    FOR EACH Clientes NO-LOCK:
        oObj = NEW JsonObject().
        oObj:add("CodCliente",  Clientes.CodCliente).
        oObj:add("CodCidade",   Clientes.CodCidade).
        oObj:add("CodEndereco", Clientes.CodEndereco).
        oObj:add("NomCliente",  Clientes.NomCliente).
        oObj:add("Observacao",  Clientes.Observacao).
        aCust:add(oObj).
    END.
    aCust:WriteFile(INPUT cArq, INPUT YES, INPUT "UTF-8").
    
END.

RUN piOpenQuery.
RUN piHabilitaBotoes (INPUT TRUE).
APPLY "choose" TO bt-pri.

WAIT-FOR WINDOW-CLOSE OF FRAME f-cli.

PROCEDURE piMostra:
    IF AVAILABLE Clientes THEN DO:
        FIND Cidades WHERE Cidades.CodCidade = Clientes.CodCidade.
        DISPLAY Clientes.CodCidade  Clientes.CodCliente Clientes.CodEndereco
                Clientes.NomCliente Clientes.Observacao Cidades.NomCidade
                    WITH FRAME f-cli.
    END.
    ELSE DO:
        CLEAR FRAME f-cli.
    END.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID       NO-UNDO.
    
    IF  AVAILABLE Clientes THEN DO:
        ASSIGN rRecord = ROWID(Clientes).
    END.
    
    OPEN QUERY qCli FOR EACH Clientes,
        FIRST Cidades WHERE Cidades.CodCidade = Clientes.CodCidade.

    REPOSITION qCli TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-cli:
       ASSIGN bt-pri:SENSITIVE  = pEnable
              bt-ant:SENSITIVE  = pEnable
              bt-prox:SENSITIVE = pEnable
              bt-ult:SENSITIVE  = pEnable
              bt-sair:SENSITIVE = pEnable
              bt-add:SENSITIVE  = pEnable
              bt-mod:SENSITIVE  = pEnable
              bt-del:SENSITIVE  = pEnable
              bt-exp:SENSITIVE  = pEnable
              bt-save:SENSITIVE = NOT pEnable
              bt-canc:SENSITIVE = NOT pEnable.
    END.
END PROCEDURE.

PROCEDURE piHabilitaCampos:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-cli:
       ASSIGN Clientes.NomCliente:SENSITIVE  = pEnable
              Clientes.CodCidade:SENSITIVE   = pEnable
              Clientes.CodEndereco:SENSITIVE = pEnable
              Clientes.Observacao:SENSITIVE  = pEnable.
    END.
END PROCEDURE.

PROCEDURE piValidaCidade:
    DEFINE INPUT PARAMETER pCidade AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER pValid AS LOGICAL NO-UNDO INITIAL NO.
   
    FIND FIRST Cidades
        WHERE Cidades.CodCidade = pCidade
        NO-LOCK NO-ERROR.
    IF  NOT AVAILABLE Cidades THEN
        ASSIGN pValid = NO.
    ELSE 
       ASSIGN pValid = YES.
END PROCEDURE.
