# db-scheme
![Schèmas Base de Données](SchemasBdd.png)


**Client**: Il est posssible de traduire la table client en object. C'est ce que nous avons choisis de faire vu que l'accès à cette entité se fait fréquement. Nous supposons aussi que cette entité joue un role centrale dans la base de données, et que l'accès à cette entité est le plus fréquent. 

L'association **Possède** sera traduite par un champs de type *VARRAY* de taille maximale 3 qui vas contenir les numéros de télephone. Cela implique que l'entité **Téléphone** sera représenté par le type *char*

L'association **Opération** sera représenté par un type **T_Operation** comprenant une référence vers l'Entité **Mouvement** et **CptCourant**. Ce type comprends aussi un champs **Montant** qui sera donc representé par sa valeur numérique. L'entité **Mouvement** sera representé par un type *char*

On a choisit de traduire **CptCourant**, **CptEpargne** et **Compte** en des objets à cause de l'héritage entre **CptCourant** et **Compte** et entre **CptEpargne** et **Compte** avec l'obligation "ou".

Pour la liaison entre **Client** et **CptCourant** on pense que le passage le plus fréquant est celle de **Client** vers **CptCourant**. pour la traduction on va créer un type **T_EstSignataire** avec comme 
attributs ***droit*** de type ***varchar*** et ***CptCourant*** de type ***T_CptCourant***. et on va ajouter un nested table de ***T_EstSignataire*** comme attribut dans T_Client.

```SQL
SELECT * FROM EMP JOIN DEPT ON EMP.DEPTNO = DEPT.DEPTNO;
```