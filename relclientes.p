ASSIGN
    CURRENT-WINDOW:WIDTH = 150.
DEFINE VARIABLE iCont  AS INTEGER NO-UNDO.
DEFINE VARIABLE Cidade LIKE Cidades.NomCidade NO-UNDO.
DEFINE STREAM sRelat.

OUTPUT STREAM sRelat TO "c:/treinamento/workspace/projetoFinal/Relatorio de clientes.txt" PAGE-SIZE 30.

DEFINE FRAME f-cab HEADER
    "Relatorio de Clientes" AT 50
    WITH CENTERED PAGE-TOP WIDTH 150.

/* Inicia a visualiza‡Æo do cabe‡alho */
DISPLAY STREAM sRelat WITH FRAME f-cab.

/* Exibe o cabe‡alho do relat¢rio (r¢tulos das colunas) */
PUT STREAM sRelat UNFORMATTED
    "Codigo" AT 1
    "Nome" AT 8
    "Endereco" AT 25
    "Cidade" AT 55
    "Observacao" AT 75
    SKIP
    .
/* Linha de separa‡Æo */
PUT STREAM sRelat UNFORMATTED
    SKIP
    FILL("-", 6) AT 1
    FILL("-", 15) AT 8
    FILL("-", 25) AT 25
    FILL("-", 10) AT 55
    FILL("-", 15) AT 75
    SKIP
    SKIP
    .

FOR EACH Clientes NO-LOCK:
    FIND FIRST Cidades WHERE Cidades.CodCidade = Clientes.CodCidade NO-ERROR.
    
    IF AVAILABLE Cidades THEN
        ASSIGN
            Cidade = STRING(Cidades.CodCidade) + "-" + Cidades.NomCidade.
    ELSE
        ASSIGN
            Cidade = "Nao encontrado".

    PUT STREAM sRelat UNFORMATTED
        Clientes.CodCliente AT 1 FORMAT(">>>>>9")
        Clientes.NomCliente AT 8
        Clientes.CodEndereco AT 25
        Cidade AT 55
        Clientes.Observacao AT 75
        SKIP
        .
    
    ASSIGN
        iCont = iCont + 1.
END.

OUTPUT STREAM sRelat CLOSE.
OS-COMMAND NO-WAIT VALUE("notepad c:/treinamento/workspace/projetoFinal/Relatorio de clientes.txt").
