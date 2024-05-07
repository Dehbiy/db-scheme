DROP TABLE Clients;

-- Drop types if they exist
DROP TYPE T_Client;
DROP TYPE NT_EstProprietaireCourant;
DROP TYPE NT_EstProprietaireEpargne;
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
    NbMouvements INTEGER,
    MEMBER FUNCTION nbSignataire RETURN INTEGER,
    MEMBER FUNCTION estTitulaire(numClient INTEGER) RETURN BOOLEAN
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
CREATE OR REPLACE TYPE NT_EstProprietaireCourant AS TABLE OF T_CptCourant;
/
CREATE OR REPLACE TYPE NT_EstProprietaireEpargne AS TABLE OF T_CptEpargne;
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
        EstProprietaireCourant NT_EstProprietaireCourant,
        EstProprietaireEpargne NT_EstProprietaireEpargne,
        MEMBER PROCEDURE add_account(account_to_add T_Compte, isCourant boolean),
        MEMBER PROCEDURE add_operation(operation_to_add T_Operation),
        MEMBER fUNCTION nbCepargne RETURN INTEGER
) not final;
/

CREATE TABLE Clients OF T_Client (
    NClient PRIMARY KEY
)
NESTED TABLE EstSignataire STORE AS LesSignataires,
NESTED TABLE Operation STORE AS LesOperations,
NESTED TABLE EstProprietaireCourant STORE AS LesProprietaireCourant,
NESTED TABLE EstProprietaireEpargne STORE AS LesProprietaireEpargne;


-- Recreate procedure
CREATE OR REPLACE TYPE BODY T_Client AS
    MEMBER PROCEDURE add_account(account_to_add T_Compte,  isCourant boolean) IS
    BEGIN
        IF isCourant then
            IF EstProprietaireCourant IS NULL THEN
                EstProprietaireCourant := NT_EstProprietaireCourant();
            END IF;
            EstProprietaireCourant.EXTEND;
            EstProprietaireCourant(EstProprietaireCourant.LAST) := TREAT(account_to_add AS T_CptCourant);
        else
            IF EstProprietaireEpargne IS NULL THEN
                EstProprietaireEpargne := NT_EstProprietaireEpargne();
            END IF;
            EstProprietaireEpargne.EXTEND;
            EstProprietaireEpargne(EstProprietaireEpargne.LAST) := TREAT(account_to_add AS T_CptEpargne);
        END IF;
    END;
    
    MEMBER PROCEDURE add_operation(operation_to_add T_Operation) IS
    BEGIN
        IF Operation IS NULL THEN
            Operation := NT_Operation();
        END IF;
        Operation.EXTEND;
        Operation(Operation.LAST) := operation_to_add;
    END;
    
    MEMBER fUNCTION nbCepargne RETURN INTEGER IS
    BEGIN
        RETURN EstProprietaireEpargne.COUNT();
    END;
END;
/

CREATE OR REPLACE TYPE BODY T_CptCourant AS
    MEMBER FUNCTION nbSignataire RETURN INTEGER IS
        counter INTEGER := 0;
    BEGIN
        FOR rec IN (
            SELECT 1
            FROM Clients c, TABLE(c.EstSignataire) e
            WHERE e.CptCourant.NCompte = SELF.NCompte
        ) LOOP
            counter := counter + 1;
        END LOOP;
        RETURN counter;
    END;
    
    MEMBER FUNCTION estTitulaire(numClient INTEGER) RETURN BOOLEAN IS
    BEGIN
        FOR rec IN (
            SELECT 1
            FROM Clients c, TABLE(c.ESTPROPRIETAIRECOURANT) e
            WHERE c.NClient = numClient  AND e.NCompte = SELF.NCompte
        ) LOOP
            RETURN TRUE;
        END LOOP;
        RETURN FALSE;
    END;
END;
/


-- Recreate table




INSERT INTO Clients VALUES (
    T_Client(
        56, 
        'Paturel',
        'Port-Royal – Paris',
        NULL,
        NT_EstSignataire(),
        T_Possede('0447569816'), 
        NT_Operation(),
        NT_EstProprietaireCourant(),
        NT_EstProprietaireEpargne()
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
    v_new_account := T_CptCourant('CC56', 0, SYSDATE,0);  -- Example values

    -- Select the client object from the database
    SELECT VALUE(c) INTO v_client
    FROM Clients c
    WHERE c.NClient = 56;  -- Assuming the client ID is 1

   
    v_client.add_account(v_new_account,true);
    
    UPDATE Clients SET EstProprietaireCourant = v_client.EstProprietaireCourant
    WHERE NClient = 56;
END;
/

DECLARE
    v_client T_Client;
    v_new_operation T_Operation;
    v_compte T_CptCourant;
    v_is_titular BOOLEAN; -- Variable to hold the return value
BEGIN
    -- Select the client object from the database
    SELECT VALUE(c) INTO v_client
    FROM Clients c
    WHERE c.NClient = 56;

    -- Select the client's current account object
    SELECT VALUE(a) INTO v_compte
    FROM TABLE(v_client.estproprietaireCourant) a
    WHERE a.NCompte = 'CC56';

    -- Create a new operation instance
    v_new_operation := T_Operation(SYSDATE, v_compte, 50);

    -- Add the new operation to the client
    v_client.add_operation(v_new_operation);
    
    -- Save the changes to the operation table
    UPDATE Clients SET OPERATION = v_client.OPERATION
    WHERE NClient = 56;

    -- Use the estTitulaire function to check if the client is titular and store the result
    v_is_titular := v_compte.estTitulaire(55);

    -- Optional: Do something with the result, e.g., output to dbms_output for debugging
    IF v_is_titular THEN
        DBMS_OUTPUT.PUT_LINE('Client is titular.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Client is not titular.');
    END IF;
END;
/

------------------------------------------------------------------------------


SELECT NClient, Nom, Adresse, Email
FROM Clients;

SELECT 
    a.NCompte AS "Numéro de compte", 
    a.Solde AS "Solde",
    a.DateOuv AS "Date d'ouverture",
    a.Taux AS "Taux d'intérêt"
FROM 
    Clients c, 
    TABLE(c.EstProprietaireEpargne) a;
    
SELECT 
    a.NCompte AS "Numéro de compte", 
    a.Solde AS "Solde",
    a.NbMouvements AS "Nombre d'opérations CB"
FROM 
    Clients c, 
    TABLE(c.EstProprietaireCourant) a
WHERE 
    c.NClient = 4;
    
SELECT 
    c.NClient AS "Numéro",
    c.Nom AS "Nom",
    c.Adresse AS "Adresse"
FROM 
    Clients c
WHERE 
    TREAT(VALUE(c) AS T_Client).nbCepargne() = 1;

SELECT 
    c.NClient AS "Numéro",
    c.Nom AS "Nom",
    TREAT(VALUE(c) AS T_Client).nbCepargne() AS "Nombre de comptes épargne"
FROM 
    Clients c;

SELECT 
    c.NClient AS "Numéro",
    c.Nom AS "Nom",
    TREAT(VALUE(c) AS T_Client).nbCepargne() AS "Nombre de comptes épargne"
FROM 
    Clients c
WHERE 
    TREAT(VALUE(c) AS T_Client).nbCepargne() = (
        SELECT MAX(TREAT(VALUE(c_inner) AS T_Client).nbCepargne())
        FROM Clients c_inner
    );

SELECT 
    c.NClient AS "Numéro",
    c.Nom AS "Nom",
    o.DateMouv AS "Date",
    o.Montant AS "Montant"
FROM 
    Clients c,
    TABLE(c.Operation) o
WHERE 
    o.CptCourant.NCompte = 'CC7';


SELECT 
    o.CptCourant.NCompte AS "Numéro de compte",
    o.DateMouv AS "Date",
    o.Montant AS "Montant"
FROM 
    Clients c,
    TABLE(c.Operation) o
WHERE 
    o.CptCourant.NCompte = 'CC7'
    AND NOT EXISTS (
        SELECT 1
        FROM TABLE(c.EstProprietaireCourant) pc
        WHERE pc.NCompte = 'CC7'
    );
    
SELECT 
    p.COLUMN_VALUE AS "Numéro de téléphone"
FROM 
    Clients c,
    TABLE(c.Possede) p
WHERE 
    c.NClient = 56;

SELECT 
    c.NClient AS "Numéro",
    c.Adresse AS "Adresse",
    es.Droit AS "Droit"
FROM 
    Clients c,
    TABLE(c.EstSignataire) es
WHERE 
    es.CptCourant.NCompte = 'CC7';




