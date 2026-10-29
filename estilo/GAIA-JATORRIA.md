# Gaia: jatorria eta lizentzia

Liburu honen HTML gaia (**Bookup**) ez da lan hauena: hirugarren baten lana da,
eta MIT lizentziarekin banatzen da. Hemen gordetzen da jatorrizko egiletza,
lizentziak eskatzen duen bezala.

- **Jatorrizkoa:** Bookup — Quarto HTML formatu pertsonalizatua
- **Egilea:** Julien Barnier
- **Biltegia:** <https://github.com/juba/bookup-html>
- **Lizentzia:** MIT (ikusi behean)

## Zer hartu da eta zer aldatu

Hartutakoa:

- `estilo/gaia.scss` — `bookup.scss`-etik (koloreak, tipografia, sidebarra, TOC-a)
- `estilo/gaia-iluna.scss` — `bookup_dark.scss`-etik (iluneko modua)
- `estilo/letrak/letrak.css` eta `estilo/letrak/*.woff2` — `fonts-embed.css` eta
  hari dagozkion Roboto / Roboto Slab / Fira Mono letra-tipoak

Aldaketak:

- Fitxategiak `_extensions/bookup/` karpetatik proiektuaren `estilo/` karpetara
  eraman dira, eta `_quarto.yml`-n `format: html:` gisa ezarri (luzapen-formatu
  baten ordez). Horrela `quarto render --to html`-ek gaia zuzen aplikatzen du.
- Letren `@font-face` arauak `css:` bidez kargatzen dira zuzenean; luzapenaren
  `embed-fonts.lua` iragazkia kendu da, beti tokiko letrak erabiltzen direlako.
- Fitxategi-izenak euskaratu dira; edukia, funtsean, aldatu gabe dago.

## MIT lizentzia

```text
MIT License

Copyright (c) 2023 Julien Barnier

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
