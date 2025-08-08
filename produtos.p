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

DEFINE QUERY qProd FOR Produtos SCROLLING.

DEFINE BUFFER bProdutos FOR Produtos.

DEFINE FRAME f-prod
    bt-pri AT 10
    bt-ant 
    bt-prox 
    bt-ult SPACE(3) 
    bt-add bt-mod bt-del bt-save bt-canc bt-exp SPACE(3)
    bt-sair  SKIP(1)
    Produtos.CodProduto COLON 20
    Produtos.NomProduto COLON 20
    Produtos.ValProduto COLON 20
    WITH SIDE-LABELS THREE-D SIZE 120 BY 15
    VIEW-AS DIALOG-BOX TITLE "Produtos".

ON CHOOSE OF bt-pri 
    DO:
        GET FIRST qProd.
        RUN piMostra.
    END.

ON CHOOSE OF bt-ant 
    DO:
        GET PREV qProd.
        IF AVAILABLE Produtos THEN
            RUN piMostra.
        ELSE 
        DO:
            GET FIRST qProd.
            RUN piMostra.
        END.
    END.

ON CHOOSE OF bt-prox 
    DO:
        GET NEXT qProd.
        IF AVAILABLE Produtos THEN
            RUN piMostra.
        ELSE 
        DO:
            GET LAST qProd.
            RUN piMostra.
        END.
    END.

ON CHOOSE OF bt-ult 
    DO:
        GET LAST qProd.
        RUN piMostra.
    END.

ON CHOOSE OF bt-add 
    DO:
        ASSIGN 
            cAction = "add".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).
   
        CLEAR FRAME f-prod.
        DISPLAY NEXT-VALUE(seqProduto) @ Produtos.CodProduto WITH FRAME f-prod.
    END.

ON CHOOSE OF bt-mod 
    DO:
        ASSIGN 
            cAction = "mod".
        RUN piHabilitaBotoes (INPUT FALSE).
        RUN piHabilitaCampos (INPUT TRUE).

        DISPLAY Produtos.CodProduto WITH FRAME f-prod.
        RUN piMostra.
    END.

ON CHOOSE OF bt-del 
    DO:
        DEFINE VARIABLE lConf AS LOGICAL NO-UNDO.

        DEFINE BUFFER bProdutos FOR Produtos.

        MESSAGE "Confirma a eliminacao do produto " Produtos.NomProduto "?" UPDATE lConf
            VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO
            TITLE "Eliminacao".
        IF  lConf THEN 
        DO:
            FIND bProdutos
                WHERE bProdutos.CodProduto = Produtos.CodProduto
                EXCLUSIVE-LOCK NO-ERROR.
            IF  AVAILABLE bProdutos THEN 
            DO:
                FIND FIRST Itens WHERE Itens.CodProduto = Produtos.CodProduto
                    NO-LOCK NO-ERROR.
                IF AVAILABLE Itens THEN
                    MESSAGE "Produto tem pedidos pendentes, opera‡Æo cancelada!"
                        VIEW-AS ALERT-BOX.
                ELSE 
                DO:
                    DELETE bProdutos.
                    RUN piOpenQuery.
                    APPLY 'choose' TO bt-pri.
                END.
            END.
        END.
    END.

ON CHOOSE OF bt-save 
    DO:
        IF cAction = "add" THEN 
        DO:
            CREATE bProdutos.
            ASSIGN 
                bProdutos.CodProduto = INPUT Produtos.CodProduto.
        END.
        IF  cAction = "mod" THEN 
        DO:
            FIND FIRST bProdutos
                WHERE bProdutos.CodProduto = Produtos.CodProduto
                EXCLUSIVE-LOCK NO-ERROR.
        END.

        ASSIGN 
            bProdutos.NomProduto = INPUT Produtos.NomProduto
            bProdutos.ValProduto = INPUT Produtos.ValProduto.

        RUN piHabilitaBotoes (INPUT TRUE).
        RUN piHabilitaCampos (INPUT FALSE).
        RUN piOpenQuery.
        IF cAction = "add" THEN
            APPLY 'choose' TO bt-ult.
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
    
        FIND bProdutos WHERE bProdutos.CodProduto = Produtos.CodProduto.
    
    // Arquivo CSV
        ASSIGN 
            cArq = SEARCH("Produtos.p") 
            cArq = REPLACE(cArq, "Produtos.p", "Produtos.csv").
        OUTPUT to value(cArq).
        FOR EACH Produtos NO-LOCK:
            PUT UNFORMATTED
                Produtos.CodProduto ";"
                Produtos.NomProduto ";"
                Produtos.ValProduto    ";".
            PUT UNFORMATTED SKIP.
        END.
        OUTPUT close.
    
    // Arquivo JSON
        DEFINE VARIABLE oObj  AS JsonObject NO-UNDO.
        DEFINE VARIABLE aProd AS JsonArray  NO-UNDO.

        ASSIGN 
            cArq  = REPLACE(cArq, "Produtos.csv", "Produtos.json")
            aProd = NEW JsonArray().
        FOR EACH Produtos NO-LOCK:
            oObj = NEW JsonObject().
            oObj:add("CodProduto", Produtos.CodProduto).
            oObj:add("NomProduto", Produtos.NomProduto).
            oObj:add("ValProduto",     Produtos.ValProduto).
            aProd:add(oObj).
        END.
        aProd:WriteFile(INPUT cArq, INPUT YES, INPUT "UTF-8").
    
        FIND Produtos WHERE Produtos.CodProduto = bProdutos.CodProduto.
        RUN piMostra.
    END.

RUN piOpenQuery.
RUN piHabilitaBotoes (INPUT TRUE).
APPLY "choose" TO bt-pri.

WAIT-FOR WINDOW-CLOSE OF FRAME f-prod.

PROCEDURE piMostra:
    IF AVAILABLE Produtos THEN 
    DO:
        DISPLAY Produtos.CodProduto Produtos.NomProduto Produtos.ValProduto 
            WITH FRAME f-prod.
    END.
    ELSE 
    DO:
        CLEAR FRAME f-prod.
    END.
END PROCEDURE.

PROCEDURE piOpenQuery:
    DEFINE VARIABLE rRecord AS ROWID NO-UNDO.
    
    IF  AVAILABLE Produtos THEN 
    DO:
        ASSIGN 
            rRecord = ROWID(Produtos).
    END.
    
    OPEN QUERY qProd FOR EACH Produtos.

    REPOSITION qProd TO ROWID rRecord NO-ERROR.
END PROCEDURE.

PROCEDURE piHabilitaBotoes:
    DEFINE INPUT PARAMETER pEnable AS LOGICAL NO-UNDO.

    DO WITH FRAME f-prod:
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

    DO WITH FRAME f-prod:
        ASSIGN 
            Produtos.NomProduto:SENSITIVE = pEnable
            Produtos.ValProduto:SENSITIVE = pEnable.
    END.
END PROCEDURE.
