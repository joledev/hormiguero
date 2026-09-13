# Como se trabaja en Hormiguero

Hormiguero es una arena multijugador donde cada quien programa el
comportamiento de su colonia de hormigas en un mini-lenguaje propio, y las
colonias compiten en un tablero que se ve moverse en vivo. Existe para
aprender Elixir de verdad: procesos, supervision, estado que cambia solo, y
una interfaz en tiempo real sobre LiveView.

Esto se escribe **antes** de que haya codigo, a proposito. Una convencion
redactada despues no es una convencion: es la descripcion de lo que ya se hizo
mal.

## Antes de nada: el entorno

`mix`, `elixir` y `psql` **no estan instalados en el sistema**. Viven en el
devShell del `flake.nix` de este repo, y `direnv` lo carga solo al entrar a la
carpeta:

```bash
cd ~/Dev/Hormiguero     # imprime el banner del devShell
mix --version           # Mix 1.18.5
```

Si no aparece el banner, falta autorizar el `.envrc` una vez:

```bash
direnv allow
```

Fuera de la carpeta, `which elixir` no devuelve nada. Es intencional: la
version de Elixir la fija el `flake.lock` de este repo, no la maquina.

> El repositorio en GitHub se llama **`hormiguero`** en minuscula y la carpeta
> local es **`Hormiguero`** con mayuscula. Tenlo presente al clonar en otra
> maquina o al escribir rutas.

## Commits

**Conventional Commits**, en espanol y sin acentos. El tipo y el ambito van en
minuscula; el resto de la linea describe **que hace el cambio**, no que
archivos toca.

```
feat(motor): un GenServer por arena con tick de 200ms
fix(parser): manejar salto de linea final sin token EOF
docs(readme): instrucciones de arranque con docker compose
test(interprete): cubrir limite de ciclos por tick
chore(deps): subir phoenix_live_view a 1.0
refactor(arena): extraer el movimiento a un modulo puro
```

Tipos que se usan aqui: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`.

Cuando el cambio no sea obvio, el cuerpo del commit explica **por que** se hizo
asi y que se descarto. Dentro de tres meses el diff sigue estando; el
razonamiento, no.

## Ramas

Una rama por ticket, nombrada con el identificador de Plane por delante. Asi el
ticket y la rama se encuentran solos:

```bash
git switch main
git pull
git switch -c ANT-12-lexer-del-mini-lenguaje
```

**`main` no acepta commits directos, y esto SI esta forzado por GitHub.** Un
`git push` a `main` se rechaza en el servidor:

```
remote: error: GH013: Repository rule violations found for refs/heads/main.
 ! [remote rejected] main -> main (push declined due to repository rule violations)
```

El ruleset «main protegida» exige pull request, prohibe borrar la rama y
prohibe el force-push, y **solo permite squash** como metodo de mezcla, que es
el que usa el ciclo de abajo.

> Esto no siempre fue asi. El repositorio nacio **privado**, y ahi los rulesets
> requieren GitHub Pro: la API respondia `403: Upgrade to GitHub Pro or make
> this repository public`. La regla existia solo como disciplina. Se hizo
> publico precisamente para cerrar ese hueco, y de paso quedaron activos el
> escaneo de secretos y la proteccion de push, que en privado tampoco estaban.

## El ciclo de un ticket

1. Mover el ticket a **In Progress** en Plane.
2. Crear la rama desde `main` actualizado.
3. **Escribir la prueba primero** cuando el ticket sea de logica pura: parser,
   interprete, reglas del motor. No aplica a plantillas ni configuracion.
4. Implementar hasta que la prueba pase.
5. `mix format` y `mix test` en verde **antes** de commitear.
6. `gh pr create --fill`, y **leer tu propio diff en la web** antes de mezclar.
   Leerlo en otro formato es lo que hace que aparezcan los descuidos.
7. `gh pr merge --squash --delete-branch`.
8. Mover el ticket a **Done**.

El paso 6 no es burocracia: es el unico momento en que ves el cambio como lo
veria otra persona.

El paso 7 usa `--squash` porque el ruleset de `main` **no admite otra cosa**:
ni merge commit ni rebase. Un historial plano, un commit por ticket.

## Secretos

El repositorio es **publico**. Nada de credenciales dentro, nunca.

- El `.env` real esta en `.gitignore` y no debe salir de tu maquina. Lo que se
  versiona es `.env.example`, con los nombres de las variables y valores de
  mentira.
- GitHub tiene **push protection** activa: si intentas subir algo que parezca
  una credencial, el push se rechaza antes de que llegue al servidor. Es una
  red, no un permiso para descuidarse.
- Los `secret_key_base` de `config/dev.exs` y `config/test.exs` **si** estan
  versionados. Es lo que hace `phx.new` y no es un descuido: firman cookies de
  un servidor que solo escucha en `localhost`. El de produccion sale de la
  variable `SECRET_KEY_BASE` en `config/runtime.exs` y no vive en el codigo.

## Definicion de terminado

Un ticket no se cierra sin las cuatro:

- [ ] El codigo hace lo que dice el ticket.
- [ ] Tiene pruebas si tiene logica. Plantillas y configuracion no las
      necesitan.
- [ ] `mix format --check-formatted` y `mix test` pasan.
- [ ] El README refleja el cambio si cambio la forma de arrancar el proyecto.

Una prueba sin asercion util es peor que ninguna: da luz verde sin mirar nada.

## Quien escribe y quien revisa

El codigo lo escribe **Joel**, linea por linea. Claude explica, da ejemplos,
revisa y **senala** — no corrige. Ese es el punto entero del proyecto: si se
cruza esa linea, deja de haber aprendizaje.

La frontera entre las dos cosas es el estado **Ready to review** de Plane:

| Estado | Quien manda |
|---|---|
| Todo → In Progress | Joel. Claude no mira el ticket. |
| In Progress → Ready to review | Joel, cuando compila y las pruebas pasan. |
| Ready to review | Claude lee el diff y comenta los hallazgos. |
| → In Progress o → Done | Segun si hay que arreglar algo. |

Para pedir revision basta con decir «revisa ANT-12» o «revisa el PR 7»: Claude
llega al repositorio por `gh` y a los tickets por la API de Plane.

La convencion completa vive en el ticket **ANT-34**.
