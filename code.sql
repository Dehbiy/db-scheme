DROP TABLE Clients;

-- Drop types if they exist
DROP TYPE T_Client;
DROP TYPE NT_EstProprietaire;
DROP TYPE NT_Operation;
DROP TYPE NT_EstSignataire;
DROP TYPE T_Possede;
DROP TYPE T_EstSignataire;
DROP TYPE T_Operation;
DROP TYPE T_CptCourant;
DROP TYPE T_CptEpargne;
DROP TYPE T_Compte;

-- Recreate types
CREATE OR REPLACE TYPE T_Compte AS OBJECT (
    NCompte VARCHAR2(20),
    Solde INTEGER,
    DateOuv DATE
) NOT FINAL;
/
CREATE OR REPLACE TYPE T_CptEpargne UNDER T_Compte (
    Taux FLOAT
) NOT FINAL;
/
CREATE OR REPLACE TYPE T_CptCourant UNDER T_Compte (
    NbMouvements INTEGER
) NOT FINAL;
/
CREATE OR REPLACE TYPE T_Operation AS OBJECT (
    DateMouv DATE,
    CptCourant T_CptCourant,
    Montant INTEGER
) NOT FINAL;
/
CREATE OR REPLACE TYPE T_EstSignataire AS OBJECT (
    Droit VARCHAR(40),
    CptCourant T_CptCourant
) NOT FINAL;
/
CREATE OR REPLACE TYPE T_Possede AS VARRAY(3) OF CHAR(10);
/
CREATE OR REPLACE TYPE NT_EstProprietaire AS TABLE OF T_Compte;
/
CREATE OR REPLACE TYPE NT_EstSignataire AS TABLE OF T_EstSignataire;
/
CREATE OR REPLACE TYPE NT_Operation AS TABLE OF T_Operation;
/
create or REPLACE TYPE T_Client as OBJECT (
        NClient INTEGER,
        Nom varchar(747),
        Adresse varchar(700),
        Email VARCHAR(757),
        EstSignataire NT_EstSignataire,
        Possede T_Possede,
        Operation NT_Operation,
        EstProprietaire NT_EstProprietaire,
        MEMBER PROCEDURE add_account(account_to_add T_Compte),
        MEMBER PROCEDURE add_operation(operation_to_add T_Operation)
) not final;
/
-- Recreate procedure
CREATE OR REPLACE TYPE BODY T_Client AS
    MEMBER PROCEDURE add_account(account_to_add T_Compte) IS
    BEGIN
        IF EstProprietaire IS NULL THEN
            EstProprietaire := NT_EstProprietaire();
        END IF;
        EstProprietaire.EXTEND;
        EstProprietaire(EstProprietaire.LAST) := account_to_add;
    END;
    
    MEMBER PROCEDURE add_operation(operation_to_add T_Operation) IS
    BEGIN
        IF Operation IS NULL THEN
            Operation := NT_Operation();
        END IF;
        Operation.EXTEND;
        Operation(Operation.LAST) := operation_to_add;
    END;
END;
/


-- Recreate table
CREATE TABLE Clients OF T_Client (
    NClient PRIMARY KEY
)
NESTED TABLE EstSignataire STORE AS LesSignataires,
NESTED TABLE Operation STORE AS LesOperations,
NESTED TABLE EstProprietaire STORE AS LesProprietaire;



INSERT INTO Clients VALUES (
    T_Client(
        56, 
        'Paturel',
        'Port-Royal – Paris',
        NULL,
        NT_EstSignataire(),
        T_Possede('0447569816'), 
        NT_Operation(),
        NT_EstProprietaire()
    )
);
/


DECLARE
    -- Variables to hold client and account objects
    v_client T_Client;
    v_new_account T_Compte;
BEGIN
    -- Create a new account instance
    -- Replace with T_CptEpargne or T_CptCourant if needed
    v_new_account := T_Compte('CC56', 0, SYSDATE);  -- Example values

    -- Select the client object from the database
    SELECT VALUE(c) INTO v_client
    FROM Clients c
    WHERE c.NClient = 56;  -- Assuming the client ID is 1

    -- Add the new account to the client's EstProprietaire collection
    v_client.add_account(v_new_account);
    
    UPDATE Clients SET EstProprietaire = v_client.EstProprietaire
    WHERE NClient = 56;
END;
/

DECLARE
    -- Variables to hold client and account objects
    v_client T_Client;
    v_new_operation T_Operation;
    v_compte T_Compte;
BEGIN
        -- Select the client object from the database
    SELECT VALUE(c) INTO v_client
    FROM Clients c
    WHERE c.NClient = 56;  -- Assuming the client ID is 1
    
        -- Select the client object from the database
    SELECT VALUE(a) INTO v_compte
    FROM TABLE(v_client.estproprietaire) a
    WHERE a.Ncompte = 'CC56';  -- Assuming the client ID is 1
    
    v_new_operation := T_Operation(null, v_compte, 50);  -- Example values



    -- Add the new account to the client's EstProprietaire collection
    v_client.add_operation(v_new_operation);
    
    UPDATE Clients SET EstProprietaire = v_client.EstProprietaire
    WHERE NClient = 56;
END;
/
------------------------------------------------------------------------------

select * from clients;