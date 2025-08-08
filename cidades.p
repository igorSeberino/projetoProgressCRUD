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

DEFINE VARIABLE cAction AS CHARACTER NO-UNDO.

DEFINE QUERY qCid FOR Cidades SCROLLING.

DEFINE BUFFER bCidades FOR Cidades.

DEFINE FRAME f-cid
    bt-pri AT 10
    bt-ant 
    bt-prox 
    bt-ult SPACE(3) 
    bt-add bt-mod bt-del bt-save bt-canc bt-exp SPACE(3)
    bt-sair  SKIP(1)
    Cidades.CodCidade  COLON 20
    Cidades.CodUF     COLON 20
    Cidades.NomCidade COLON 20
    WITH SIDE-LABELS THREE-D SIZE 120 BY 15
    VIEW-AS DIALOG-BOX TITLE "Cidades".

ON CHOOSE OF bt-pri 
    DO:
        GET FIRST qCid.
        RUN piMostra.
    END.

ON CHOOSE OF bt-ant 
    DO:
        GET PREV qCid.
        IF AVAILABLE Cidades THEN
            RUN piMostra.
        ELSE 
        DO:
            GET FIRST qCid.
            RUN piMostra.
        END.
    END.

ON CHOOSE OF bt-prox 
    DO:
        GET NEXT qCid.
        IF AVAILABLE Cidades THEN
            RUN piMostra.
        ELSE 
        DO:
            GET LAST qCid.
            RUN piMostra.
        END.
    END.

ON CHOOSE OF bt-ult 
    DO:
        GET LAST qCid.
        RUN piMostra.
    END.

ON CHOOSE OF bt-add 
    DO:
        ASSIGN 
            cAction = "add".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
   
        CLEAR FRAME f-cid.
        DISPLAY NEXT-VALUE(seqCidade) @ Cidades.CodCidade WITH FRAME f-cid.
    END.

ON CHOOSE OF bt-mod 
    DO:
        ASSIGN 
            cAction = "mod".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).

        DISPLAY Cidades.CodCidade WITH FRAME f-cid.
        RUN piMostra.
    END.

ON CHOOSE OF bt-del 
    DO:
        DEFINE VARIABLE lConf AS LOGICAL NO-UNDO.

        DEFINE BUFFER bCidade FOR Cidades.

        MESSAGE "Confirma a eliminacao da cidade" Cidades.NomCidade "?" UPDATE lConf
            VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO
            TITLE "Eliminacao".
        IF  lConf THEN 
        DO:
            FIND bCidades
                WHERE bCidades.CodCidade = Cidades.CodCidade
                EXCLUSIVE-LOCK NO-ERROR.
            IF  AVAILABLE bCidades THEN 
            DO:
                FIND FIRST Clientes WHERE Clientes.CodCidade = Cidades.CodCidade 
                    NO-LOCK NO-ERROR.
                IF AVAILABLE Clientes THEN
                    MESSAGE "Cidade contem clientes, operacao cancelada!"
                        VIEW-AS ALERT-BOX.
                ELSE 
                DO:
                    DELETE bCidades.
                    RUN piOpenQuery.
                    APPLY "choose" TO bt-pri.
                END.
            END.
        END.
    END.

ON CHOOSE OF bt-save 
    DO:
        IF cAction = "add" THEN 
        DO:
            CREATE bCidades.
            ASSIGN 
                bCidades.CodCidade = INPUT Cidades.CodCidade.
        END.
        IF  cAction = "mod" THEN 
        DO:
            FIND FIRST bCidades
                WHERE bCidades.CodCidade = Cidades.CodCidade
                EXCLUSIVE-LOCK NO-ERROR.
        END.

        ASSIGN 
            bCidades.NomCidade = INPUT Cidades.NomCidade
            bCidades.CodUf     = upper(INPUT Cidades.CodUF).

        RUN piHabilitaBotoes (INPUT TRUE).
        RUN piHabilitaCampos (INPUT FALSE).
        RUN piOpenQuery.
        IF cAction = "add" THEN 
            APPLY 'choose' TO bt-ult.
        ELSE
            APPLY 'choose' TO bt-prox.
    END.

ON CHOOSE OF bt-canc 
    DO:
        RUN piHabilitaBotoes (INPUT TRUE).
        RUN piHabilitaCampos (INPUT FALSE).
        RUN piMostra.
    END.

ON CHOOSE OF bt-exp 
    DO:
        DEFINE VARIABLE cArq AS CHARACTER NO-UNDO.
    
        FIND bCidades WHERE bCidades.CodCidade = Cidades.CodCidade.
    
    // Arquivo CSV
        ASSIGN 
            cArq = SEARCH("Cidades.p") 
            cArq = REPLACE(cArq, "Cidades.p", "Cidades.csv").
        OUTPUT to value(cArq).
        FOR EACH Cidades NO-LOCK:
            PUT UNFORMATTED
                Cidades.CodCidade ";"
                Cidades.NomCidade ";"
                Cidades.CodUF    ";".
            PUT UNFORMATTED SKIP.
        END.
        OUTPUT close.
    
    // Arquivo JSON
        DEFINE VARIABLE oObj    AS JsonObject NO-UNDO.
        DEFINE VARIABLE oOrd    AS JsonObject NO-UNDO.
        DEFINE VARIABLE aCust   AS JsonArray  NO-UNDO.
        DEFINE VARIABLE aOrders AS JsonArray  NO-UNDO.

        ASSIGN 
            cArq  = REPLACE(cArq, "Cidades.csv", "Cidades.json")
            aCust = NEW JsonArray().
        FOR EACH Cidades NO-LOCK:
            oObj = NEW JsonObject().
            oObj:add("CodCidade", Cidades.CodCidade).
            oObj:add("NomCidade", Cidades.NomCidade).
            oObj:add("CodUF",     Cidades.CodUF).
            aCust:add(oObj).
        END.
        aCust:WriteFile(INPUT cArq, INPUT YES, INPUT "UTF-8").
    
        FIND Cidades WHERE Cidades.CodCidade = bCidades.CodCidade.
        RUN piMostra.
    END.

RUN piOpenQuery.
RUN piHabilitaBotoes (INPUT TRUE).
APPLY "choose" TO bt-pri.

WAIT-FOR WINDOW-CLOSE OF FRAME f-cid.

PROCEDURE piMostra:
    IF AVAILABLE Cidades THEN 
    DO:
        DISPLAY Cidades.CodCidade Cidades.NomCidade Cidades.CodUF
            WITH FRAME f-cid.
    END.
    ELSE 
    DO:
        CLEAR FRAME f-cid.
    END.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID NO-UNDO.
    
    IF  AVAILABLE Cidades THEN 
    DO:
        ASSIGN 
            rRecord = ROWID(Cidades).
    END.
    
    OPEN QUERY qCid FOR EACH Cidades.

    REPOSITION qCid TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-cid:
        ASSIGN 
            bt-pri:SENSITIVE  = pEnable
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

    DO WITH FRAME f-cid:
        ASSIGN 
            Cidades.NomCidade:SENSITIVE = pEnable
            Cidades.CodUF:SENSITIVE     = pEnable.
    END.
END PROCEDURE.
