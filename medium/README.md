# Import Medium

## Mode d'emploi

### Importer

1. Demander une archive depuis Medium (cela prend quelques minutes).
2. Télécharger le fichier, le dézipper
3. Copier le contenu du dossier `posts` dans imported

### Convertir

```
ruby bin/convert.rb
```

Pour convertir 1 seul article

```
ruby bin/convert.rb 2014-09-14_Renversons-l-apprentissage---1043e59ff89f
```

### Expoter

Remplir le fichier .env

```
ruby bin/export.rb
```

Pour exporter 1 seul article

```
ruby bin/export.rb 2d4498f2e6aa
```