# db-scheme
![Schèmas Base de Données](SchemasBdd.png)

# Question1

**Client**: Il est posssible de traduire la table client en object. C'est ce que nous avons choisis de faire vu que l'accès à cette entité se fait fréquement. Nous supposons aussi que cette entité joue un role centrale dans la base de données, et que l'accès à cette entité est le plus fréquent. 

L'association **Possède** sera traduite par un champs de type *VARRAY* de taille maximale 3 qui vas contenir les numéros de télephone. Cela implique que l'entité **Téléphone** sera représenté par le type *char*

L'association **Opération** sera représenté par un type **T_Operation** comprenant une référence vers l'Entité **Mouvement** et **CptCourant**. Ce type comprends aussi un champs **Montant** qui sera donc representé par sa valeur numérique. L'entité **Mouvement** sera representé par un type *char*

On a choisit de traduire **CptCourant**, **CptEpargne** et **Compte** en des objets à cause de l'héritage entre **CptCourant** et **Compte** et entre **CptEpargne** et **Compte** avec l'obligation "ou".

Pour la liaison entre **Client** et **CptCourant** on pense que le passage le plus fréquant est celle de **Client** vers **CptCourant**. pour la traduction on va créer un type **T_EstSignataire** avec comme 
attributs ***droit*** de type ***varchar*** et ***CptCourant*** de type ***T_CptCourant***. et on va ajouter un nested table de ***T_EstSignataire*** comme attribut dans T_Client.

# Question2

```SQL

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
        MEMBER PROCEDURE add_operation(operation_to_add T_Operation)
) not final;
/
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
END;
/


-- Recreate table
CREATE TABLE Clients OF T_Client (
    NClient PRIMARY KEY
)
NESTED TABLE EstSignataire STORE AS LesSignataires,
NESTED TABLE Operation STORE AS LesOperations,
NESTED TABLE EstProprietaireCourant STORE AS LesProprietaireCourant,
NESTED TABLE EstProprietaireEpargne STORE AS LesProprietaireEpargne;
```

# Question2

## a)

```SQL
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
```

## b)
```SQL
DECLARE
    
    v_client T_Client;
    v_new_account T_Compte;
BEGIN
    
    v_new_account := T_CptCourant('CC56', 0, SYSDATE,0);  

    
    SELECT VALUE(c) INTO v_client
    FROM Clients c
    WHERE c.NClient = 56;  -- 

   
    v_client.add_account(v_new_account,true);
    
    UPDATE Clients SET EstProprietaireCourant = v_client.EstProprietaireCourant
    WHERE NClient = 56;
END;
/
```

## C)
```SQL
DECLARE
    
    v_client T_Client;
    v_new_operation T_Operation;
    v_compte T_CptCourant;
BEGIN
      
    SELECT VALUE(c) INTO v_client
    FROM Clients c
    WHERE c.NClient = 56;  
    
    SELECT VALUE(a) INTO v_compte
    FROM TABLE(v_client.estproprietaireCourant) a
    WHERE a.Ncompte = 'CC56';  
    
    v_new_operation := T_Operation(null, v_compte, 50);  



    
    v_client.add_operation(v_new_operation);
    
    UPDATE Clients SET OPERATION = v_client.OPERATION
    WHERE NClient = 56;
END;
/
```
# Question 4
```SQL

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
```

# Question 5

## 1)
```SQL
SELECT NClient, Nom, Adresse, Email
FROM Clients;
```

## 2)
```SQL
SELECT 
    a.NCompte AS "Numéro de compte", 
    a.Solde AS "Solde",
    a.DateOuv AS "Date d'ouverture",
    a.Taux AS "Taux d'intérêt"
FROM 
    Clients c, 
    TABLE(c.EstProprietaireEpargne) a;
```

## 3)
```SQL
SELECT 
    a.NCompte AS "Numéro de compte", 
    a.Solde AS "Solde",
    a.NbMouvements AS "Nombre d'opérations CB"
FROM 
    Clients c, 
    TABLE(c.EstProprietaireCourant) a
WHERE 
    c.NClient = 4;
```

## 4)
```SQL
SELECT 
    c.NClient AS "Numéro",
    c.Nom AS "Nom",
    c.Adresse AS "Adresse"
FROM 
    Clients c
WHERE 
    TREAT(VALUE(c) AS T_Client).nbCepargne() = 1;
```

## 5)
```SQL
SELECT 
    c.NClient AS "Numéro",
    c.Nom AS "Nom",
    TREAT(VALUE(c) AS T_Client).nbCepargne() AS "Nombre de comptes épargne"
FROM 
    Clients c;
```

## 6)
```SQL
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
```

## 7)
```SQL
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
```

## 8)
```SQL
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
```

## 9)
```SQL
SELECT 
    p.COLUMN_VALUE AS "Numéro de téléphone"
FROM 
    Clients c,
    TABLE(c.Possede) p
WHERE 
    c.NClient = 56;
```

## 10)
```SQL
SELECT 
    c.NClient AS "Numéro",
    c.Adresse AS "Adresse",
    es.Droit AS "Droit"
FROM 
    Clients c,
    TABLE(c.EstSignataire) es
WHERE 
    es.CptCourant.NCompte = 'CC7';
```