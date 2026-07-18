# antiword-wasm

[antiword](https://github.com/grobian/antiword) 0.37 compilé en WebAssembly.
Convertit les documents Word 97-2003 (`.doc`, format binaire OLE2) en DocBook XML
**dans le navigateur** : pas de serveur, pas de téléchargement sur le poste, le
document ne quitte jamais l'onglet.

## Utilisation

```html
<script src="https://cdn.jsdelivr.net/gh/UTILISATEUR/antiword-wasm@main/antiword.js"></script>
<script>
const lines = [];
const mod = await createAntiword({ print: t => lines.push(t), noInitialRun: true });
mod.FS.writeFile('/in.doc', bytes);          // bytes = Uint8Array du .doc
const rc = mod.callMain(['-m', 'UTF-8.txt', '-x', 'db', '/in.doc']);
const docbook = lines.join('\n');            // rc === 0 si OK
</script>
```

Dans un userscript : `// @require https://cdn.jsdelivr.net/gh/UTILISATEUR/antiword-wasm@main/antiword.js`

### Notes

- **Une instance par document.** antiword s'appuie sur des variables globales C ;
  réutiliser le module pour un second fichier donne des résultats douteux.
- **Vérifier la signature OLE2** (`d0 cf 11 e0 a1 b1 1a e1`) avant d'appeler :
  antiword ne traite pas les `.docx` (pour ceux-là, voir *mammoth.js*).
- Sortie texte : `-t` au lieu de `-x db`.

## Contenu

| Fichier | Rôle |
|---|---|
| `antiword.js` | Artefact : wasm + ressources embarqués en base64 (`-sSINGLE_FILE=1`) |
| `build-antiword-wasm.sh` | Reproduit intégralement le build depuis les sources amont |

## Build

```bash
./build-antiword-wasm.sh
```

Installe emsdk si nécessaire, clone antiword, compile, produit `antiword.js`.

Seules deux ressources d'antiword sont embarquées, dans `/usr/share/antiword`
du système de fichiers virtuel (4,8 Ko au lieu des 412 Ko du dossier `Resources`) :

- `UTF-8.txt` — table de correspondance des caractères. **Obligatoire** : sans
  elle antiword refuse de convertir et affiche son usage.
- `fontnames` — table des polices. Facultative, mais son absence provoque un
  avertissement sur `stderr`.

## Licence

antiword est publié sous **GNU General Public License v2** par Adri van Os.
Ce dépôt redistribue un binaire compilé et fournit, conformément à la GPL, le
script de build permettant de le reproduire depuis les sources amont
([grobian/antiword](https://github.com/grobian/antiword)).

Voir `LICENSE`.
